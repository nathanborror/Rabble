/// Documentation derived from:
/// - https://modern.ircdocs.horse
/// - https://www.alien.net.au/irc/irc2numerics.html
import Foundation

public enum Numeric: Codable, Equatable, Sendable {

    /// # 001: <client> :Welcome to the <networkname> Network, <nick>[!<user>@<host>]
    /// The first message sent after client registration, this message introduces the client to the network. The text used in the last param of this message
    /// varies wildly.
    ///
    /// Servers that implement spoofed hostmasks in any capacity SHOULD NOT include the extended (complete) hostmask in the last parameter of this reply,
    /// either for all clients or for those whose hostnames have been spoofed. This is because some clients try to extract the hostname from this final parameter
    /// of this message and resolve this hostname, in order to discover their ‘local IP address’.
    ///
    /// Clients MUST NOT try to extract the hostname from the final parameter of this message and then attempt to resolve this hostname. This method of
    /// operation WILL BREAK and will cause issues when the server returns a spoofed hostname.
    case RPL_WELCOME(client: String, text: String)

    /// # 002: <client> :Your host is <servername>, running version <version>
    /// Part of the post-registration greeting, this numeric returns the name and software/version of the server the client is currently connected to. The text used
    /// in the last param of this message varies wildly.
    case RPL_YOURHOST(client: String, text: String)

    /// # 003: <client> :This server was created <datetime>
    /// Part of the post-registration greeting, this numeric returns a human-readable date/time that the server was started or created. The text used in the last
    /// param of this message varies wildly.
    case RPL_CREATED(client: String, text: String)

    /// # 004: <client> <servername> <version> <available user modes> <available channel modes> [<channel modes with a parameter>]
    /// Part of the post-registration greeting. Clients SHOULD discover available features using RPL_ISUPPORT tokens rather than the mode letters listed in this reply.
    case RPL_MYINFO(client: String, servername: String, version: String, userModes: String, channelModes: String, channelModesWithParameters: String)

    /// # 005: <client> <1-13 tokens> :are supported by this server
    case RPL_ISUPPORT(client: String, tokens: [String])

    /// # 010: <client> <hostname> <port> :<info>
    /// Sent to the client to redirect it to another server. The <info> text varies between server software and reasons for the redirection. Because this numeric
    /// does not specify whether to enable SSL and is not interpreted correctly by all clients, it is recommended that this not be used. This numeric is also
    /// known as RPL_REDIR by some software.
    case RPL_BOUNCE(client: String, hostname: String, Port: String, info: String)

    /// # 221: <client> <user modes>
    /// Sent to a client to inform that client of their currently-set user modes.
    case RPL_UMODEIS(client: String, modes: String)

    /// # 251: <client> :There are <u> users and <i> invisible on <s> servers
    /// Sent as a reply to the LUSERS command. <u>, <i>, and <s> are non-negative integers, and represent the number of total users, invisible users, and
    /// other servers connected to this server.
    case RPL_LUSERCLIENT

    /// # 252: <client> <ops> :operator(s) online
    /// Sent as a reply to the LUSERS command. <ops> is a positive integer and represents the number of IRC operators connected to this server. The text
    /// used in the last param of this message may vary.
    case RPL_LUSEROP(client: String, ops: Int)

    /// # 253: <client> <connections> :unknown connection(s)
    /// Sent as a reply to the LUSERS command. <connections> is a positive integer and represents the number of connections to this server that are
    /// currently in an unknown state. The text used in the last param of this message may vary.
    case RPL_LUSERUNKNOWN(client: String, connections: Int)

    /// # 254: <client> <channels> :channels formed
    /// Sent as a reply to the LUSERS command. <channels> is a positive integer and represents the number of channels that currently exist on this server.
    /// The text used in the last param of this message may vary.
    case RPL_LUSERCHANNELS(client: String, channels: Int)

    /// # 255: <client> :I have <c> clients and <s> servers
    /// Sent as a reply to the LUSERS command. <c> and <s> are non-negative integers and represent the number of clients and other servers connected to
    /// this server, respectively.
    case RPL_LUSERME(client: String, text: String)

    /// # 265: <client> [<u> <m>] :Current local users <u>, max <m>
    /// Sent as a reply to the LUSERS command. <u> and <m> are non-negative integers and represent the number of clients currently and the maximum
    /// number of clients that have been connected directly to this server at one time, respectively. The two optional parameters SHOULD be supplied to allow
    /// clients to better extract these numbers.
    case RPL_LOCALUSERS(client: String, u: Int, m: Int, text: String)

