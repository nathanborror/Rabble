import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCServerSession", category: "IRC")

@MainActor
@Observable
public class IRCSessionServer: IRCSession {

    public var server: Server
    public var pending: [String: IRCPendingRequest] = [:]
    public var buffer = ""
    public var isConnected = false
    public var isAuthenticated = false
    public var error: IRCSessionError? = nil

    private var connection: NWConnection? = nil
    private var incomingDataBuffer = ""
    private var motdBuffer = ""

    public init(_ server: Server) {
        self.server = server
    }

    public func connect() async throws {
        clearLogs()

        let endpoint = NWEndpoint.hostPort(host: .init(server.config.server), port: .init(integerLiteral: server.config.port))
        connection = NWConnection(to: endpoint, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task {
                do {
                    try await handleStateUpdate(state: state)
                } catch {
                    print(error)
                }
            }
        }
        connection?.start(queue: .main)
    }

    public func disconnect() async throws {
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    public func send(_ line: String) async throws {
        let line = line+"\n"
        guard let data = line.data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed { error in
            guard let error else { return }
            logger.error("\(error)")
        })
    }

    private func handleStateUpdate(state: NWConnection.State) async throws {
        switch state {
        case .ready:
            isConnected = true

            // Start listening immediatly
            handleListen()

            // Request capabilities
            try await send("CAP LS 302") { message in
                if case .CAP = message.command {
                    return true
                }
                return false
            }

            // TODO: Check before requiring
            // draft/chathistory sasl

            try await send("CAP REQ :echo-message server-time message-tags batch labeled-response") { message in
                if case .CAP = message.command {
                    return message.params.contains("ACK")
                }
                return false
            }
            try await send("CAP END")
            try await send("NICK \(server.config.nick)")
            try await send("USER \(server.config.ident ?? server.config.username) 0 * :\(server.config.realname ?? "-")")

            // Rejoin channels
            for channel in server.channels {
                try await channelJoin(channel.id)
            }
        case .failed(let error):
            self.error = .unhandled(error)
            try await disconnect()
        case .cancelled:
            try await disconnect()
        case .preparing:
            logger.info("preparing")
        default:
            break
        }
    }

    private func handleListen() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                do {
                    try await processIncomingData(data)
                } catch {
                    print(error)
                }
                if error == nil {
                    self.handleListen()
                }
            }
        }
    }
}
