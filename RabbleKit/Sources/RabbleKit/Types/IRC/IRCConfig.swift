import Foundation

public struct IRCConfig: Codable, Sendable {
    public var kind: Kind
    public var server: String
    public var port: UInt16

    /// The user's primary handle on IRC:  <nick>!<ident>@<host>
    public var nick: String

    /// Derived from the user's system login or identd service. If it cannot be verified, it may be prefixed with ~.
    public var ident: String?

    /// The account name when using SASL distinct from ident and nick. Often used interchangeably with ident in casual contexts.
    public var username: String

    /// The domain or IP address, can be an actual IP, hostname or cloaked value or privacy.
    public var host: String?

    /// Optionally sent during registration (USER command) and not typically visible in normal messages.
    public var realname: String?

    /// Email is necessary for registration.
    public var email: String?

    /// Password is necessary for registration.
    public var password: String?

    public var motd: String?
    public var logs: [IRCMessage]
    public var list: [Channel]
    public var capabilities: [String: Bool]
    public var created: Date
    public var modified: Date

    public enum Kind: Codable, Sendable {
        case network
        case simulation
    }

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

    public init(kind: Kind, server: String, port: UInt16, nick: String, ident: String? = nil, username: String,
                host: String? = nil, realname: String? = nil, email: String? = nil, password: String? = nil,
                motd: String? = nil, logs: [IRCMessage] = [], list: [Channel] = [], capabilities: [String : Bool] = [:]) {
        self.kind = kind
        self.server = server
        self.port = port
        self.nick = nick
        self.ident = ident
        self.username = username
        self.host = host
        self.realname = realname
        self.email = email
        self.password = password
        self.motd = motd
        self.logs = logs
        self.list = list
        self.capabilities = capabilities
        self.created = .now
        self.modified = .now
    }

    public func apply(_ config: IRCConfig) -> IRCConfig {
        var existing = self
        existing.kind = config.kind
        existing.server = config.server
        existing.port = config.port
        existing.nick = config.nick
        existing.ident = config.ident
        existing.username = config.username
        existing.host = config.host
        existing.realname = config.realname
        existing.email = config.email
        existing.password = config.password
        existing.motd = config.motd
        existing.logs = config.logs
        existing.list = config.list
        existing.capabilities = config.capabilities
        existing.modified = .now
        return existing
    }
}
