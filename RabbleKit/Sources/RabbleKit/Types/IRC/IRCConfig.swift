import Foundation

public struct IRCConfig: Codable, Sendable {
    public var server: String
    public var port: UInt16
    public var nick: String
    public var username: String
    public var password: String?
    public var name: String
    public var motd: String?
    public var logs: [IRCMessage]
    public var list: [Channel]
    public var capabilities: [String: Bool]
    public var created: Date
    public var modified: Date

    public struct Channel: Identifiable, Codable, Sendable {
        public var name: String
        public var users: Int?
        public var topic: String?

        public var id: String { name }

        public init(name: String, users: Int? = nil, topic: String? = nil) {
            self.name = name
            self.users = users
            self.topic = topic
        }

        public func apply(_ channel: Channel) -> Channel {
            var existing = self
            existing.name = channel.name
            existing.users = (channel.users != nil) ? channel.users : existing.users
            existing.topic = (channel.topic != nil) ? channel.topic : existing.topic
            return existing
        }
    }

    public init(server: String, port: UInt16 = 6667, nick: String, username: String, password: String? = nil,
                name: String, motd: String? = nil, logs: [IRCMessage] = []) {
        self.server = server
        self.port = port
        self.nick = nick
        self.username = username
        self.password = password
        self.name = name
        self.motd = motd
        self.logs = logs
        self.list = []
        self.capabilities = [:]
        self.created = .now
        self.modified = .now
    }

    public func apply(_ config: IRCConfig) -> IRCConfig {
        var existing = self
        existing.server = config.server
        existing.port = config.port
        existing.nick = config.nick
        existing.username = config.username
        existing.password = config.password
        existing.name = config.name
        existing.motd = config.motd
        existing.logs = config.logs
        existing.list = config.list
        existing.capabilities = config.capabilities
        existing.modified = .now
        return existing
    }
}
