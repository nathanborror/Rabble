import Foundation

extension IRC {
    
    public enum Command: Codable, Equatable, Sendable {
        case pass
        case nick
        case user
        case oper
        case quit

        /// # JOIN <channel>{,<channel>} [<key>{,<key>}]
        case join(channel: String)

        /// # PART <channel>{,<channel>} [<reason>]
        case part(channel: String, reason: String?)

        /// # PRIVMSG <target>{,<target>} <text to be sent>
        case privmsg(target: String, message: String)

        /// # NOTICE <target>{,<target>} <text to be sent>
        case notice(target: String, message: String)

        case ping
        case pong
        case mode

        /// # TOPIC <channel> [<topic>]
        case topic(channel: String, message: String)

        case names
        case list
        case invite
        case kick
        case away
        case who
        case whois
        case whowas
        case motd
        case time
        case info
        case version
        case admin

        // Modern IRCv3 and SASL

        /// # CAP <subcommand> [:<capabilities>]
        case cap
        
        case authenticate
        case account

        public init?(_ command: String, params: [String]) {
            let lower = command.lowercased()
            switch lower {
            case "pass":
                self = .pass
            case "nick":
                self = .nick
            case "user":
                self = .user
            case "oper":
                self = .oper
            case "quit":
                self = .quit
            case "join":
                self = .join(channel: params[0])
            case "part":
                guard params.count >= 1 else { return nil }
                let reason = params.count > 1 ? params[1] : nil
                self = .part(channel: params[0], reason: reason)
            case "privmsg":
                guard params.count >= 2 else { return nil }
                self = .privmsg(target: params[0], message: params[1])
            case "notice":
                guard params.count >= 2 else { return nil }
                self = .notice(target: params[0], message: params[1])
            case "ping":
                self = .ping
            case "pong":
                self = .pong
            case "mode":
                self = .mode
            case "topic":
                self = .topic(channel: params[0], message: params[1])
            case "names":
                self = .names
            case "list":
                self = .list
            case "invite":
                self = .invite
            case "kick":
                self = .kick
            case "away":
                self = .away
            case "who":
                self = .who
            case "whois":
                self = .whois
            case "whowas":
                self = .whowas
            case "motd":
                self = .motd
            case "time":
                self = .time
            case "info":
                self = .info
            case "version":
                self = .version
            case "admin":
                self = .admin
            case "cap":
                self = .cap
            case "account":
                self = .account
            case "authenticate":
                self = .authenticate
            default:
                return nil
            }
        }
    }
}
