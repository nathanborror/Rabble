import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCSession", category: "IRCKit")

public enum IRCSessionError: Error, CustomStringConvertible {
    case channelNotFound
    case authenticationFailed
    case timeout
    case unhandled(Error)

    public var description: String {
        switch self {
        case .channelNotFound:
            "Channel not found"
        case .authenticationFailed:
            "Authentication failed"
        case .timeout:
            "Timeout"
        case .unhandled(let error):
            "Unhandled error: \(error)"
        }
    }
}

@MainActor
public protocol IRCSession: AnyObject {

    var server: Server { get set }
    var isConnected: Bool { get }
    var isAuthenticated: Bool { get }
    var error: IRCSessionError? { get }

    func connect() async throws
    func disconnect() async throws

    func send(_ line: String) async throws
    func send(_ line: String, expecting: @escaping (Message) -> Bool, timeout: TimeInterval) async throws
}

extension IRCSession {
    
    public func channelJoin(_ channel: String, fetchHistory: Bool = false) async throws {
        try await send("JOIN \(channel)")
        try await send("WHO \(channel)")
        try await send("MODE \(channel)")
        if fetchHistory {
            try await send("CHATHISTORY LATEST \(channel) * 20")
        }
    }

    public func channelInfo(_ channel: String) async throws {
        try await send("WHO \(channel)")
        try await send("MODE \(channel)")
    }

    public func channelPart(_ channel: String) async throws {
        try await send("PART \(channel)")
    }
    
    public func nickServRegister(email: String, password: String) async throws {
        guard !isAuthenticated else { return }
        try await send("PRIVMSG NickServ :REGISTER \(password) \(email)")
    }

    public func nickServIdentify(password: String) async throws {
        guard !isAuthenticated else { return }
        try await send("PRIVMSG NickServ :IDENTIFY \(password)")
    }

    public func clearLogs() {
        server.config.logs = []
    }
}

// MARK: Config

extension IRCSession {

    public func upsertConfigLog(_ message: Message) {
        var logs = server.config.logs
        if let index = logs.firstIndex(where: { $0.id == message.id }) {
            logs[index] = message
        } else {
            logs.append(message)
        }
        server.config.logs = logs
    }

    public func upsertConfigChannel(_ channel: Config.Channel) {
        var list = server.config.list
        if let index = list.firstIndex(where: { $0.id == channel.id }) {
            let existing = list[index].apply(channel)
            list[index] = existing
        } else {
            list.append(channel)
        }
        server.config.list = list
    }

    public func upsertConfigCapabilities(_ params: [String]) {
        var capabilities = server.config.capabilities
        if params[1] == "LS" && params[2] == "*" {
            let caps = params[3].split(separator: " ").map(String.init)
            for cap in caps {
                capabilities[cap] = false
            }
        } else if params[1] == "LS" {
            let caps = params[2].split(separator: " ").map(String.init)
            for cap in caps {
                capabilities[cap] = false
            }
        }
        server.config.capabilities = capabilities
    }
}

// MARK: Channels

extension IRCSession {

    public func getChannel(_ channelID: String) throws -> Channel {
        guard let channel = server.channels.first(where: { $0.id == channelID }) else {
            throw IRCSessionError.channelNotFound
        }
        return channel
    }

    public func upsertChannel(_ channel: Channel) throws {
        var channels = server.channels
        if let index = channels.firstIndex(where: { $0.id == channel.id }) {
            let existing = channels[index].apply(channel)
            channels[index] = existing
        } else {
            channels.append(channel)
        }
        server.channels = channels
    }

    public func upsertChannelNicks(_ nicks: [String], channelID: String) throws {
        for nick in nicks {
            try upsertChannelNick(nick, channelID: channelID)
        }
    }

    public func upsertChannelNick(_ nick: String, channelID: String) throws {
        let user = ChannelUser(nick: nick)
        try upsertChannelUser(user, channelID: channelID)
    }

    public func upsertChannelUser(_ user: ChannelUser, channelID: String) throws {
        var channel = try getChannel(channelID)
        if let existing = channel.users[user.nick] {
            channel.users[user.nick] = existing.apply(user)
        } else {
            channel.users[user.nick] = user
        }
        try upsertChannel(channel)
    }

