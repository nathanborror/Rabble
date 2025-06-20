import Foundation

extension IRC {

    public struct Session: Codable, Sendable {
        public var server: String
        public var port: UInt16
        public var nick: String
        public var username: String
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
            public var users: Int
            public var topic: String?

            public var id: String { name }

            public init(name: String, users: Int, topic: String? = nil) {
                self.name = name
                self.users = users
                self.topic = topic
            }
        }

        public init(server: String, port: UInt16 = 6667, nick: String, username: String, name: String, logs: [Log] = []) {
            self.server = server
            self.port = port
            self.nick = nick
            self.username = username
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
            existing.name = session.name
            existing.logs = session.logs
            existing.list = session.list
            existing.capabilities = session.capabilities
            existing.modified = .now
            return existing
        }
    }
}

extension IRC.Session {

    public mutating func upsert(log: Log) {
        logs.append(log)
    }

    public mutating func upsert(channel: Channel) {
        if let index = list.firstIndex(where: { $0.id == channel.id }) {
            list[index] = channel
        } else {
            list.append(channel)
        }
    }
}
