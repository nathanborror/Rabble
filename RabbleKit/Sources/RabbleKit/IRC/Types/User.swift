import Foundation

extension IRC {

    public struct User: Codable, Identifiable, Sendable {
        public var nick: String
        public var username: String?
        public var hostname: String?
        public var away: String?
        public var modes: Set<String>
        public var channels: Set<String>
        public var lastActive: Date?

        public var id: String { nick }
    }

    public struct UserRef: Codable, Identifiable, Sendable {
        public var nick: String
        public var modes: Set<String>
        public var joined: Date?

        public var id: String { nick }
    }
}