    /// # 266: <client> [<u> <m>] :Current global users <u>, max <m>
    /// Sent as a reply to the LUSERS command. <u> and <m> are non-negative integers. <u> represents the number of clients currently connected to this
    /// server, globally (directly and through other server links). <m> represents the maximum number of clients that have been connected to this server at one
    /// time, globally. The two optional parameters SHOULD be supplied to allow clients to better extract these numbers.
    case RPL_GLOBALUSERS(client: String, u: Int, m: Int, text: String)

    /// # 301: <client> <nick> :<message>
    /// Indicates that the user with the nickname <nick> is currently away and sends the away message that they set.
    case RPL_AWAY(client: String, nick: String, text: String)

    /// # 302: <client> :[<reply>{ <reply>}]
    /// Sent as a reply to the USERHOST command, this numeric lists nicknames and the information associated with them. The last parameter of this numeric
    /// (if there are any results) is a list of <reply> values, delimited by a SPACE character (' ', 0x20).
    case RPL_USERHOST(client: String, reply: String)

    /// # 305: <client> :You are no longer marked as being away
    /// Sent as a reply to the AWAY command, this lets the client know that they are no longer set as being away. The text used in the last param of this
    /// message may vary.
    case RPL_UNAWAY(client: String, text: String)

    /// # 311: <client> <nick> <username> <host> * :<realname>
    /// Sent as a reply to the WHOIS command, this numeric shows details about the client with the nickname <nick>. <username> and <realname>
    /// represent the names set by the USER command (though <username> may be set by the server in other ways). <host> represents the host used for the
    /// client in nickmasks (which may or may not be a real hostname or IP address). <host> CANNOT start with a colon (':', 0x3A) as this would get parsed as a
    /// trailing parameter – IPv6 addresses such as "::1" are prefixed with a zero ('0', 0x30) to ensure this. The second-last parameter is a literal asterisk character
    /// ('*', 0x2A) and does not mean anything.
    case RPL_WHOISUSER(client: String, nick: String, username: String, host: String, realname: String)

    /// # 312: <client> <nick> <server> :<server info>
    case RPL_WHOISSERVER

    /// # 313: <client> <nick> :is an IRC operator
    case RPL_WHOISOPERATOR

    /// # 314: <client> <nick> <username> <host> * :<realname>
    case RPL_WHOWASUSER

    /// # 315: <client> <mask> :End of WHO list
    case RPL_ENDOFWHO

    /// # 317: <client> <nick> <secs> <signon> :seconds idle, signon time
    case RPL_WHOISIDLE

    /// # 318: <client> <nick> :End of /WHOIS list
    case RPL_ENDOFWHOIS

    /// # 319: <client> <nick> :[prefix]<channel>{ [prefix]<channel>}
    case RPL_WHOISCHANNELS

    /// # 320: <client> <nick> :blah blah blah
    case RPL_WHOISSPECIAL

    /// # 321: <client> Channel :Users  Name
    /// Sent as a reply to the LIST command, this numeric marks the start of a channel list. As noted in the command description, this numeric MAY be skipped
    /// by the server so clients MUST NOT depend on receiving it.
    case RPL_LISTSTART(client: String)

    /// # 322: <client> <channel> <client count> :<topic>
    /// Sent as a reply to the LIST command, this numeric sends information about a channel to the client. <channel> is the name of the channel.
    /// <client count> is an integer indicating how many clients are joined to that channel. <topic> is the channel’s topic (as set by the TOPIC command).
    case RPL_LIST(client: String, channel: String, count: Int, topic: String?)

    /// # 323: <client> :End of /LIST
    /// Sent as a reply to the LIST command, this numeric indicates the end of a LIST response.
    case RPL_LISTEND(client: String)

    /// # 324: <client> <channel> <modestring> <mode arguments>...
    /// Sent to a client to inform them of the currently-set modes of a channel. <channel> is the name of the channel. <modestring> and <mode arguments>
    /// are a mode string and the mode arguments (delimited as separate parameters) as defined in the MODE message description.
    case RPL_CHANNELMODEIS(client: String, channel: String, modestring: String, arguments: [String]?)

