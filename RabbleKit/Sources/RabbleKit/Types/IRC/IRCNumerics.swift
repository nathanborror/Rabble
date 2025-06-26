/// Documentation derived from:
/// - https://modern.ircdocs.horse
/// - https://www.alien.net.au/irc/irc2numerics.html
import Foundation

public enum IRCNumeric: Codable, Equatable, Sendable {
    case RPL_WELCOME
    case RPL_YOURHOST
    case RPL_CREATED
    case RPL_MYINFO
    case RPL_ISUPPORT
    case RPL_BOUNCE
    case RPL_UMODEIS
    case RPL_LUSERCLIENT
    case RPL_LUSEROP
    case RPL_LUSERUNKNOWN
    case RPL_LUSERCHANNELS
    case RPL_LUSERME
    case RPL_LOCALUSERS
    case RPL_GLOBALUSERS
    case RPL_WHOISUSER
    case RPL_WHOISSERVER
    case RPL_WHOISOPERATOR
    case RPL_ENDOFWHO
    case RPL_ENDOFWHOIS
    case RPL_WHOISCHANNELS
    case RPL_LISTSTART
    case RPL_LIST
    case RPL_LISTEND
    case RPL_CHANNELMODEIS
    case RPL_CREATIONTIME

    /// # 332: <client> <channel> :<topic>
    /// Sent to a client when joining the <channel> to inform them of the current topic of the channel.
    case RPL_TOPIC(client: String, channel: String, topic: String)

    /// # 333: <client> <channel> <nick> <setat>
    /// Sent to a client to let them know who set the topic (<nick>) and when they set it (<setat> is a unix timestamp). Sent after RPL_TOPIC (332).
    case RPL_TOPICWHOTIME(client: String, channel: String, nick: String, setat: String)

    /// # 352: <client> <channel> <username> <host> <server> <nick> <flags> :<hopcount> <realname>
    /// Sent as a reply to the WHO command, this numeric gives information about the client with the nickname <nick>. Refer to RPL_WHOISUSER (311)
    /// for the meaning of the fields <username>, <host> and <realname>. <server> is the name of the server the client is connected to. If the WHO
    /// command was given a channel as the <mask> parameter, then the same channel MUST be returned in <channel>. Otherwise <channel> is an
    /// arbitrary channel the client is joined to or a literal asterisk character ('*', 0x2A) if no channel is returned. <hopcount> is the number of intermediate
    /// servers between the client issuing the WHO command and the client <nick>, it might be unreliable so clients SHOULD ignore it.
    ///
    /// <flags> contains the following characters, in this order:
    /// - Away status: the letter H ('H', 0x48) to indicate that the user is here, or the letter G ('G', 0x47) to indicate that the user is gone.
    /// - Optionally, a literal asterisk character ('*', 0x2A) to indicate that the user is a server operator.
    /// - Optionally, the highest channel membership prefix that the client has in <channel>, if the client has one.
    /// - Optionally, one or more user mode characters and other arbitrary server-specific flags.
    case RPL_WHOREPLY(client: String, channel: String, username: String, host: String, server: String, nick: String, flags: String, name: String)

    /// # 353: <client> <symbol> <channel> :[prefix]<nick>{ [prefix]<nick>}
    /// Sent as a reply to the NAMES command, this numeric lists the clients that are joined to <channel> and their status in that channel.
    ///
    /// <symbol> notes the status of the channel. It can be one of the following:
    /// - ("=", 0x3D) - Public channel.
    /// - ("@", 0x40) - Secret channel (secret channel mode "+s").
    /// - ("*", 0x2A) - Private channel (was "+p", no longer widely used today).
    ///
    /// <nick> is the nickname of a client joined to that channel, and <prefix> is the highest channel membership prefix that client has in the channel, if
    /// they have one. The last parameter of this numeric is a list of [prefix]<nick> pairs, delimited by a SPACE character (' ', 0x20).
    case RPL_NAMREPLY(client: String, symbol: String, channel: String, nicks: [String])

    /// # 366: <client> <channel> :End of /NAMES list
    /// Sent as a reply to the NAMES command, this numeric specifies the end of a list of channel member names.
    case RPL_ENDOFNAMES(client: String, channel: String, text: String)

    /// # 372: <client> :<line of the motd>
    /// When sending the Message of the Day to the client, servers reply with each line of the MOTD as this numeric. MOTD lines MAY be wrapped to 80
    /// characters by the server.
    case RPL_MOTD(client: String, text: String)

    /// # 375: <client> :- <server> Message of the day -
    /// Indicates the start of the Message of the Day to the client. The text used in the last param of this message may vary, and SHOULD be displayed as-is
    /// by IRC clients to their users.
    case RPL_MOTDSTART(client: String, text: String)

