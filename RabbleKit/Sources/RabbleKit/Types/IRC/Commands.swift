import Foundation

extension IRC {
    
    public enum Command: Codable, Equatable, Sendable {

        // Connection and registration
        case pass
        case nick
        case user
        case oper
        case quit
        case join(channel: String)
        case part

        // Messaging
        case privmsg(channel: String, message: String)
        case notice
        case ping
        case pong

        // Channel and user management
        case mode
        case topic(channel: String, message: String)
        case names
        case list
        case invite
        case kick
        case away

        // Information
        case who
        case whois
        case whowas
        case motd
        case time
        case info
        case version
        case admin

        // Modern IRCv3 and SASL
        case cap
        case authenticate
        case account

        // Custom
        case connected
        case disconnected
        case error(String)

        // Fallback
        case unknown(String)

        public init?(_ command: String, params: [String]) {
            let lower = command.lowercased()
            switch lower {
            case "pass":    self = .pass
            case "nick":    self = .nick
            case "user":    self = .user
            case "oper":    self = .oper
            case "quit":    self = .quit
            case "join":
                self = .join(channel: params[0])
            case "part":    self = .part
            case "privmsg":
                self = .privmsg(channel: params[0], message: params[1])
            case "notice":  self = .notice
            case "ping":    self = .ping
            case "pong":    self = .pong
            case "mode":    self = .mode
            case "topic":
                self = .topic(channel: params[0], message: params[1])
            case "names":   self = .names
            case "list":    self = .list
            case "invite":  self = .invite
            case "kick":    self = .kick
            case "away":    self = .away
            case "who":     self = .who
            case "whois":   self = .whois
            case "whowas":  self = .whowas
            case "motd":    self = .motd
            case "time":    self = .time
            case "info":    self = .info
            case "version": self = .version
            case "admin":   self = .admin
            case "cap":     self = .cap
            case "account": self = .account
            case "authenticate": self = .authenticate
            default:
                return nil
            }
        }
    }
}
