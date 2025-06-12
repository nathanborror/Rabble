import Foundation

public struct Session: Codable, Identifiable, Sendable {
    public var id = UUID()
    public var created: Date = .now
    public var modified: Date = .now
    public var messages: [Message] = []
    public var isConnected: Bool = false
    public var server: String
    public var port: UInt16
    public var nickname: String
    public var name: String

    public init(server: String, port: UInt16 = 6667, nickname: String, name: String = "") {
        self.server = server
        self.port = port
        self.nickname = nickname
        self.name = name
    }

    public func apply(_ session: Session) -> Session {
        var existing = self
        existing.modified = .now
        existing.messages = session.messages
        existing.isConnected = session.isConnected
        existing.server = session.server
        existing.port = session.port
        existing.nickname = session.nickname
        existing.name = session.name
        return existing
    }
}
