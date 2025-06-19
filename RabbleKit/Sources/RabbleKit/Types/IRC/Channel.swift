import Foundation

extension IRC {

    public struct Channel: Identifiable, Codable, Sendable {
        public var sessionID: String
        public var name: String
        public var topic: Topic?
        public var users: [String: User]
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

        public struct User: Codable, Identifiable, Sendable {
            public var nick: String
            public var modes: Set<String>
            public var joined: Date?

            public var id: String { nick }
        }

        public init(sessionID: String, name: String, topic: Topic? = nil, users: [String: User] = [:],
                    modes: Set<String> = [], password: String? = nil, limit: Int? = nil, bans: Set<String> = [],
                    messages: [Message] = [], created: Date) {
            self.sessionID = sessionID
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
}
