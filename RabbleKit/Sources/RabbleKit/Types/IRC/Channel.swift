import Foundation

extension IRC {

    public struct Channel: Identifiable, Codable, Sendable {
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

            public init(nick: String, modes: Set<String>, joined: Date? = nil) {
                self.modes = []
                self.nick = nick
                self.joined = joined

                /// # Founder
                /// This prefix shows that the given user is the ‘founder’ of the current channel and has full moderation control over it – ie, they are
                /// considered to ‘own’ that channel by the network. This prefix is typically only used on networks that have the concept of client accounts,
                /// and ownership of channels by those accounts.
                if nick.hasPrefix("~") {
                    self.nick = String(nick.trimmingPrefix("~"))
                    self.modes.insert("+q")
                }

                /// # Protected
                /// Users with this mode cannot be kicked and cannot have this mode removed by other protected users. In some software, they may
                /// perform actions that operators can, but at a higher privilege level than operators. This prefix is typically only used on networks that have
                /// the concept of client accounts, and ownership of channels by those accounts.
                if nick.hasPrefix("&") {
                    self.nick = String(nick.trimmingPrefix("&"))
                    self.modes.insert("+a")
                }

                /// # Operator
                /// Users with this mode may perform channel moderation tasks such as kicking users, applying channel modes, and set other users to
                /// operator (or lower) status.
                if nick.hasPrefix("@") {
                    self.nick = String(nick.trimmingPrefix("@"))
                    self.modes.insert("+o")
                }

                /// # Halfop
                /// Users with this mode may perform channel moderation tasks, but at a lower privilege level than operators. Which channel moderation
                /// tasks they can and cannot perform varies with server software and configuration.
                if nick.hasPrefix("%") {
                    self.nick = String(nick.trimmingPrefix("%"))
                    self.modes.insert("+h")
                }

                /// # Voice
                /// Users with this mode may send messages to a channel that is moderated.
                if nick.hasPrefix("+") {
                    self.nick = String(nick.trimmingPrefix("+"))
                    self.modes.insert("+v")
                }
            }
        }

        public init(name: String, topic: Topic? = nil, users: [String: User] = [:], modes: Set<String> = [],
                    password: String? = nil, limit: Int? = nil, bans: Set<String> = [], messages: [Message] = [], created: Date) {
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
            existing.messages += channel.messages
            existing.modified = .now
            return existing
        }
    }
}
