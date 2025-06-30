import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCSession", category: "IRC")

public enum IRCSessionError: Error, CustomStringConvertible {
    case channelNotFound
    case channelMemberNotFound
    case authenticationFailed
    case timeout
    case unhandled(Error)

    public var description: String {
        switch self {
        case .channelNotFound:
            "Channel not found"
        case .channelMemberNotFound:
            "Channel member not found"
        case .authenticationFailed:
            "Authentication failed"
        case .timeout:
            "Timeout"
        case .unhandled(let error):
            "Unhandled error: \(error)"
        }
    }
}

public struct IRCPendingRequest {
    let continuation: CheckedContinuation<Void, Error>
    let expectedResponse: (Message) -> Bool
    let timeout: Date
}

@MainActor
public protocol IRCSession: AnyObject {

    var server: Server { get set }
    var pending: [String: IRCPendingRequest] { get set }
    var buffer: String { get set }
    var isConnected: Bool { get }
    var isAuthenticated: Bool { get }
    var error: IRCSessionError? { get set }

    func connect() async throws
    func disconnect() async throws
    func send(_ line: String) async throws
}

// MARK: Conevenience

extension IRCSession {

    public func send(_ line: String, expecting: @escaping (Message) -> Bool, timeout: TimeInterval = 10) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let id = String.id

            // Update pending requests queue
            pending[id] = .init(
                continuation: continuation,
                expectedResponse: expecting,
                timeout: .now.addingTimeInterval(timeout)
            )

            // Send line to server
            Task {
                try await send(line)
            }

            // Wait for possible timeout, remove request from queue upon timeout
            Task {
                try await Task.sleep(for: .seconds(timeout))
                if let request = pending.removeValue(forKey: id) {
                    request.continuation.resume(throwing: IRCSessionError.timeout)
                }
            }
        }
    }
    
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

    public func channelKick(_ channel: String, nick: String, comment: String?) async throws {
        try await send("KICK \(channel) \(nick) :\(comment ?? "")")
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
        server.logs = []
    }
}

// MARK: Config

extension IRCSession {

    public func upsertLog(_ input: String) {
        var logs = server.logs
        logs.append(input)
        server.logs = logs
    }

