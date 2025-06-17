import Foundation

public struct Session: Codable, Identifiable, Sendable {
    public var id: String
    public var server: String
    public var port: UInt16
    public var nick: String
    public var name: String
    public var log: [Log]
    public var list: [ChannelRef]
    public var joined: [Channel]
    public var archived: [Channel]
    public var connected: Bool
    public var created: Date
    public var modified: Date

    public init(server: String, port: UInt16 = 6667, nick: String, name: String, log: [Log] = [], connected: Bool = false) {
        self.id = UUID().uuidString
        self.server = server
        self.port = port
        self.nick = nick
        self.name = name
        self.log = log
        self.list = []
        self.joined = []
        self.archived = []
        self.connected = connected
        self.created = .now
        self.modified = .now
    }

    public func apply(_ session: Session) -> Session {
        var existing = self
        existing.server = session.server
        existing.port = session.port
        existing.nick = session.nick
        existing.name = session.name
        existing.log = session.log
        existing.list = session.list
        existing.joined = session.joined
        existing.archived = session.archived
        existing.connected = session.connected
        existing.modified = .now
        return existing
    }
}

public struct Log: Codable, Identifiable, Sendable {
    public var id: String
    public var text: String
    public var created: Date

    public init(_ text: String) {
        self.id = UUID().uuidString
        self.text = text
        self.created = .now
    }
}
