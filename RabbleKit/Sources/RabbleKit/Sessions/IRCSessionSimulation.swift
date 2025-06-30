import Foundation
import OSLog
import IRC

private let logger = Logger(subsystem: "IRCSimulationSession", category: "IRC")

@MainActor
@Observable
public class IRCSessionSimulation: IRCSession {
    public var server: Server
    public var pending: [String: IRCPendingRequest] = [:]
    public var buffer = ""
    public var isConnected = false
    public var isAuthenticated = false
    public var error: IRCSessionError? = nil

    public init(_ server: Server) {
        self.server = server
        self.isConnected = !server.logs.isEmpty
    }

    // MARK: Session Interface

    public func connect() async throws {
        clearLogs()
        
        let messages = try await API.shared.generate([
            "NICK \(server.config.nick)",
            "USER \(server.config.ident ?? server.config.username) 0 * \(server.config.realname ?? "-")",
        ])

        isConnected = true

        for message in messages {
            let data = message.content ?? ""
            try await processIncomingString("\(data)\n")
        }
    }

    public func disconnect() async throws {
        print("not implemented")
    }

    public func send(_ input: String) async throws {
        Task {
            // Add outbound message to history because LLMs don't respect `CAP REQ echo-message`
            try await processIncomingString(":\(server.config.nick)!~u@unknown.irc \(input)\n")

            do {
                let lines = server.logs.map { $0 } + [input]
                let messages = try await API.shared.generate(lines)
                for message in messages {
                    let data = message.content ?? ""
                    try await processIncomingString("\(data)\n")
                }
            } catch {
                print(error)
            }
        }
    }
}
