import Foundation

extension IRC {

    public enum Numeric: Codable, CaseIterable, Sendable {

        // Connection welcome and MOTD
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

        // Whois/Whowas/Who
        case RPL_WHOISUSER
        case RPL_WHOISSERVER
        case RPL_WHOISOPERATOR
        case RPL_ENDOFWHO
        case RPL_ENDOFWHOIS
        case RPL_WHOISCHANNELS

        // Channels
        case RPL_LISTSTART
        case RPL_LIST
        case RPL_LISTEND
        case RPL_CHANNELMODEIS
        case RPL_CREATIONTIME

        case RPL_TOPIC
        case RPL_TOPICWHOTIME

        // Names listing
        case RPL_WHOREPLY
        case RPL_NAMREPLY
        case RPL_ENDOFNAMES

        case RPL_MOTD
        case RPL_MOTDSTART
        case RPL_ENDOFMOTD

        case RPL_HOSTHIDDEN

        // Errors (sample)
        case ERR_NOSUCHNICK
        case ERR_NOSUCHCHANNEL
        case ERR_NOTONCHANNEL

        public init?(_ string: String) {
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

            // Whois/Whowas/Who
            case 311: self = .RPL_WHOISUSER
            case 312: self = .RPL_WHOISSERVER
            case 313: self = .RPL_WHOISOPERATOR
            case 315: self = .RPL_ENDOFWHO
            case 318: self = .RPL_ENDOFWHOIS
            case 319: self = .RPL_WHOISCHANNELS

            // Channels
            case 321: self = .RPL_LISTSTART
            case 322: self = .RPL_LIST
            case 323: self = .RPL_LISTEND
            case 324: self = .RPL_CHANNELMODEIS
            case 329: self = .RPL_CREATIONTIME

            case 332: self = .RPL_TOPIC
            case 333: self = .RPL_TOPICWHOTIME

            // Names listing
            case 352: self = .RPL_WHOREPLY
            case 353: self = .RPL_NAMREPLY
            case 366: self = .RPL_ENDOFNAMES

            case 372: self = .RPL_MOTD
            case 375: self = .RPL_MOTDSTART
            case 376: self = .RPL_ENDOFMOTD

            case 396: self = .RPL_HOSTHIDDEN

            // Errors (sample)
            case 401: self = .ERR_NOSUCHNICK
            case 403: self = .ERR_NOSUCHCHANNEL
            case 442: self = .ERR_NOTONCHANNEL
            default:
                return nil
            }
        }
    }
}
