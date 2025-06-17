import Foundation

extension IRC {

    public struct Channel: Identifiable, Codable, Sendable {
        public var name: String
        public var topic: Topic?
        public var users: [String: UserRef]
        public var modes: Set<String>
        public var password: String?
        public var limit: Int?
        public var bans: Set<String>
        public var messages: [Message]
        public var created: Date
        public var modified: Date

        public var id: String { name }

        public struct Topic: Codable, Sendable {
            public var message: String
            public var author: String
            public var created: Date

            public init(message: String, author: String, created: Date) {
                self.message = message
                self.author = author
                self.created = created
            }
        }

        public init(name: String, topic: Topic? = nil, users: [String: UserRef] = [:], modes: Set<String> = [], password: String? = nil,
                    limit: Int? = nil, bans: Set<String> = [], messages: [Message] = [], created: Date) {
            self.name = name
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
            existing.topic = channel.topic
            existing.users = channel.users
            existing.modes = channel.modes
            existing.password = channel.password
            existing.limit = channel.limit
            existing.bans = channel.bans
            existing.messages = channel.messages
            existing.modified = .now
            return existing
        }
    }

    public struct ChannelRef: Identifiable, Codable, Sendable {
        public var name: String
        public var users: Int
        public var topic: String?

        public var id: String { name }

        public init(name: String, users: Int, topic: String? = nil) {
            self.name = name
            self.users = users
            self.topic = topic
        }
    }
}