    /// # 329: <client> <channel> <creationtime>
    /// Sent to a client to inform them of the creation time of a channel. <channel> is the name of the channel. <creationtime> is a unix timestamp
    /// representing when the channel was created on the network.
    case RPL_CREATIONTIME(client: String, channel: String, creationtime: Date)

    /// # 330: <client> <nick> <account> :is logged in as
    /// Sent as a reply to the WHOIS command, this numeric indicates that the client with the nickname <nick> was authenticated as the owner of
    /// <account>. This does not necessarily mean the user owns their current nickname, which is covered byRPL_WHOISREGNICK.
    case RPL_WHOISACCOUNT(client: String, nick: String, account: String)

    /// # 331: <client> <channel> :No topic is set
    /// Sent to a client when joining a channel to inform them that the channel with the name <channel> does not have any topic set.
    case RPL_NOTOPIC(client: String, channel: String)

    /// # 332: <client> <channel> :<topic>
    /// Sent to a client when joining the <channel> to inform them of the current topic of the channel.
    case RPL_TOPIC(client: String, channel: String, topic: String)

    /// # 333: <client> <channel> <nick> <setat>
    /// Sent to a client to let them know who set the topic (<nick>) and when they set it (<setat> is a unix timestamp). Sent after RPL_TOPIC (332).
    case RPL_TOPICWHOTIME(client: String, channel: String, nick: String, setat: String)

    /// # 336: <client> <channel>
    /// Sent to a client as a reply to the INVITE command when used with no parameter, to indicate a channel the client was invited to. This numeric should not
    /// be confused with RPL_INVEXLIST (346), which is used as a reply to MODE.
    case RPL_INVITELIST(client: String, channel: String)

    /// # 337: <client> :End of /INVITE list
    /// Sent as a reply to the INVITE command when used with no parameter, this numeric indicates the end of invitations a client received. This numeric should
    /// not be confused with RPL_ENDOFINVEXLIST (347), which is used as a reply to MODE.
    case RPL_ENDOFINVITELIST(client: String)

    /// # 338: <client> <nick> :is actually ...
    case RPL_WHOISACTUALLY

    /// # 341: <client> <nick> <channel>
    /// Sent as a reply to the INVITE command to indicate that the attempt was successful and the client with the nickname <nick> has been invited to <channel>.
    case RPL_INVITING(client: String, nick: String, channel: String)

    /// # 346: <client> <channel> <mask>
    /// Sent as a reply to the MODE command, when clients are viewing the current entries on a channel’s invite-exception list. <mask> is the given mask on the
    /// invite-exception list. This numeric should not be confused with RPL_INVITELIST (336), which is used as a reply to INVITE. This numeric is sometimes
    /// erroneously called RPL_INVITELIST, as this was the name used in RFC2812.
    case RPL_INVEXLIST(client: String, channel: String, mask: String)

    /// # 347: <client> <channel> :End of Channel Invite Exception List
    /// Sent as a reply to the MODE command, this numeric indicates the end of a channel’s invite-exception list. This numeric should not be confused with
    /// RPL_ENDOFINVITELIST (337), which is used as a reply to INVITE. This numeric is sometimes erroneously called RPL_ENDOFINVITELIST, as this was
    /// the name used in RFC2812.
    case RPL_ENDOFINVEXLIST(client: String, channel: String)

    /// # 348: <client> <channel> <mask>
    /// Sent as a reply to the MODE command, when clients are viewing the current entries on a channel’s exception list. <mask> is the given mask on the
    /// exception list.
    case RPL_EXCEPTLIST(client: String, channel: String, mask: String)

    /// # 349: <client> <channel> :End of channel exception list
    /// Sent as a reply to the MODE command, this numeric indicates the end of a channel’s exception list.
    case RPL_ENDOFEXCEPTLIST(client: String, channel: String)

    /// # 351: <client> <version> <server> :<comments>
    /// Sent as a reply to the VERSION command, this numeric indicates information about the desired server. <version> is the name and version of the
    /// software being used (including any revision information). <server> is the name of the server. <comments> may contain any further comments or
    /// details about the specific version of the server.
    case RPL_VERSION(client: String, version: String, server: String, comments: String)

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
    case RPL_WHOREPLY(client: String, channel: String, ident: String, hostname: String, server: String, nick: String, flags: String, name: String)

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

