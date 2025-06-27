import Foundation

public enum IRCCommand: Codable, Equatable, Sendable {
    case pass
    case nick
    case user
    case oper
    case quit

    /// # JOIN <channel>{,<channel>} [<key>{,<key>}]
    case join(channels: [String], keys: [String])

    /// # PART <channel>{,<channel>} [<reason>]
    case part(channels: [String], reason: String?)

    /// # PRIVMSG <target>{,<target>} <text to be sent>
    case privmsg(targets: [String], text: String)

    /// # NOTICE <target>{,<target>} <text to be sent>
    case notice(targets: [String], text: String)

    case ping
    case pong
    case mode

    /// # TOPIC <channel> [<topic>]
    case topic(channel: String, text: String)

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
            guard params.count >= 1 else { return nil }
            let channels = params[0].split(separator: ",").map(String.init)
            if params.count > 1 {
                let keys = params[1].split(separator: ",").map(String.init)
                self = .join(channels: channels, keys: keys)
            } else {
                self = .join(channels: channels, keys: [])
            }
        case "part":
            guard params.count >= 1 else { return nil }
            let channels = params[0].split(separator: ",").map(String.init)
            let reason = params.count > 1 ? params[1] : nil
            self = .part(channels: channels, reason: reason)
        case "privmsg":
            guard params.count >= 2 else { return nil }
            let targets = params[0].split(separator: ",").map(String.init)
            self = .privmsg(targets: targets, text: params[1])
        case "notice":
            guard params.count >= 2 else { return nil }
            let targets = params[0].split(separator: ",").map(String.init)
            self = .notice(targets: targets, text: params[1])
        case "ping":
            self = .ping
        case "pong":
            self = .pong
        case "mode":
            self = .mode
        case "topic":
            self = .topic(channel: params[0], text: params[1])
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
