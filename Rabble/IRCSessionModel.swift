import Foundation
import Network
import RabbleKit

@Observable
@MainActor
final class IRCSessionModel {

    var file: File
    var irc: IRC = .init()

    private let state = AppState.shared
    private var connection: NWConnection? = nil

    var logs: [IRC.Session.Log] {
        irc.session?.logs ?? []
    }

    var list: [IRC.Session.Channel] {
        irc.session?.list ?? []
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

    func disconnect() async throws {

        // Update session pool
        connection?.cancel()
        connection = nil

        // Update session
        irc.session?.connected = false
        try await API.shared.fileUpdate(file.id, package: irc)
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

    private func handleStateUpdate(state: NWConnection.State) async throws {
        switch state {
        case .ready:
            irc.session?.connected = true

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
            try await disconnect()
        case .cancelled:
            try await disconnect()
        default:
            break
        }

        try await API.shared.fileUpdate(file.id, package: irc)
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
            try await API.shared.fileUpdate(file.id, package: irc)

            // Respond to periodic PINGs to maintain the connection
            if line.hasPrefix("PING ") {
                let payload = line.trimmingPrefix("PING ")
                send("PONG \(payload)")
            }
        }
    }

    private func apply(message: IRC.Message) async throws {
        guard case .numeric(let numeric) = message.command else {
            return
        }
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
            try await API.shared.fileUpdate(file.id, package: irc)
        default:
            return
        }
    }

    private var incomingDataBuffer = ""
}
