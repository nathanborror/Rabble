import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCServerSession", category: "IRCKit")

@MainActor
@Observable
public class IRCServerSession: IRCSession {

    public var server: Server

    public var isConnected = false
    public var isAuthenticated = false
    public var error: IRCSessionError? = nil

    private var connection: NWConnection? = nil
    private var incomingDataBuffer = ""
    private var motdBuffer = ""

    struct PendingRequest {
        let continuation: CheckedContinuation<Void, Error>
        let expectedResponse: (Message) -> Bool
        let timeout: Date
    }

    private var pendingRequests: [String: PendingRequest] = [:]

    public init(_ server: Server) {
        self.server = server
    }

    public func connect() async throws {
        clearLogs()

        let endpoint = NWEndpoint.hostPort(host: .init(server.config.server), port: .init(integerLiteral: server.config.port))
        connection = NWConnection(to: endpoint, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { try await handleStateUpdate(state: state) }
        }
        connection?.start(queue: .main)
    }

    public func disconnect() async throws {
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    public func send(_ line: String) async throws {
        let line = line+"\r\n"
        guard let data = line.data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed { error in
            guard let error else { return }
            logger.error("\(error)")
        })
    }

    public func send(_ line: String, expecting: @escaping (Message) -> Bool, timeout: TimeInterval = 10) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let id = String.id

            // Update pending requests queue
            pendingRequests[id] = .init(
                continuation: continuation,
                expectedResponse: expecting,
                timeout: .now.addingTimeInterval(timeout)
            )

            // Send line to server
            Task {
                try await send(line)
            }

            // Wait for possible timeout, remove request from queue upon timeout
            Task {
                try await Task.sleep(for: .seconds(timeout))
                if let request = pendingRequests.removeValue(forKey: id) {
                    request.continuation.resume(throwing: IRCSessionError.timeout)
                }
            }
        }
    }

    private func handleStateUpdate(state: NWConnection.State) async throws {
        switch state {
        case .ready:
            isConnected = true

            // Start listening immediatly
            handleListen()

            // Request capabilities
            try await send("CAP LS 302") { message in
                message.command == .cap
            }

            // TODO: Check before requiring
            // draft/chathistory sasl

            try await send("CAP REQ :echo-message server-time message-tags batch labeled-response") { message in
                message.command == .cap && message.params.contains("ACK")
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
                    try await self.handleIncomingData(data)
                } catch {
                    print(error)
                }
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

            guard let message = parseMessage(line) else {
                return
            }

            // Check pending requests
            for (id, request) in pendingRequests {
                if request.expectedResponse(message) {
                    pendingRequests.removeValue(forKey: id)
                    request.continuation.resume()
                    break
                }
            }

            // Respond to periodic PINGs to maintain the connection
            switch message.command {
            case .ping:
                let pong = "PONG \(message.params[0])"
                try await send(pong)
            default:
                break
            }

            // Upsert new line to config object
            upsertConfigLog(message)

            // Handle command and numeric
            do {
                try await processMessageCommand(message)
                try await processMessageNumeric(message)
            } catch let error as IRCSessionError {
                self.error = error
            } catch {
                self.error = .unhandled(error)
            }
        }
    }
}
