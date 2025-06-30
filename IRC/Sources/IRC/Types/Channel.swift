import Foundation

public struct Channel: Identifiable, Codable, Sendable {
    public var name: String
    public var key: String?
    public var topic: Topic?
    public var users: [String: ChannelUser]
    public var modes: String?
    public var password: String?
    public var limit: Int?
    public var bans: Set<String>
    public var messages: [Message]
    public var created: Date
    public var modified: Date

    public var id: String { name }

    public struct Topic: Codable, Sendable {
        public var message: String
        public var author: String?
        public var created: Date?

        public init(message: String, author: String? = nil, created: Date? = nil) {
            self.message = message
            self.author = author
            self.created = created
        }
    }

    public init(name: String, key: String? = nil, topic: Topic? = nil, users: [String: ChannelUser] = [:],
                modes: String? = nil, password: String? = nil, limit: Int? = nil, bans: Set<String> = [],
                messages: [Message] = [], created: Date = .now) {
        self.name = name
        self.key = key
        self.topic = topic
        self.users = users
        self.modes = modes
        self.password = password
        self.limit = limit
        self.bans = bans
        self.messages = messages
        self.created = created
        self.modified = .now
    }

    public func apply(_ channel: Channel) -> Channel {
        var existing = self
        existing.name = channel.name
        existing.key = channel.key
        existing.topic = channel.topic
        existing.users = channel.users
        existing.modes = channel.modes
        existing.password = channel.password
        existing.limit = channel.limit
        existing.bans = channel.bans
        existing.messages = union(existing.messages, channel.messages)
        existing.modified = .now
        return existing
    }

    public func apply(modeArguments arguments: [String]) -> Channel {
        guard let modes else { return self }

        var existing = self
        var argumentIndex = 0

        for mode in modes.dropFirst() {
            switch mode {
            case "k": // Private Key
                existing.key = arguments[argumentIndex]
                argumentIndex += 1
            case "l": // User limit (int)
                existing.limit = Int(arguments[argumentIndex])
                argumentIndex += 1
            case "f": // Flood protection limit
                print("flood protection limit not implemented")
            default:
                print("channel mode argument not implemented")
            }
        }
        return existing
    }

    // MARK: Standard Channel Modes

    public var isInviteOnly: Bool {
        modes?.contains("i") ?? false
    }

    public var isKeyed: Bool {
        modes?.contains("k") ?? false
    }

    public var isLimited: Bool {
        modes?.contains("l") ?? false
    }

    public var isModerated: Bool {
        modes?.contains("m") ?? false
    }

    public var isNoExternalMessages: Bool {
        modes?.contains("n") ?? false
    }

    public var isPrivate: Bool {
        modes?.contains("p") ?? false
    }

    public var isSecret: Bool {
        modes?.contains("s") ?? false
    }

    public var isTopicLocked: Bool {
        modes?.contains("t") ?? false
    }

    // MARK: Extensions

    public var isBlockingCTCPMessages: Bool {
        modes?.contains("C") ?? false
    }

    public var isNoKicks: Bool {
        modes?.contains("Q") ?? false
    }

    public var isRegistered: Bool {
        modes?.contains("r") ?? false
    }

    public var isSSLUsersOnly: Bool {
        modes?.contains("s") ?? false
    }

    public var isTLSOnly: Bool {
        modes?.contains("z") ?? false
    }
}

public struct ChannelRef: Identifiable, Codable, Sendable {
    public var name: String
    public var users: Int?
    public var topic: String?

    public var id: String { name }

    public init(name: String, users: Int? = nil, topic: String? = nil) {
        self.name = name
        self.users = users
        self.topic = topic
    }

    public func apply(_ channel: ChannelRef) -> ChannelRef {
        var existing = self
        existing.name = channel.name
        existing.users = (channel.users != nil) ? channel.users : existing.users
        existing.topic = (channel.topic != nil) ? channel.topic : existing.topic
        return existing
    }
}
