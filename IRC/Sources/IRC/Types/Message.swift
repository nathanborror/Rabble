import Foundation

public struct Message: Codable, Identifiable, Sendable {
    public var _id: String
    public var kind: Kind
    public var prefix: String?
    public var nick: String?
    public var ident: String?
    public var host: String?
    public var numeric: Numeric?
    public var command: Command?
    public var params: [String]
    public var tags: [String: String]?
    public var raw: String
    public var created: Date
    public var modified: Date

    public var id: String {
        tags?["msgid"] ?? _id
    }

    public var timestamp: Date {
        guard let time = tags?["time"] else { return created }
        return parseTime(time) ?? created
    }

    public enum Kind: Codable, Sendable {
        case server
        case client
    }

    public init(kind: Kind, prefix: String? = nil, nick: String? = nil, ident: String? = nil, host: String? = nil,
                numeric: Numeric? = nil, command: Command? = nil, params: [String] = [],
                tags: [String : String]? = nil, raw: String) {
        self._id = .id
        self.kind = kind
        self.prefix = prefix
        self.nick = nick
        self.ident = ident
        self.host = host
        self.numeric = numeric
        self.command = command
        self.params = params
        self.tags = tags
        self.raw = raw
        self.created = .now
        self.modified = .now
    }

    public func apply(_ message: Message) -> Message {
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