    /// # 364: <client> <server1> <server2> :<hopcount> <server info>
    /// Sent as a reply to the LINKS command, this numeric specifies servers <server1> and <server2> are linked together. For servers which follow a
    /// spanning tree topology, <server2> is the closest to the client. <server info> is a string containing a description of that server.
    case RPL_LINKS(client: String, server1: String, server2: String, hopcount: Int, serverInfo: String)

    /// # 365: <client> * :End of /LINKS list
    /// Sent as a reply to the LINKS command, this numeric specifies the end of a list of channel member names.
    case RPL_ENDOFLINKS(client: String)

    /// # 366: <client> <channel> :End of /NAMES list
    /// Sent as a reply to the NAMES command, this numeric specifies the end of a list of channel member names.
    case RPL_ENDOFNAMES(client: String, channel: String, text: String)

    /// # 367: <client> <channel> <mask> [<who> <set-ts>]
    /// Sent as a reply to the MODE command, when clients are viewing the current entries on a channel’s ban list. <mask> is the given mask on the ban list.
    /// <who> and <set-ts> are optional and MAY be included in responses. <who> is either the nickname or nickmask of the client that set the ban, or a
    /// server name, and <set-ts> is the UNIX timestamp of when the ban was set.
    case RPL_BANLIST(client: String, channel: String, mask: String)

    /// # 368: <client> <channel> :End of channel ban list
    /// Sent as a reply to the MODE command, this numeric indicates the end of a channel’s ban list.
    case RPL_ENDOFBANLIST(client: String, channel: String)

    /// # 369: <client> <nick> :End of WHOWAS
    /// Sent as a reply to the WHOWAS command, this numeric indicates the end of a WHOWAS reponse for the nickname <nick>. This numeric is sent after
    /// all other WHOWAS response numerics have been sent to the client.
    case RPL_ENDOFWHOWAS(client: String, nick: String)

    /// # 371: <client> :<string>
    /// Sent as a reply to the INFO command, this numeric returns human-readable information describing the server: e.g. its version, list of authors and
    /// contributors, and any other miscellaneous information which may be considered to be relevant.
    case RPL_INFO(client: String, text: String)

    /// # 372: <client> :<line of the motd>
    /// When sending the Message of the Day to the client, servers reply with each line of the MOTD as this numeric. MOTD lines MAY be wrapped to 80
    /// characters by the server.
    case RPL_MOTD(client: String, text: String)

    /// # 374: <client> :End of INFO list
    /// Indicates the end of an INFO response.
    case RPL_ENDOFINFO(client: String)

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

    /// # 400: <client> <command>{ <subcommand>} :<info>
    /// Indicates that the given command/subcommand could not be processed. <subcommand> may repeat for more specific subcommands.
    case ERR_UNKNOWNERROR

    /// # 401: <client> <nickname> :No such nick/channel
    /// Indicates that no client can be found for the supplied nickname. The text used in the last param of this message may vary.
    case ERR_NOSUCHNICK(client: String, nick: String, text: String)

    /// # 402:
    case ERR_NOSUCHSERVER

    /// # 403:
    case ERR_NOSUCHCHANNEL(client: String, channel: String, text: String)

    /// # 404:
    case ERR_CANNOTSENDTOCHAN

    /// # 405:
    case ERR_TOOMANYCHANNELS

    /// # 406:
    case ERR_WASNOSUCHNICK

    /// # 409:
    case ERR_NOORIGIN

    /// # 411:
    case ERR_NORECIPIENT

    /// # 412:
    case ERR_NOTEXTTOSEND

    /// # 417:
    case ERR_INPUTTOOLONG

    /// # 421:
    case ERR_UNKNOWNCOMMAND

    /// # 422:
    case ERR_NOMOTD

    /// # 431:
    case ERR_NONICKNAMEGIVEN

    /// # 432:
    case ERR_ERRONEUSNICKNAME

    /// # 433:
    case ERR_NICKNAMEINUSE

    /// # 436:
    case ERR_NICKCOLLISION

    /// # 441:
    case ERR_USERNOTINCHANNEL

    /// # 442:
    case ERR_NOTONCHANNEL(client: String, channel: String, text: String)

    /// # 443:
    case ERR_USERONCHANNEL

    /// # 451:
    case ERR_NOTREGISTERED

    /// # 461:
    case ERR_NEEDMOREPARAMS

    /// # 462:
    case ERR_ALREADYREGISTERED

    /// # 464:
    case ERR_PASSWDMISMATCH

