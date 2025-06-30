import Foundation
import SharedKit

public struct Config: Codable, Sendable {
    public var kind: Kind
    public var server: String
    public var port: UInt16

    /// The user's primary handle on IRC:  <nick>!<ident>@<host>
    public var nick: String

    /// Derived from the user's system login or identd service. If it cannot be verified, it may be prefixed with ~.
    public var ident: String?

    /// The account name when using SASL distinct from ident and nick. Often used interchangeably with ident in casual contexts.
    public var username: String

    /// The domain or IP address, can be an actual IP, hostname or cloaked value or privacy.
    public var host: String?

    /// Optionally sent during registration (USER command) and not typically visible in normal messages.
    public var realname: String?

    /// Email is necessary for registration.
    public var email: String?

    /// Password is necessary for registration.
    public var password: String?

    /// Current user modes set.
    public var modes: String?

    /// Current MOTD for the server.
    public var motd: String?

    public var capabilities: [String: Bool]
    public var availableUserModes: String?
    public var availableChannelModes: String?
    public var availableChannelModesWithParameters: String?
    public var support: [String: Value]
    public var created: Date
    public var modified: Date

    public enum Kind: Codable, Sendable {
        case network
        case simulation
    }


    public init(kind: Kind = .network, server: String, port: UInt16, nick: String, ident: String? = nil,
                username: String, host: String? = nil, realname: String? = nil, email: String? = nil,
                password: String? = nil, modes: String? = nil, motd: String? = nil, capabilities: [String : Bool] = [:],
                availableUserModes: String? = nil, availableChannelModes: String? = nil,
                availableChannelModesWithParameters: String? = nil, support: [String: Value] = [:]) {
        self.kind = kind
        self.server = server
        self.port = port
        self.nick = nick
        self.ident = ident
        self.username = username
        self.host = host
        self.realname = realname
        self.email = email
        self.password = password
        self.modes = modes
        self.motd = motd
        self.capabilities = capabilities
        self.availableUserModes = availableUserModes
        self.availableChannelModes = availableChannelModes
        self.availableChannelModesWithParameters = availableChannelModesWithParameters
        self.support = support
        self.created = .now
        self.modified = .now
    }
}
