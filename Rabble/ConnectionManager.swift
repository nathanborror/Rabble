import Foundation
import Network
import RabbleKit

@Observable
@MainActor
final class ConnectionManager {

    var file: File
    var irc: IRC = .init()
    var selectedChannel = "__console__"

    private let state = AppState.shared
    private var connection: NWConnection? = nil

    var hostname: String {
        irc.session?.server ?? "Unknown"
    }

    var connected: Bool {
        connection?.state == .ready
    }

    var logs: [IRC.Session.Log] {
        irc.session?.logs ?? []
    }

    var list: [IRC.Session.Channel] {
        irc.session?.list ?? []
    }

    var channels: [String: IRC.Channel] {
        Dictionary(uniqueKeysWithValues: irc.channels.map { ($0.id, $0) })
    }

    init(file: File) {
        self.file = file
        self.read()
    }

    func read() {
        do {
            let irc: IRC = try state.filePackage(file.id)
            self.irc = irc
        } catch {
            print(error)
        }
    }

    func connect() async throws {
        let endpoint = NWEndpoint.hostPort(host: .init(irc.session!.server), port: .init(integerLiteral: irc.session!.port))
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

    func leave(_ channelID: String) {
        send("PART \(channelID)")
        irc.remove(channelID: channelID)
        Task { try await handleSave() }
    }

    func clear() {
        irc.session?.logs = []
    }

    private func handleSave() async throws {
        try await API.shared.fileUpdate(file.id, package: irc)
    }

    private func handleStateUpdate(state: NWConnection.State) async throws {
        switch state {
        case .ready:
            // TODO: What is the difference between a nickname and a username?
            let messages = [
                "NICK \(irc.session!.nick)",
                "USER \(irc.session!.nick) 0 * :\(irc.session!.name)",
            ]
            for message in messages {
                send(message)
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

            // Upsert new line to session object
            irc.session?.upsert(log: .init(line))
            try await handleSave()

            // React to line
            if let message = IRC.parseServerMessage(line) {
                try await react(message: message)
            }

            // Respond to periodic PINGs to maintain the connection
            if line.hasPrefix("PING ") {
                let payload = line.trimmingPrefix("PING ")
                send("PONG \(payload)")
            }
        }
    }

    private func react(message: IRC.Message) async throws {
        switch message.command {
        case .join:
            irc.upsert(channel: .init(name: message.params[0], created: .now))
            try await handleSave()
        case .privmsg:
            let channelID = message.params[0]
            irc.upsert(message: message, channelID: channelID)
        case .numeric(let numeric):
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

                irc.session?.upsert(channel: .init(name: name, users: users, topic: topic))
                try await handleSave()
            default:
                return
            }
        default:
            break
        }
    }

    private var incomingDataBuffer = ""
}
