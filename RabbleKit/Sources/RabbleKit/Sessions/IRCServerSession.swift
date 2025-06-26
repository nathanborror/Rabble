import Foundation
import OSLog
import Network
import SharedKit

private let logger = Logger(subsystem: "IRCServerSession", category: "IRC")

@MainActor
@Observable
public class IRCServerSession: IRCSession {

    public var fileID: String
    public var server: IRCServer

    public var isConnected = false
    public var isAuthenticated = false
    public var error: IRCSessionError? = nil

    private var connection: NWConnection? = nil
    private var incomingDataBuffer = ""
    private var motdBuffer = ""

    struct PendingRequest {
        let continuation: CheckedContinuation<Void, Error>
        let expectedResponse: (IRCMessage) -> Bool
        let timeout: Date
    }

    private var pendingRequests: [String: PendingRequest] = [:]

    public init(fileID: String, server: IRCServer) {
        self.fileID = fileID
        self.server = server
    }

    // MARK: Session Interface

    public func connect() async throws {
        clearLogs()

        let endpoint = NWEndpoint.hostPort(host: .init(server.config.server), port: .init(integerLiteral: server.config.port))
        connection = NWConnection(to: endpoint, using: .tcp)
        connection?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { try await handleStateUpdate(state: state) }
        }
        connection?.start(queue: .main)
    }

    public func disconnect() {
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    public func channel(_ channelID: String) throws -> IRCChannel {
        guard let channel = server.channels.first(where: { $0.id == channelID }) else {
            throw IRCSessionError.channelNotFound
        }
        return channel
    }

    public func send(_ line: String) {
        let line = line+"\r\n"
        guard let data = line.data(using: .utf8) else { return }
        connection?.send(content: data, completion: .contentProcessed { error in
            guard let error else { return }
            logger.error("\(error)")
        })
    }

    public func send(_ line: String, expecting: @escaping (IRCMessage) -> Bool, timeout: TimeInterval = 10) async throws {
        try await withCheckedThrowingContinuation { continuation in
            let id = String.id

            // Update pending requests queue
            pendingRequests[id] = .init(
                continuation: continuation,
                expectedResponse: expecting,
                timeout: .now.addingTimeInterval(timeout)
            )

            // Send line to server
            send(line)

            // Wait for possible timeout, remove request from queue upon timeout
            Task {
                try await Task.sleep(for: .seconds(timeout))
                if let request = pendingRequests.removeValue(forKey: id) {
                    request.continuation.resume(throwing: IRCSessionError.timeout)
                }
            }
        }
    }

    public func sendChannelJoin(_ channel: String) {
        let messages = [
            "JOIN \(channel)",
            "WHO \(channel)",
            "MODE \(channel)",
            "CHATHISTORY LATEST \(channel) * 20",
        ]
        for message in messages {
            send(message)
        }
    }

    public func sendChannelInfo(_ channel: String) {
        let messages = [
            "WHO \(channel)",
            "MODE \(channel)",
        ]
        for message in messages {
            send(message)
        }
    }

    public func sendChannelPart(_ channel: String) {
        send("PART \(channel)")
    }

    public func save() {
        Task {
            do {
                try await API.shared.fileUpdate(fileID, package: server)
            } catch {
                logger.error("\(error)")
            }
        }
    }

    public func clearLogs() {
        server.config.logs = []
    }

    // MARK: Connection Handlers

    func handleStateUpdate(state: NWConnection.State) async throws {
        switch state {
        case .ready:
            isConnected = true

            // Start listening immediatly
            handleListen()

            // Request capabilities
            try await send("CAP LS 302") { message in
                message.command == .cap
            }
            try await send("CAP REQ :draft/chathistory echo-message server-time message-tags batch labeled-response sasl") { message in
                message.command == .cap && message.params.contains("ACK")
            }

            send("CAP END")

            // Authenticate (SASL)
            if !isAuthenticated, let password = server.config.password {
                let token = "\0\(server.config.username)\0\(password)".data(using: .utf8)!
                send("AUTHENTICATE PLAIN")
                send("AUTHENTICATE \(token.base64EncodedString())")
            }

            send("NICK \(server.config.nick)")
            send("USER \(server.config.ident ?? server.config.username) 0 * :\(server.config.realname ?? "-")")

            // Rejoin channels
            for channel in server.channels {
                sendChannelJoin(channel.id)
            }
        case .failed(let error):
            self.error = .unhandled(error)
            disconnect()
        case .cancelled:
            disconnect()
        case .preparing:
            logger.info("preparing")
        default:
            break
        }
    }

    func handleListen() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                await self.handleIncomingData(data)
                if error == nil {
                    self.handleListen()
                }
            }
        }
    }

    func handleIncomingData(_ data: Data?) async {
        guard let data, let newText = String(data: data, encoding: .utf8) else { return }
        incomingDataBuffer += newText

        while let range = incomingDataBuffer.range(of: "\r\n") {
            let line = String(incomingDataBuffer[..<range.lowerBound])
            incomingDataBuffer = String(incomingDataBuffer[range.upperBound...]) // Remove parsed line + delimiter

            guard let message = parseServerMessage(line) else {
                return
            }

            // Check pending requests
            for (id, request) in pendingRequests {
                if request.expectedResponse(message) {
                    pendingRequests.removeValue(forKey: id)
                    request.continuation.resume()
                    break
                }
            }

            // Respond to periodic PINGs to maintain the connection
            switch message.command {
            case .ping:
                let pong = "PONG \(message.params[0])"
                send(pong)
            default:
                break
            }

            // Upsert new line to config object
            upsertConfigLog(message)

            // Handle command and numeric
            do {
                try await handleMessageCommand(message)
                try await handleMessageNumeric(message)
            } catch let error as IRCSessionError {
                self.error = error
            } catch {
                self.error = .unhandled(error)
            }
        }
        save()
    }

    func handleMessageCommand(_ message: IRCMessage) async throws {
        switch message.command {
        case let .join(channel):
            upsertChannel(.init(name: channel, created: .now))
            upsertConfigChannel(.init(name: channel))
        case let .part(channel, _):
            try removeChannel(channel)
        case let .privmsg(channel, _):
            try upsertChannelMessage(message, channelID: channel)
        case .cap:
            upsertConfigCapabilities(message.params)
        case let .topic(channel, text):
            try upsertChannelTopic(text, channelID: channel)
        default:
            return
        }
    }

    func handleMessageNumeric(_ message: IRCMessage) async throws {
        switch message.numeric {
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
        case let .RPL_NAMREPLY(_, _, channel, nicks):
            try upsertChannelUsers(nicks, channelID: channel)
        case let .RPL_WHOREPLY(_, channel, _, _, _, nick, _, _):
            try upsertChannelUsers([nick], channelID: channel)
        case let .RPL_TOPIC(_, channel, text):
            try upsertChannelTopic(text, channelID: channel)

        // MOTD

        case .RPL_MOTDSTART:
            motdBuffer = ""
        case let .RPL_MOTD(_, text):
            motdBuffer += text.trimmingPrefix("- ") + "\n"
        case .RPL_ENDOFMOTD:
            server.config.motd = motdBuffer

        // Errors

        case .ERR_SASLFAIL:
            throw IRCSessionError.authenticationFailed

        default:
            return
        }
    }

    // MARK: Config

    func upsertConfigLog(_ message: IRCMessage) {
        var logs = server.config.logs
        if let index = logs.firstIndex(where: { $0.id == message.id }) {
            logs[index] = message
        } else {
            logs.append(message)
        }
        server.config.logs = logs
    }

    func upsertConfigChannel(_ channel: IRCConfig.Channel) {
        var list = server.config.list
        if let index = list.firstIndex(where: { $0.id == channel.id }) {
            let existing = list[index].apply(channel)
            list[index] = existing
        } else {
            list.append(channel)
        }
        server.config.list = list
    }

    func upsertConfigCapabilities(_ params: [String]) {
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

    // MARK: Channels

    func upsertChannel(_ channel: IRCChannel) {
        var channels = server.channels
        if let index = channels.firstIndex(where: { $0.id == channel.id }) {
            let existing = channels[index].apply(channel)
            channels[index] = existing
        } else {
            channels.append(channel)
        }
        server.channels = channels
    }

    func upsertChannelUsers(_ nicks: [String], channelID: String) throws {
        var channel = try channel(channelID)
        for nick in nicks {
            channel.users[nick] = .init(nick: nick, modes: [])
        }
        upsertChannel(channel)
    }

    func upsertChannelMessage(_ message: IRCMessage, channelID: String) throws {
        var channel = try channel(channelID)
        var messages = channel.messages
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            let existing = messages[index].apply(message)
            messages[index] = existing
        } else {
            messages.append(message)
        }
        channel.messages = messages
        upsertChannel(channel)
    }

    func upsertChannelTopic(_ topic: String, channelID: String) throws {
        var channel = try channel(channelID)
        channel.topic = .init(message: topic)
        upsertChannel(channel)
    }

    func removeChannel(_ channelID: String) throws {
        guard let index = server.channels.firstIndex(where: { $0.id == channelID }) else {
            throw IRCSessionError.channelNotFound
        }
        server.channels.remove(at: index)
    }

    // MARK: Parsing

    func parseServerMessage(_ input: String) -> IRCMessage? {
        var rest = input[...]

        // 1. Parse tags
        var tags: [String: String]? = nil
        if rest.first == "@" {
            rest.removeFirst()
            if let space = rest.firstIndex(of: " ") {
                let tagsString = rest[..<space]
                tags = Dictionary(uniqueKeysWithValues: tagsString.split(separator: ";").compactMap { tag in
                    let parts = tag.split(separator: "=", maxSplits: 1, omittingEmptySubsequences: false)
                    let key = String(parts[0])
                    let value = parts.count > 1 ? String(parts[1]) : ""
                    return (key, value)
                })
                rest = rest[rest.index(after: space)...]
            } else {
                return nil
            }
        }

        // 2. Parse prefix
        var prefix: String? = nil
        if rest.first == ":" {
            rest.removeFirst()
            if let space = rest.firstIndex(of: " ") {
                prefix = String(rest[..<space])
                rest = rest[rest.index(after: space)...]
            } else {
                return nil
            }
        }

        // 3. Parse instruction with no params
        rest = rest.drop(while: { $0 == " " }) // remove leading spaces
        guard let firstSpace = rest.firstIndex(of: " ") else {
            let value = String(rest)
            return .init(
                kind: .server,
                prefix: parseServerMessagePrefix(prefix),
                numeric: .init(value, params: []),
                command: .init(value, params: []),
                tags: tags,
                raw: input
            )
        }
        let instruction = String(rest[..<firstSpace])
        rest = rest[firstSpace...]

        // 4. Parse params (middle and trailing)
        var params: [String] = []
        var i = rest.startIndex
        while i < rest.endIndex {
            // Skip spaces
            while i < rest.endIndex && rest[i] == " " { i = rest.index(after: i) }
            if i == rest.endIndex { break }
            if rest[i] == ":" {
                // trailing param
                let trailingStart = rest.index(after: i)
                let trailing = String(rest[trailingStart...])
                params.append(trailing)
                break
            }
            // middle param
            let nextSpace = rest[i...].firstIndex(of: " ") ?? rest.endIndex
            let param = String(rest[i..<nextSpace])
            params.append(param)
            i = nextSpace
        }
        return .init(
            kind: .server,
            prefix: parseServerMessagePrefix(prefix),
            numeric: .init(instruction, params: params),
            command: .init(instruction, params: params),
            params: params,
            tags: tags,
            raw: input
        )
    }

    func parseServerMessagePrefix(_ prefix: String?) -> IRCMessage.Prefix? {
        guard let prefix else {
            return nil
        }
        if let exclam = prefix.firstIndex(of: "!") {
            let nick = String(prefix[..<exclam])
            let rest = prefix[prefix.index(after: exclam)...]
            if let at = rest.firstIndex(of: "@") {
                let ident = String(rest[..<at])
                let host = String(rest[rest.index(after: at)...])
                if knownServices.contains(nick) {
                    return .service(nick)
                }
                return .user(nick: nick, ident: ident, host: host)
            } else {
                if knownServices.contains(nick) {
                    return .service(nick)
                }
                return .user(nick: nick, ident: nil, host: nil)
            }
        } else if let at = prefix.firstIndex(of: "@") {
            let nick = String(prefix[..<at])
            let host = String(prefix[prefix.index(after: at)...])
            if knownServices.contains(nick) {
                return .service(nick)
            }
            return .user(nick: nick, ident: nil, host: host)
        } else if prefix.contains(".") {
            return .server(prefix)
        } else {
            if knownServices.contains(prefix) {
                return .service(prefix)
            }
            return .user(nick: prefix, ident: nil, host: nil)
        }
    }

    func parseServerTime(_ input: String?) -> Date? {
        guard let input else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: input)
    }

    let knownServices: Set<String> = [
        "NickServ", "ChanServ", "MemoServ", "OperServ", "BotServ", "HistServ", "HostServ", "HelpServ", "Global"
    ]
}
