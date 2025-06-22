import Foundation

extension IRC {

    public struct Session: Codable, Sendable {
        public var server: String
        public var port: UInt16
        public var nick: String
        public var username: String
        public var password: String?
        public var name: String
        public var logs: [Log]
        public var list: [Channel]
        public var capabilities: [String: Bool]
        public var created: Date
        public var modified: Date

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

        public init(server: String, port: UInt16 = 6667, nick: String, username: String, password: String? = nil, name: String, logs: [Log] = []) {
            self.server = server
            self.port = port
            self.nick = nick
            self.username = username
            self.password = password
            self.name = name
            self.logs = logs
            self.list = []
            self.capabilities = [:]
            self.created = .now
            self.modified = .now
        }

        public func apply(_ session: Session) -> Session {
            var existing = self
            existing.server = session.server
            existing.port = session.port
            existing.nick = session.nick
            existing.username = session.username
            existing.password = session.password
            existing.name = session.name
            existing.logs = session.logs
            existing.list = session.list
            existing.capabilities = session.capabilities
            existing.modified = .now
            return existing
        }
    }
}