    public func upsertChannelRef(_ channel: ChannelRef) {
        var list = server.channelList
        if let index = list.firstIndex(where: { $0.id == channel.id }) {
            let existing = list[index].apply(channel)
            list[index] = existing
        } else {
            list.append(channel)
        }
        server.channelList = list
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

    public func getChannelMember(_ userID: String, channelID: String) throws -> ChannelUser {
        let channel = try getChannel(channelID)
        guard let user = channel.users[userID] else {
            throw IRCSessionError.channelMemberNotFound
        }
        return user
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

    public func removeChannelNick(_ nick: String, channelID: String) throws {
        var channel = try getChannel(channelID)
        channel.users.removeValue(forKey: nick)
        try upsertChannel(channel)
    }
}

// MARK: Processors

extension IRCSession {

    public func processIncomingData(_ data: Data?) async throws {
        guard let data else { return }
        try await processIncomingString(String(data: data, encoding: .utf8))
    }

    public func processIncomingString(_ input: String?) async throws {
        guard let input else { return }
        buffer += input.replacingOccurrences(of: "\r\n", with: "\n")

        while let range = buffer.range(of: "\n") {
            let line = String(buffer[..<range.lowerBound])
            buffer = String(buffer[range.upperBound...]) // Remove parsed line + delimiter

            guard let message = parseMessage(line) else {
                return
            }

            // Check pending requests
            for (id, request) in pending {
                if request.expectedResponse(message) {
                    pending.removeValue(forKey: id)
                    request.continuation.resume()
                    break
                }
            }

            // Respond to periodic PINGs to maintain the connection
            switch message.command {
            case .PING:
                let pong = "PONG \(message.params[0])"
                try await send(pong)
            default:
                break
            }

            // Upsert new line to config object
            upsertLog(line)

            // Handle command and numeric
            do {
                try await processMessageCommand(message)
                try await processMessageNumeric(message)
            } catch let error as IRCSessionError {
                self.error = error
            } catch {
                self.error = .unhandled(error)
            }
        }
    }

    public func processMessageCommand(_ message: Message) async throws {
        guard let command = message.command else { return }
        switch command {
        case let .CAP(subcommand, capabilities):
            try await commandCAP(message, subcommand: subcommand, capabilities: capabilities)
        case .AUTHENTICATE:
            break
        case .PASS:
            break
        case let .NICK(nick):
            try await commandNICK(message, nick: nick)
        case .USER:
            break
        case .PING:
            break
        case .PONG:
            break
        case .OPER:
            break
        case .QUIT:
            break
        case .ERROR:
            break
        case let .JOIN(channel):
            try await commandJOIN(message, channel: channel)
        case let .PART(channel, reason):
            try await commandPART(message, channel: channel, reason: reason)
        case let .TOPIC(channel, text):
            try await commandTOPIC(message, channel: channel, text: text)
        case .NAMES:
            break
        case .LIST:
            break
        case let .INVITE(nick, channel):
            try await commandINVITE(message, channel: channel, nick: nick)
        case let .KICK(channel, nick, _):
            try await commandKICK(message, channel: channel, nick: nick)
        case .MOTD:
            break
        case .VERSION:
            break
        case .ADMIN:
            break
        case .CONNECT:
            break
        case .LUSERS:
            break
        case .TIME:
            break
        case .STATS:
            break
        case .HELP:
            break
        case .INFO:
            break
        case .MODE:
            break
        case let .PRIVMSG(target, _):
            try await commandPRIVMSG(message, target: target)
        case .NOTICE:
            break
        case .WHO:
            break
        case .WHOIS:
            break
        case .WHOWAS:
            break
        case .KILL:
            break
        case .REHASH:
            break
        case .RESTART:
            break
        case .SQUIT:
            break
        case .AWAY:
            break
        case .LINKS:
            break
        case .USERHOST:
            break
        case .WALLOPS:
            break
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
        case let .RPL_LIST(_, channel, count, topic):
            upsertChannelRef(.init(name: channel, users: count, topic: topic))
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

// MARK: Command State Changes

extension IRCSession {

    private func commandCAP(_ message: Message, subcommand: String, capabilities: [String]) async throws {
        if subcommand == "LS" {
            for cap in capabilities {
                let existing = server.config.capabilities[cap] ?? false
                server.config.capabilities[cap] = existing
            }
        }
        if subcommand == "ACK" {
            for cap in capabilities {
                server.config.capabilities[cap] = true
            }
        }
    }

    private func commandNICK(_ message: Message, nick: String) async throws {
        if let previousNick = message.nick {
            for channel in server.channels {
                var existing = channel
                if var user = channel.users[previousNick] {
                    user.nick = nick
                    existing.users.removeValue(forKey: previousNick)
                    existing.users[nick] = user
                }
                try upsertChannel(existing)
            }
            if previousNick == server.config.nick {
                server.config.nick = nick
            }
        }
    }

    private func commandJOIN(_ message: Message, channel: String) async throws {
        if message.nick == server.config.nick {
            try upsertChannel(.init(name: channel))
        } else {
            try upsertChannelMessage(message, channelID: channel)
            if let nick = message.nick {
                try upsertChannelNick(nick, channelID: channel)
            }
        }
    }

    private func commandPART(_ message: Message, channel: String, reason: String?) async throws {
        try upsertChannelMessage(message, channelID: channel)
        if message.nick == server.config.nick {
            try removeChannel(channel)
        }
    }

    private func commandTOPIC(_ message: Message, channel: String, text: String) async throws {
        try upsertChannelMessage(message, channelID: channel)
        try upsertChannelTopic(text, channelID: channel)
    }

    private func commandINVITE(_ message: Message, channel: String, nick: String) async throws {
        if server.config.nick == nick {
            try await channelJoin(channel)
        }
        try upsertChannelMessage(message, channelID: channel)
    }

    private func commandKICK(_ message: Message, channel: String, nick: String) async throws {
        try upsertChannelMessage(message, channelID: channel)
        if server.config.nick == nick {
            try removeChannel(channel)
        } else {
            try removeChannelNick(nick, channelID: channel)
        }
    }

    private func commandPRIVMSG(_ message: Message, target: String) async throws {
        if target.hasPrefix("#") {
            try upsertChannelMessage(message, channelID: target)
        } else {
            // TODO: Implement private direct messages
            print("[target: \(target)] not implemented")
        }
    }
}