    /// # 376: <client> :End of /MOTD command.
    /// Indicates the end of the Message of the Day to the client. The text used in the last param of this message may vary.
    case RPL_ENDOFMOTD(client: String, text: String)

    /// # 396 (Undernet)
    /// Reply to a user when user mode +x (host masking) was set successfully
    case RPL_HOSTHIDDEN

    // Errors
    case ERR_NOSUCHNICK(client: String, nick: String, text: String)
    case ERR_NOSUCHCHANNEL(client: String, channel: String, text: String)
    case ERR_NOTONCHANNEL(client: String, channel: String, text: String)
    case ERR_CHANOPRIVSNEEDED(client: String, channel: String, text: String)

    /// # 904: <client> :SASL authentication failed
    /// This numeric indicates that SASL authentication failed because of invalid credentials or other errors not explicitly mentioned by other numerics. For more
    /// information on this numeric, see the IRCv3 sasl-3.1 extension. The text used in the last param of this message varies wildly.
    case ERR_SASLFAIL(client: String, text: String)

    public init?(_ string: String, params: [String]) {
        guard let code = UInt16(string) else {
            return nil
        }
        switch code {
        case 001: self = .RPL_WELCOME
        case 002: self = .RPL_YOURHOST
        case 003: self = .RPL_CREATED
        case 004: self = .RPL_MYINFO
        case 005: self = .RPL_ISUPPORT
        case 010: self = .RPL_BOUNCE
        case 221: self = .RPL_UMODEIS
        case 251: self = .RPL_LUSERCLIENT
        case 252: self = .RPL_LUSEROP
        case 253: self = .RPL_LUSERUNKNOWN
        case 254: self = .RPL_LUSERCHANNELS
        case 255: self = .RPL_LUSERME
        case 265: self = .RPL_LOCALUSERS
        case 266: self = .RPL_GLOBALUSERS
        case 311: self = .RPL_WHOISUSER
        case 312: self = .RPL_WHOISSERVER
        case 313: self = .RPL_WHOISOPERATOR
        case 315: self = .RPL_ENDOFWHO
        case 318: self = .RPL_ENDOFWHOIS
        case 319: self = .RPL_WHOISCHANNELS
        case 321: self = .RPL_LISTSTART
        case 322: self = .RPL_LIST
        case 323: self = .RPL_LISTEND
        case 324: self = .RPL_CHANNELMODEIS
        case 329: self = .RPL_CREATIONTIME

        case 332:
            guard params.count >= 3 else { return nil }
            self = .RPL_TOPIC(client: params[0], channel: params[1], topic: params[2])
        case 333:
            guard params.count >= 4 else { return nil }
            self = .RPL_TOPICWHOTIME(client: params[0], channel: params[1], nick: params[2], setat: params[3])
        case 352:
            guard params.count >= 8 else { return nil }
            self = .RPL_WHOREPLY(client: params[0], channel: params[1], username: params[2], host: params[3], server: params[4], nick: params[5], flags: params[6], name: params[7])
        case 353:
            guard params.count >= 4 else { return nil }
            let nicks = params[3].split(separator: " ").map(String.init)
            self = .RPL_NAMREPLY(client: params[0], symbol: params[1], channel: params[2], nicks: nicks)
        case 366:
            guard params.count >= 3 else { return nil }
            self = .RPL_ENDOFNAMES(client: params[0], channel: params[1], text: params[2])
        case 372:
            guard params.count >= 2 else { return nil }
            self = .RPL_MOTD(client: params[0], text: params[1])
        case 375:
            guard params.count >= 2 else { return nil }
            self = .RPL_MOTDSTART(client: params[0], text: params[1])
        case 376:
            guard params.count >= 2 else { return nil }
            self = .RPL_ENDOFMOTD(client: params[0], text: params[1])
        case 396:
            self = .RPL_HOSTHIDDEN

        // Errors

        case 401:
            guard params.count >= 3 else { return nil }
            self = .ERR_NOSUCHNICK(client: params[0], nick: params[1], text: params[2])
        case 403:
            guard params.count >= 3 else { return nil }
            self = .ERR_NOSUCHCHANNEL(client: params[0], channel: params[1], text: params[2])
        case 442:
            guard params.count >= 3 else { return nil }
            self = .ERR_NOTONCHANNEL(client: params[0], channel: params[1], text: params[2])
        case 482:
            guard params.count >= 3 else { return nil }
            self = .ERR_CHANOPRIVSNEEDED(client: params[0], channel: params[1], text: params[2])
        case 904:
            guard params.count >= 2 else { return nil }
            self = .ERR_SASLFAIL(client: params[0], text: params[1])
        default:
            return nil
        }
    }
}
