import Foundation
extension IRC {
    
    public enum Command: Codable, Sendable {

        // Connection and registration
        case pass
        case nick
        case user
        case oper
        case quit
        case join
        case part

        // Messaging
        case privmsg
        case notice
        case ping
        case pong

        // Channel and user management
        case mode
        case topic
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

        // Numerics
        case numeric(Numeric)

        // Custom
        case connected
        case disconnected
        case error(String)

        // Fallback
        case unknown(String)

        public init(_ command: String) {
            let lower = command.lowercased()
            switch lower {
            case "pass":    self = .pass
            case "nick":    self = .nick
            case "user":    self = .user
            case "oper":    self = .oper
            case "quit":    self = .quit
            case "join":    self = .join
            case "part":    self = .part
            case "privmsg": self = .privmsg
            case "notice":  self = .notice
            case "ping":    self = .ping
            case "pong":    self = .pong
            case "mode":    self = .mode
            case "topic":   self = .topic
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
                if command.count == 3, command.allSatisfy({ $0.isNumber }) {
                    self = .numeric(.init(command))
                } else {
                    self = .unknown(command)
                }
            }
        }
    }
}
