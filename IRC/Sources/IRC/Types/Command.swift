import Foundation

public enum Command: Codable, Equatable, Sendable {

    // MARK: - Connection Messages

    /// The CAP command is used for capability negotiation between a server and a client. The CAP message may be sent from the server to the client. For the
    /// exact semantics of the CAP command and subcommands, please see the Capability Negotiation specification.
    /// Parameters: <subcommand> [:<capabilities>]
    case CAP(subcommand: String, capabilities: String?)

    /// The AUTHENTICATE command is used for SASL authentication between a server and a client. The client must support and successfully negotiate the
    /// "sasl" client capability (as listed below in the SASL specifications) before using this command. The AUTHENTICATE message may be sent from the server
    /// to the client. For the exact semantics of the AUTHENTICATE command and negotiating support for the "sasl" client capability, please see the IRCv3.1
    /// and IRCv3.2 SASL Authentication specifications.
    case AUTHENTICATE

    /// The PASS command is used to set a ‘connection password’. If set, the password must be set before any attempt to register the connection is made.
    /// This requires that clients send a PASS command before sending the NICK / USER combination.
    /// Parameters: <password>
    case PASS(password: String)

    /// The NICK command is used to give the client a nickname or change the previous one. If the server receives a NICK command from a client where the
    /// desired nickname is already in use on the network, it should issue an ERR_NICKNAMEINUSE numeric and ignore the NICK command.
    /// Parameters: <nickname>
    case NICK(nickname: String)

    /// The USER command is used at the beginning of a connection to specify the username and realname of a new user. It must be noted that <realname>
    /// must be the last parameter because it may contain SPACE (' ', 0x20) characters, and should be prefixed with a colon (:) if required.
    /// Parameters: <username> 0 * <realname>
    case USER(username: String, realname: String)

    /// The PING command is sent by either clients or servers to check the other side of the connection is still connected and/or to check for connection latency,
    /// at the application layer. The <token> may be any non-empty string.
    /// Parameters: <token>
    case PING(token: String)

    /// The PONG command is used as a reply to PING commands, by both clients and servers. The <token> should be the same as the one in the PING
    /// message that triggered this PONG.
    case PONG

    /// The OPER command is used by a normal user to obtain IRC operator privileges. Both parameters are required for the command to be successful.
    /// Parameters: <name> <password>
    case OPER(name: String, password: String)

    /// The QUIT command is used to terminate a client’s connection to the server. The server acknowledges this by replying with an ERROR message and
    /// closing the connection to the client. This message may also be sent from the server to a client to show that a client has exited from the network. This is
    /// typically only dispatched to clients that share a channel with the exiting user. When the QUIT message is sent to clients, <source> represents the client
    /// that has exited the network.
    /// Parameters: [<reason>]
    case QUIT(reason: String?)

    /// This message is sent from a server to a client to report a fatal error, before terminating the client’s connection. This MUST only be used to report fatal
    /// errors. Regular errors should use the appropriate numerics or the IRCv3 standard replies framework.
    /// Parameters: <reason>
    case ERROR(reason: String)

    // MARK: - Channel Operations

    case JOIN(channels: [String], keys: [String])
    case PART(channels: [String], reason: String?)
    case TOPIC(channel: String, text: String)
    case NAMES
    case LIST
    case INVITE(nick: String, channel: String)

    /// The KICK command can be used to request the forced removal of a user from a channel. It causes the <user> to be removed from the <channel> by
    /// force. This message may be sent from a server to a client to notify the client that someone has been removed from a channel. In this case, the message
    /// <source> will be the client who sent the kick, and <channel> will be the channel which the target client has been removed from.
    /// Parameters: <channel> <user> *( "," <user> ) [<comment>]
    case KICK(channel: String, nick: String, comment: String?)

    // MARK: - Server Queries and Commands

    case MOTD
    case VERSION
    case ADMIN
    case CONNECT
    case LUSERS
    case TIME
    case STATS
    case HELP
    case INFO
    case MODE

