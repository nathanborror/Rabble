import Foundation

public struct ChannelUser: Codable, Identifiable, Sendable {
    public var nick: String
    public var ident: String?
    public var name: String?
    public var hostname: String?
    public var server: String?
    public var hops: Int?
    public var modes: String?
    public var joined: Date?
    public var membership: Membership?
    public var status: Status?

    public var id: String { nick }

    public enum Membership: String, Codable, Sendable {
        case owner = "~"
        case admin = "&"
        case op = "@"
        case half = "%"
        case voice = "+"
    }

    public enum Status: String, Codable, Sendable {
        case online
        case away
    }

    public init(nick: String, ident: String? = nil, name: String? = nil, hostname: String? = nil, server: String? = nil,
                hops: Int? = nil, flags: String? = nil, modes: String? = nil, joined: Date? = nil) {
        self.nick = nick
        self.ident = ident
        self.hostname = hostname
        self.server = server
        self.hops = hops
        self.modes = modes
        self.joined = joined

        // Determine membership status based on nick prefix (e.g. @name or +name)
        if let firstCharacter = nick.first, let membership = Membership(rawValue: String(firstCharacter)) {
            self.nick.removeFirst()
            self.membership = membership
        }

        // Determine online status and membership status if flags exist
        if let flags {
            for char in flags.reversed() {
                switch char {
                case "H":
                    self.status = .online
                case "G":
                    self.status = .away
                default:
                    if let membership = Membership(rawValue: String(char)) {
                        self.membership = membership
                    }
                }
            }
        }

        // Remove hop count prefix on name if it exists
        if let name {
            let parts = name.split(separator: " ")
            if let prefix = parts.first, let hops = Int(prefix) {
                let remaining = Array(parts.dropFirst())
                self.name = remaining.joined(separator: " ")
                self.hops = hops
            } else {
                self.name = name
            }
        }
    }

    public func apply(_ user: ChannelUser) -> ChannelUser {
        var existing = self
        existing.ident = user.ident ?? existing.ident
        existing.name = user.name ?? existing.name
        existing.hostname = user.hostname ?? existing.hostname
        existing.server = user.server ?? existing.server
        existing.hops = user.hops ?? existing.hops
        existing.modes = user.modes ?? existing.modes
        existing.joined = user.joined ?? existing.joined
        existing.membership = user.membership ?? existing.membership
        existing.status = user.status ?? existing.status
        return existing
    }
}
