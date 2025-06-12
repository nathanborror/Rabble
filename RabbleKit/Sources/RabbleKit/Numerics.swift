import Foundation

public enum Numeric: UInt16, Codable, CaseIterable, Sendable {

    // Connection welcome and MOTD
    case rplWelcome       = 001
    case rplYourHost      = 002
    case rplCreated       = 003
    case rplMyInfo        = 004
    case rplISupport      = 005
    case rplBounce        = 010
    case rplMotdStart     = 375
    case rplMotd          = 372
    case rplEndOfMotd     = 376

    // Channel listing
    case rplListStart     = 321
    case rplList          = 322
    case rplListEnd       = 323

    // Names listing
    case rplNamReply      = 353
    case rplEndOfNames    = 366

    // Whois/Whowas/Who
    case rplWhoisUser     = 311
    case rplWhoisServer   = 312
    case rplWhoisOperator = 313
    case rplWhoisChannels = 319
    case rplEndOfWhois    = 318

    // Errors (sample)
    case errNoSuchNick    = 401
    case errNoSuchChannel = 403
    case errNotOnChannel  = 442

    // ...add more as needed

    case unknown = 0

    public init(_ string: String) {
        guard let code = UInt16(string) else {
            self = .unknown
            return
        }
        self = Numeric(rawValue: code) ?? .unknown
    }

    public var code: String {
        String(format: "%03d", rawValue)
    }
}