    /// # 465:
    case ERR_YOUREBANNEDCREEP

    /// # 471:
    case ERR_CHANNELISFULL

    /// # 472:
    case ERR_UNKNOWNMODE

    /// # 473:
    case ERR_INVITEONLYCHAN

    /// # 474:
    case ERR_BANNEDFROMCHAN

    /// # 475:
    case ERR_BADCHANNELKEY

    /// # 476:
    case ERR_BADCHANMASK

    /// # 481:
    case ERR_NOPRIVILEGES

    /// # 482:
    case ERR_CHANOPRIVSNEEDED(client: String, channel: String, text: String)

    /// # 483:
    case ERR_CANTKILLSERVER

    /// # 491:
    case ERR_NOOPERHOST

    /// # 501:
    case ERR_UMODEUNKNOWNFLAG

    /// # 502:
    case ERR_USERSDONTMATCH

    /// # 524:
    case ERR_HELPNOTFOUND

    /// # 525:
    case ERR_INVALIDKEY

    /// # 691:
    case ERR_STARTTLS

    /// # 696:
    case ERR_INVALIDMODEPARAM

    /// # 723:
    case ERR_NOPRIVS

    /// # 902:
    case ERR_NICKLOCKED

    /// # 904: <client> :SASL authentication failed
    /// This numeric indicates that SASL authentication failed because of invalid credentials or other errors not explicitly mentioned by other numerics. For more
    /// information on this numeric, see the IRCv3 sasl-3.1 extension. The text used in the last param of this message varies wildly.
    case ERR_SASLFAIL(client: String, text: String)

    /// # 905:
    case ERR_SASLTOOLONG

    /// # 906:
    case ERR_SASLABORTED

    /// # 907:
    case ERR_SASLALREADY

