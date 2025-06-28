import Foundation
@testable import IRCKit

@MainActor
@Observable
public class IRCMockSession: IRCSession {

    public var server: Server
    public var expected: [String]

    public var isConnected = false
    public var isAuthenticated = false
    public var error: IRCSessionError? = nil

    public init(_ server: Server) {
        self.server = server
        self.expected = []
    }

    public func connect() async throws {}
    public func disconnect() async throws {}

    public func send(_ line: String) async throws {}
    public func send(_ line: String, expecting: @escaping (Message) -> Bool, timeout: TimeInterval = 10) async throws {}

    public func handleExpectedMessages() async throws {
        var buffer = expected.joined(separator: "\r\n") + "\r\n"
        while let range = buffer.range(of: "\r\n") {
            let line = String(buffer[..<range.lowerBound])
            buffer = String(buffer[range.upperBound...]) // Remove parsed line + delimiter

            guard let message = parseMessage(line) else {
                return
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

extension IRCMockSession {

    static var alice: IRCMockSession {
        make(nick: "alice", username: "alice")
    }

    static var bob: IRCMockSession {
        make(nick: "bob", username: "bob")
    }

    static func make(nick: String, username: String) -> IRCMockSession {
        let config = Config(server: "localhost", port: 6667, nick: nick, username: username)
        let server = Server(config: config)
        return .init(server)
    }
}
