import Foundation

public struct Session: Codable, Identifiable, Sendable {
    public var id: String
    public var server: String
    public var port: UInt16
    public var nickname: String
    public var name: String
    public var messages: [Message]
    public var connected: Bool
    public var created: Date
    public var modified: Date

    public init(id: String = UUID().uuidString, server: String, port: UInt16 = 6667, nickname: String, name: String,
                messages: [Message] = [], connected: Bool = false) {
        self.id = id
        self.server = server
        self.port = port
        self.nickname = nickname
        self.name = name
        self.messages = messages
        self.connected = connected
        self.created = .now
        self.modified = .now
    }

    public func apply(_ session: Session) -> Session {
        var existing = self
        existing.server = session.server
        existing.port = session.port
        existing.nickname = session.nickname
        existing.name = session.name
        existing.messages = session.messages
        existing.connected = session.connected
        existing.modified = .now
        return existing
    }
}
