import Foundation

public enum Numeric: UInt16, Codable, CaseIterable, Sendable {

    // Connection welcome and MOTD
    case RPL_WELCOME       = 001
    case RPL_YOURHOST      = 002
    case RPL_CREATED       = 003
    case RPL_MYINFO        = 004
    case RPL_ISUPPORT      = 005
    case RPL_BOUNCE        = 010

    case RPL_LUSERCLIENT   = 251
    case RPL_LUSEROP       = 252
    case RPL_LUSERUNKNOWN  = 253
    case RPL_LUSERCHANNELS = 254
    case RPL_LUSERME       = 255

    case RPL_LOCALUSERS    = 265
    case RPL_GLOBALUSERS   = 266

    // Whois/Whowas/Who
    case RPL_WHOISUSER     = 311
    case RPL_WHOISSERVER   = 312
    case RPL_WHOISOPERATOR = 313
    case RPL_ENDOFWHOIS    = 318
    case RPL_WHOISCHANNELS = 319

    // Channel listing
    case RPL_LISTSTART     = 321
    case RPL_LIST          = 322
    case RPL_LISTEND       = 323

    case RPL_TOPIC         = 332
    case RPL_TOPICWHOTIME  = 333

    // Names listing
    case RPL_NAMREPLY      = 353
    case RPL_ENDOFNAMES    = 366

    case RPL_MOTD          = 372
    case RPL_MOTDSTART     = 375
    case RPL_ENDOFMOTD     = 376

    // Errors (sample)
    case ERR_NOSUCHNICK    = 401
    case ERR_NOSUCHCHANNEL = 403
    case ERR_NOTONCHANNEL  = 442

    // ...add more as needed

    case UNKNOWN = 0

    public init(_ string: String) {
        guard let code = UInt16(string) else {
            self = .UNKNOWN
            return
        }
        self = Numeric(rawValue: code) ?? .UNKNOWN
    }

    public var code: String {
        String(format: "%03d", rawValue)
    }
}
