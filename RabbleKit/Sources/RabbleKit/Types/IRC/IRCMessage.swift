import Foundation

public struct IRCMessage: Codable, Identifiable, Sendable {
    public var id: String
    public var kind: Kind
    public var prefix: Prefix?
    public var numeric: IRCNumeric?
    public var command: IRCCommand?
    public var params: [String]
    public var tags: [String: String]?
    public var raw: String
    public var created: Date
    public var modified: Date

    public enum Kind: Codable, Sendable {
        case server
        case client
    }

    public enum Prefix: Codable, Sendable {
        case server(String)
        case user(nick: String, username: String?, host: String?)
        case service(String)
    }

    public init(id: String = UUID().uuidString, kind: Kind, prefix: Prefix? = nil, numeric: IRCNumeric? = nil,
                command: IRCCommand? = nil, params: [String] = [], tags: [String : String]? = nil, raw: String,
                created: Date = .now) {
        self.id = id
        self.kind = kind
        self.prefix = prefix
        self.numeric = numeric
        self.command = command
        self.params = params
        self.tags = tags
        self.raw = raw
        self.created = created
        self.modified = .now
    }

    public mutating func apply(_ message: IRCMessage) -> IRCMessage {
        var existing = self
        existing.kind = message.kind
        existing.prefix = message.prefix
        existing.numeric = message.numeric
        existing.command = message.command
        existing.params = message.params
        existing.tags = message.tags
        existing.raw = message.raw
        existing.modified = .now
        return existing
    }
}
