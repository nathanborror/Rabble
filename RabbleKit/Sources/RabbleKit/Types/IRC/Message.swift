import Foundation

extension IRC {

    public struct Message: Codable, Identifiable, Sendable {
        public var id: String
        public var kind: Kind
        public var prefix: Prefix?
        public var command: Command
        public var params: [String]
        public var tags: [String: String]?
        public var raw: String
        public var created: Date

        public enum Kind: Codable, Sendable {
            case server
            case client
        }

        public enum Prefix: Codable, Sendable {
            case server(String)
            case user(String)
            case service(String)
        }

        public init(id: String = UUID().uuidString, kind: Kind, prefix: Prefix? = nil, command: Command,
                    params: [String] = [], tags: [String : String]? = nil, raw: String) {
            self.id = id
            self.kind = kind
            self.prefix = prefix
            self.command = command
            self.params = params
            self.tags = tags
            self.raw = raw
            self.created = .now
        }
    }
}