    public init?(_ string: String, params: [String]) {
        guard let code = UInt16(string) else {
            return nil
        }
        switch code {
        case 001:
            guard params.count >= 2 else { return nil }
            self = .RPL_WELCOME(client: params[0], text: params[1])
        case 002:
            guard params.count >= 2 else { return nil }
            self = .RPL_YOURHOST(client: params[0], text: params[1])
        case 003:
            guard params.count >= 2 else { return nil }
            self = .RPL_CREATED(client: params[0], text: params[1])
        case 004:
            guard params.count >= 6 else { return nil }
            self = .RPL_MYINFO(client: params[0], servername: params[1], version: params[2], userModes: params[3], channelModes: params[4], channelModesWithParameters: params[5])
        case 005:
            guard params.count >= 3 else { return nil }
            self = .RPL_ISUPPORT(client: params[0], tokens: Array(params[1..<params.count-1]))
        case 010:
            guard params.count >= 4 else { return nil }
            self = .RPL_BOUNCE(client: params[0], hostname: params[1], Port: params[2], info: params[3])
        case 221:
            guard params.count >= 2 else { return nil }
            self = .RPL_UMODEIS(client: params[0], modes: params[1])
        case 251: self = .RPL_LUSERCLIENT
        case 252:
            guard params.count >= 2 else { return nil }
            guard let count = Int(params[1]) else { return nil }
            self = .RPL_LUSEROP(client: params[0], ops: count)
        case 253:
            guard params.count >= 2 else { return nil }
            guard let count = Int(params[1]) else { return nil }
            self = .RPL_LUSERUNKNOWN(client: params[0], connections: count)
        case 254:
            guard params.count >= 2 else { return nil }
            guard let count = Int(params[1]) else { return nil }
            self = .RPL_LUSERCHANNELS(client: params[0], channels: count)
        case 255:
            guard params.count >= 2 else { return nil }
            self = .RPL_LUSERME(client: params[0], text: params[1])
        case 265:
            guard params.count >= 4 else { return nil }
            self = .RPL_LOCALUSERS(client: params[0], u: Int(params[1]) ?? 0, m: Int(params[2]) ?? 0, text: params[3])
        case 266:
            guard params.count >= 4 else { return nil }
            self = .RPL_GLOBALUSERS(client: params[0], u: Int(params[1]) ?? 0, m: Int(params[2]) ?? 0, text: params[3])
        case 301:
            guard params.count >= 3 else { return nil }
            self = .RPL_AWAY(client: params[0], nick: params[1], text: params[2])
        case 302:
            guard params.count >= 2 else { return nil }
            self = .RPL_USERHOST(client: params[0], reply: params[1])
        case 305:
            guard params.count >= 2 else { return nil }
            self = .RPL_UNAWAY(client: params[0], text: params[1])
        case 311:
            guard params.count >= 6 else { return nil }
            self = .RPL_WHOISUSER(client: params[0], nick: params[1], username: params[2], host: params[3], realname: params[5])
        case 312:
            self = .RPL_WHOISSERVER
        case 313:
            self = .RPL_WHOISOPERATOR
        case 314:
            self = .RPL_WHOWASUSER
        case 315:
            self = .RPL_ENDOFWHO
        case 317:
            self = .RPL_WHOISIDLE
        case 318:
            self = .RPL_ENDOFWHOIS
        case 319:
            self = .RPL_WHOISCHANNELS
        case 320:
            self = .RPL_WHOISSPECIAL
        case 321:
            guard params.count >= 1 else { return nil }
            self = .RPL_LISTSTART(client: params[0])
        case 322:
            guard params.count >= 4 else { return nil }
            self = .RPL_LIST(client: params[0], channel: params[1], count: Int(params[2]) ?? 0, topic: params[3].isEmpty ? nil : params[3])
        case 323:
            guard params.count >= 1 else { return nil }
            self = .RPL_LISTEND(client: params[0])
        case 324:
            guard params.count >= 3 else { return nil }
            let args = Array(params.dropFirst(3))
            self = .RPL_CHANNELMODEIS(client: params[0], channel: params[1], modestring: params[2], arguments: args.isEmpty ? nil : args)
        case 329:
            guard params.count >= 3 else { return nil }
            guard let interval = TimeInterval(params[2]) else { return nil }
            let date = Date(timeIntervalSince1970: interval)
            self = .RPL_CREATIONTIME(client: params[0], channel: params[1], creationtime: date)
        case 330:
            guard params.count >= 3 else { return nil }
            self = .RPL_WHOISACCOUNT(client: params[0], nick: params[1], account: params[2])
        case 331:
            guard params.count >= 2 else { return nil }
            self = .RPL_NOTOPIC(client: params[0], channel: params[1])
        case 332:
            guard params.count >= 3 else { return nil }
            self = .RPL_TOPIC(client: params[0], channel: params[1], topic: params[2])
        case 333:
            guard params.count >= 4 else { return nil }
            self = .RPL_TOPICWHOTIME(client: params[0], channel: params[1], nick: params[2], setat: params[3])
        case 336:
            guard params.count >= 2 else { return nil }
            self = .RPL_INVITELIST(client: params[0], channel: params[1])
        case 337:
            guard params.count >= 1 else { return nil }
            self = .RPL_ENDOFINVITELIST(client: params[0])
        case 338:
            self = .RPL_WHOISACTUALLY
        case 341:
            guard params.count >= 3 else { return nil }
            self = .RPL_INVITING(client: params[0], nick: params[1], channel: params[2])
        case 346:
            guard params.count >= 3 else { return nil }
            self = .RPL_INVEXLIST(client: params[0], channel: params[1], mask: params[2])
        case 347:
            guard params.count >= 2 else { return nil }
            self = .RPL_ENDOFINVEXLIST(client: params[0], channel: params[1])
        case 348:
            guard params.count >= 3 else { return nil }
            self = .RPL_EXCEPTLIST(client: params[0], channel: params[1], mask: params[2])
        case 349:
            guard params.count >= 2 else { return nil }
            self = .RPL_ENDOFEXCEPTLIST(client: params[0], channel: params[1])
        case 351:
            guard params.count >= 4 else { return nil }
            self = .RPL_VERSION(client: params[0], version: params[1], server: params[2], comments: params[3])
        case 352:
            guard params.count >= 8 else { return nil }
            self = .RPL_WHOREPLY(client: params[0], channel: params[1], ident: params[2], hostname: params[3], server: params[4], nick: params[5], flags: params[6], name: params[7])
        case 353:
            guard params.count >= 4 else { return nil }
            let nicks = params[3].split(separator: " ").map(String.init)
            self = .RPL_NAMREPLY(client: params[0], symbol: params[1], channel: params[2], nicks: nicks)
        case 364:
            guard params.count >= 5 else { return nil }
            self = .RPL_LINKS(client: params[0], server1: params[1], server2: params[2], hopcount: Int(params[3]) ?? 0, serverInfo: params[4])
        case 365:
            guard params.count >= 1 else { return nil }
            self = .RPL_ENDOFLINKS(client: params[0])
        case 366:
            guard params.count >= 3 else { return nil }
            self = .RPL_ENDOFNAMES(client: params[0], channel: params[1], text: params[2])
        case 367:
            guard params.count >= 3 else { return nil }
            self = .RPL_BANLIST(client: params[0], channel: params[1], mask: params[2])
        case 368:
            guard params.count >= 2 else { return nil }
            self = .RPL_ENDOFBANLIST(client: params[0], channel: params[1])
        case 369:
            guard params.count >= 2 else { return nil }
            self = .RPL_ENDOFWHOWAS(client: params[0], nick: params[1])
        case 371:
            guard params.count >= 2 else { return nil }
            self = .RPL_INFO(client: params[0], text: params[1])
        case 372:
            guard params.count >= 2 else { return nil }
            self = .RPL_MOTD(client: params[0], text: params[1])
        case 374:
            guard params.count >= 1 else { return nil }
            self = .RPL_ENDOFINFO(client: params[0])
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
        case 402:
            self = .ERR_NOSUCHSERVER
        case 403:
            guard params.count >= 3 else { return nil }
            self = .ERR_NOSUCHCHANNEL(client: params[0], channel: params[1], text: params[2])
        case 404:
            self = .ERR_CANNOTSENDTOCHAN
        case 405:
            self = .ERR_TOOMANYCHANNELS
        case 406:
            self = .ERR_WASNOSUCHNICK
        case 409:
            self = .ERR_NOORIGIN
        case 411:
            self = .ERR_NORECIPIENT
        case 412:
            self = .ERR_NOTEXTTOSEND
        case 417:
            self = .ERR_INPUTTOOLONG
        case 421:
            self = .ERR_UNKNOWNCOMMAND
        case 422:
            self = .ERR_NOMOTD
        case 431:
            self = .ERR_NONICKNAMEGIVEN
        case 432:
            self = .ERR_ERRONEUSNICKNAME
        case 433:
            self = .ERR_NICKNAMEINUSE
        case 436:
            self = .ERR_NICKCOLLISION
        case 441:
            self = .ERR_USERNOTINCHANNEL
        case 442:
            guard params.count >= 3 else { return nil }
            self = .ERR_NOTONCHANNEL(client: params[0], channel: params[1], text: params[2])
        case 443:
            self = .ERR_USERONCHANNEL
        case 451:
            self = .ERR_NOTREGISTERED
        case 461:
            self = .ERR_NEEDMOREPARAMS
        case 462:
            self = .ERR_ALREADYREGISTERED
        case 464:
            self = .ERR_PASSWDMISMATCH
        case 465:
            self = .ERR_YOUREBANNEDCREEP
        case 471:
            self = .ERR_CHANNELISFULL
        case 472:
            self = .ERR_UNKNOWNMODE
        case 473:
            self = .ERR_INVITEONLYCHAN
        case 474:
            self = .ERR_BANNEDFROMCHAN
        case 475:
            self = .ERR_BADCHANNELKEY
        case 476:
            self = .ERR_BADCHANMASK
        case 481:
            self = .ERR_NOPRIVILEGES
        case 482:
            guard params.count >= 3 else { return nil }
            self = .ERR_CHANOPRIVSNEEDED(client: params[0], channel: params[1], text: params[2])
        case 483:
            self = .ERR_CANTKILLSERVER
        case 491:
            self = .ERR_NOOPERHOST
        case 501:
            self = .ERR_UMODEUNKNOWNFLAG
        case 502:
            self = .ERR_USERSDONTMATCH
        case 524:
            self = .ERR_HELPNOTFOUND
        case 525:
            self = .ERR_INVALIDKEY
        case 691:
            self = .ERR_STARTTLS
        case 696:
            self = .ERR_INVALIDMODEPARAM
        case 723:
            self = .ERR_NOPRIVS
        case 902:
            self = .ERR_NICKLOCKED
        case 904:
            guard params.count >= 2 else { return nil }
            self = .ERR_SASLFAIL(client: params[0], text: params[1])
        case 905:
            self = .ERR_SASLTOOLONG
        case 906:
            self = .ERR_SASLABORTED
        case 907:
            self = .ERR_SASLALREADY
        default:
            return nil
        }
    }
}
