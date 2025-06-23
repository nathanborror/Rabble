import Foundation
import Network
import RabbleKit

@Observable
@MainActor
final class ConnectionManager {

    var file: File
    var irc: IRC

    private let state = AppState.shared
    private var connection: NWConnection? = nil

    var hostname: String {
        irc.session.server
    }

    var session: IRC.Session? {
        irc.session
    }

    var connected: Bool {
        connection?.state == .ready
    }

    var logs: [IRC.Session.Log] {
        irc.session.logs
    }

    var list: [IRC.Session.Channel] {
        irc.session.list
    }

    var channels: [String: IRC.Channel] {
        Dictionary(uniqueKeysWithValues: irc.channels.map { ($0.id, $0) })
    }

    init(file: File) throws {
        self.file = file
        self.irc = try state.filePackage(file.id)
    }

    func connect() async throws {
        clear()
        
        let endpoint = NWEndpoint.hostPort(host: .init(irc.session.server), port: .init(integerLiteral: irc.session.port))
        connection = NWConnection(to: endpoint, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                try await self.handleStateUpdate(state: state)
            }
        }
        connection?.start(queue: .main)
    }

    func disconnect() {
        connection?.cancel()
        connection = nil
    }

    func send(_ input: String) {

        // Required, IRC is a line-oriented protocol
        let input = input+"\r\n"

        // Send input to server session
        guard let data = input.data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed { error in
            guard let error else { return }
            print(error)
        })
    }

    func join(_ channelID: String) {
        let messages = [
            "JOIN \(channelID)",
            "WHO \(channelID)",
            "MODE \(channelID)",
            //"CHATHISTORY LATEST \(channelID) * 20",
        ]
        for message in messages {
            send(message)
        }
    }

    func leave(_ channelID: String) {
        send("PART \(channelID)")
        irc.remove(channelID: channelID)
        Task { try await handleSave() }
    }

    func clear() {
        irc.session.logs = []
        Task { try await handleSave() }
    }

    private func handleSave() async throws {
        try await API.shared.fileUpdate(file.id, package: irc)
    }

    private func handleStateUpdate(state: NWConnection.State) async throws {
        switch state {
        case .ready:
            var messages = [String]()

            // Request capabilities
            messages += [
                "CAP LS 302",
                "CAP REQ :echo-message server-time message-tags batch labeled-response sasl", // chathistory
                "CAP END",
            ]

            // Establish connection with identity
            messages += [
                "NICK \(irc.session.nick)",
                "USER \(irc.session.username) 0 * :\(irc.session.name)",
            ]

//            // Authentication (sasl)
//            let auth = "\0\(irc.session.username)\0\(irc.session.password ?? "")".data(using: .utf8)!
//            messages += [
//                "AUTHENTICATE PLAIN",
//                "AUTHENTICATE \(auth.base64EncodedString())",
//            ]

//            // Authentication (non-sasl)
//            if let password = irc.session.password {
//                messages += [
//                    "PRIVMSG NickServ :IDENTIFY \(password)",
//                    "NICK \(irc.session.nick)",
//                ]
//            }

            for message in messages {
                print(message)
                send(message)
            }

            // Rejoin channels
            for channel in irc.channels {
                join(channel.id)
            }

            handleListen()
        case .failed(let error):
            print(error)
            disconnect()
        case .cancelled:
            disconnect()
        default:
            break
        }

        try await handleSave()
    }

    private func handleListen() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                try await self.handleIncomingData(data)
                if error == nil {
                    self.handleListen()
                }
            }
        }
    }

    private func handleIncomingData(_ data: Data?) async throws {
        guard let data, let newText = String(data: data, encoding: .utf8) else { return }
        incomingDataBuffer += newText

        while let range = incomingDataBuffer.range(of: "\r\n") {
            let line = String(incomingDataBuffer[..<range.lowerBound])
            incomingDataBuffer = String(incomingDataBuffer[range.upperBound...]) // Remove parsed line + delimiter

            guard let message = IRC.parseServerMessage(line) else {
                return
            }

            // Respond to periodic PINGs to maintain the connection
            switch message.command {
            case .ping:
                let pong = "PONG \(message.params[0])"
                send(pong)
                print(line)
                print(pong)
                return
            default:
                break
            }

            // Upsert new line to session object
            irc.upsertSession(log: .init(line))

            // Handle command
            try await handleMessageCommand(message)

            // Save state
            try await handleSave()
        }
    }

    private func handleMessageCommand(_ message: IRC.Message) async throws {
        switch message.command {
        case .join:
            let channelName = message.params[0]
            irc.upsert(channel: .init(name: channelName, created: .now))
            irc.upsertSession(channel: .init(name: channelName))
            try await handleSave()
        case .privmsg:
            let channelID = message.params[0]
            irc.upsert(message: message, channelID: channelID)
        case .cap:
            if message.params[1] == "LS" && message.params[2] == "*" {
                let capabilities = message.params[3].split(separator: " ").map(String.init)
                for cap in capabilities {
                    irc.session.capabilities[cap] = false
                }
            } else if message.params[1] == "LS" {
                let capabilities = message.params[2].split(separator: " ").map(String.init)
                for cap in capabilities {
                    irc.session.capabilities[cap] = false
                }
            }
        case .numeric(let numeric):
            try await handleMessageNumeric(message, numeric: numeric)
        default:
            break
        }
    }

    private func handleMessageNumeric(_ message: IRC.Message, numeric: IRC.Numeric) async throws {
        switch numeric {
        case .RPL_LIST:
            guard message.params.count >= 4 else {
                return
            }
            let name = message.params[1]
            let users = Int(message.params[2]) ?? 0
            let topic = message.params[3].isEmpty ? nil : message.params[3]
            guard name != "*" else {
                return
            }
            irc.upsertSession(channel: .init(name: name, users: users, topic: topic))
        case .RPL_NAMREPLY:
            if let channel = irc.get(channelID: message.params[2]) {
                irc.upsert(name: message.params[3], channelID: channel.id)
                irc.upsertSession(channel: .init(name: channel.id, users: channel.users.count))
            }
        case .RPL_TOPIC:
            if var channel = irc.get(channelID: message.params[1]) {
                channel.topic = .init(message: message.params[2])
                irc.upsert(channel: channel)
            }
        default:
            return
        }
    }

    private var incomingDataBuffer = ""
}