    // MARK: - Sending Messages

    case PRIVMSG(targets: [String], text: String)
    case NOTICE(targets: [String], text: String)

    // MARK: - User-Based Queries

    case WHO
    case WHOIS
    case WHOWAS

    // MARK: - Operator Messages

    case KILL
    case REHASH
    case RESTART
    case SQUIT

    // MARK: - Optional Messages

    case AWAY
    case LINKS
    case USERHOST
    case WALLOPS

    public init?(_ command: String, params: [String]) {
        switch command {
        case "CAP":
            guard params.count >= 1 else { return nil }
            self = .CAP(subcommand: params[0], capabilities: params[1])
        case "AUTHENTICATE":
            self = .AUTHENTICATE
        case "PASS":
            guard params.count >= 1 else { return nil }
            self = .PASS(password: params[0])
        case "NICK":
            guard params.count >= 1 else { return nil }
            self = .NICK(nickname: params[0])
        case "USER":
            guard params.count >= 2 else { return nil }
            self = .USER(username: params[0], realname: params[1])
        case "PING":
            guard params.count >= 1 else { return nil }
            self = .PING(token: params[0])
        case "PONG":
            self = .PONG
        case "OPER":
            guard params.count >= 2 else { return nil }
            self = .OPER(name: params[0], password: params[1])
        case "QUIT":
            self = .QUIT(reason: params[0])
        case "ERROR":
            guard params.count >= 1 else { return nil }
            self = .ERROR(reason: params[0])
        case "JOIN":
            guard params.count >= 1 else { return nil }
            let channels = params[0].split(separator: ",").map(String.init)
            if params.count > 1 {
                let keys = params[1].split(separator: ",").map(String.init)
                self = .JOIN(channels: channels, keys: keys)
            } else {
                self = .JOIN(channels: channels, keys: [])
            }
        case "PART":
            guard params.count >= 1 else { return nil }
            let channels = params[0].split(separator: ",").map(String.init)
            let reason = params.count > 1 ? params[1] : nil
            self = .PART(channels: channels, reason: reason)
        case "TOPIC":
            guard params.count >= 2 else { return nil }
            self = .TOPIC(channel: params[0], text: params[1])
        case "NAMES":
            self = .NAMES
        case "LIST":
            self = .LIST
        case "INVITE":
            guard params.count >= 2 else { return nil }
            self = .INVITE(nick: params[0], channel: params[1])
        case "KICK":
            guard params.count >= 2 else { return nil }
            self = .KICK(channel: params[0], nick: params[1], comment: params[2])
        case "MOTD":
            self = .MOTD
        case "VERSION":
            self = .VERSION
        case "ADMIN":
            self = .ADMIN
        case "CONNECT":
            self = .CONNECT
        case "LUSERS":
            self = .LUSERS
        case "TIME":
            self = .TIME
        case "STATS":
            self = .STATS
        case "HELP":
            self = .HELP
        case "INFO":
            self = .INFO
        case "MODE":
            self = .MODE
        case "PRIVMSG":
            guard params.count >= 2 else { return nil }
            let targets = params[0].split(separator: ",").map(String.init)
            self = .PRIVMSG(targets: targets, text: params[1])
        case "NOTICE":
            guard params.count >= 2 else { return nil }
            let targets = params[0].split(separator: ",").map(String.init)
            self = .NOTICE(targets: targets, text: params[1])
        case "WHO":
            self = .WHO
        case "WHOIS":
            self = .WHOIS
        case "WHOWAS":
            self = .WHOWAS
        case "KILL":
            self = .KILL
        case "REHASH":
            self = .REHASH
        case "RESTART":
            self = .RESTART
        case "SQUIT":
            self = .SQUIT
        case "AWAY":
            self = .AWAY
        case "LINKS":
            self = .LINKS
        case "USERHOST":
            self = .USERHOST
        case "WALLOPS":
            self = .WALLOPS
        default:
            return nil
        }
    }
}
