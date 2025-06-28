import Foundation
@testable import IRC

@MainActor
@Observable
public class IRCMockSession: IRCSession {

    public var server: Server
    public var buffer = ""
    public var pending: [String: IRCPendingRequest] = [:]

    public var isConnected = false
    public var isAuthenticated = false
    public var error: IRCSessionError? = nil

    public init(_ server: Server) {
        self.server = server
    }

    public func connect() async throws {}
    public func disconnect() async throws {}

    public func send(_ line: String) async throws {}
    public func send(_ line: String, expecting: @escaping (Message) -> Bool, timeout: TimeInterval = 10) async throws {}
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