    public func upsertChannelMessage(_ message: Message, channelID: String) throws {
        var channel = try getChannel(channelID)
        var messages = channel.messages
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            let existing = messages[index].apply(message)
            messages[index] = existing
        } else {
            messages.append(message)
        }
        channel.messages = messages
        try upsertChannel(channel)
    }

    public func upsertChannelTopic(_ topic: String, channelID: String) throws {
        var channel = try getChannel(channelID)
        channel.topic = .init(message: topic)
        try upsertChannel(channel)
    }

    public func removeChannel(_ channelID: String) throws {
        guard let index = server.channels.firstIndex(where: { $0.id == channelID }) else {
            throw IRCSessionError.channelNotFound
        }
        server.channels.remove(at: index)
    }
}

// MARK: Processors

extension IRCSession {

    public func processMessageCommand(_ message: Message) async throws {
        switch message.command {
        case let .join(channels, keys):
            // Add channel(s) if the message is coming from the client's nick
            if message.nick == server.config.nick {
                for (index, channel) in channels.enumerated() {
                    let key = (keys.count > index) ? keys[index] : nil
                    try upsertChannel(.init(name: channel, key: key))
                }
            }
            // Add the message to the channel
            for channel in channels {
                try upsertChannelMessage(message, channelID: channel)
            }
        case let .part(channels, _):
            for channel in channels {
                try upsertChannelMessage(message, channelID: channel)
                if message.nick == server.config.nick {
                    try removeChannel(channel)
                }
            }
        case let .privmsg(targets, _):
            for target in targets {
                if target.hasPrefix("#") {
                    try upsertChannelMessage(message, channelID: target)
                } else {
                    // TODO: Implement private direct messages
                    print("[target: \(target)] not implemented")
                }
            }
        case .cap:
            upsertConfigCapabilities(message.params)
        case let .topic(channel, text):
            try upsertChannelTopic(text, channelID: channel)
            try upsertChannelMessage(message, channelID: channel)
        case let .invite(nick, channel):
            guard server.config.nick == nick else { return }
            try await channelJoin(channel)
        default:
            return
        }
    }

    public func processMessageNumeric(_ message: Message) async throws {
        switch message.numeric {
        case let .RPL_MYINFO(_, servername, _, userModes, channelModes, channelModesWithParameters):
            var config = server.config
            config.host = servername
            config.availableUserModes = userModes
            config.availableChannelModes = channelModes
            config.availableChannelModesWithParameters = channelModesWithParameters
            server.config = config
        case let .RPL_ISUPPORT(_, tokens):
            var config = self.server.config
            for token in tokens {
                let parts = token.split(separator: "=")
                if parts.count == 2 {
                    let key = String(parts[0])
                    let value = String(parts[1])
                    if let int = Int(value) {
                        config.support[key] = .int(int)
                    } else {
                        config.support[key] = .string(value)
                    }
                } else {
                    let key = String(parts[0])
                    config.support[key] = .bool(true)
                }
            }
            self.server.config = config
        case let .RPL_UMODEIS(_, modes):
            var config = server.config
            config.modes = modes
            server.config = config
        case .RPL_LIST:
            guard message.params.count >= 4 else {
                return
            }
            let name = message.params[1]
            let users = Int(message.params[2]) ?? 0
            let topic = message.params[3].isEmpty ? nil : message.params[3]
            guard name != "*" else {
                return
            }
            upsertConfigChannel(.init(name: name, users: users, topic: topic))
        case let .RPL_CHANNELMODEIS(_, channel, modestring, arguments):
            var channel = try getChannel(channel)
            channel.modes = modestring
            channel = channel.apply(modeArguments: arguments ?? [])
            try upsertChannel(channel)
        case let .RPL_TOPIC(_, channel, text):
            try upsertChannelTopic(text, channelID: channel)
        case let .RPL_INVITING(_, nick, channel):
            try upsertChannelNick(nick, channelID: channel)
        case let .RPL_WHOREPLY(_, channel, ident, hostname, server, nick, flags, name):
            let user = ChannelUser(nick: nick, ident: ident, name: name, hostname: hostname, server: server, flags: flags)
            try upsertChannelUser(user, channelID: channel)
        case let .RPL_NAMREPLY(_, _, channel, nicks):
            try upsertChannelNicks(nicks, channelID: channel)
        case let .RPL_MOTD(_, text):
            let motd = text.trimmingPrefix("- ") + "\n"
            server.config.motd = (server.config.motd ?? "" + motd)
        case .RPL_MOTDSTART:
            server.config.motd = ""
        case .ERR_SASLFAIL:
            throw IRCSessionError.authenticationFailed

        default:
            return
        }
    }
}
