import Foundation
import SharedKit

public struct IRC: Packagable {
    public var id: String
    public var session: Session?
    public var channels: [Channel]

    public init(id: String = .id, session: Session? = nil, channels: [Channel] = []) {
        self.id = id
        self.session = session
        self.channels = channels
    }

    // MARK: Packagable

    public static func load(url: URL) throws -> Self {
        var out = Self(session: nil, channels: [])

        let sessionData = try Data(contentsOf: url.appending(path: "session.json"))
        out.session = try JSONDecoder().decode(Session.self, from: sessionData)

        let channelURLs = try FileManager.default.contentsOfDirectory(at: url.appending(path: "channels"), includingPropertiesForKeys: nil)
        for url in channelURLs {
            let channelData = try Data(contentsOf: url)
            let channel = try JSONDecoder().decode(Channel.self, from: channelData)
            out.channels.append(channel)
        }
        return out
    }

    public func write(url: URL) throws -> [(URL, Data)] {
        var out = [(URL, Data)]()

        // Encode session
        if let session {
            let sessionData = try JSONEncoder().encode(session)
            let sessionURL = url.appending(path: "session.json")
            out.append((sessionURL, sessionData))
        }

        // Encode channels
        let channelsURL = url.appending(path: "channels")
        try FileManager.default.createDirectory(at: channelsURL, withIntermediateDirectories: true)

        for channel in channels {
            let channelData = try JSONEncoder().encode(channel)
            let channelURL = channelsURL.appending(path: "\(channel.id).json")
            out.append((channelURL, channelData))
        }
        return out
    }

    // MARK: Mutations

    public mutating func upsert(channel: Channel) {
        if let index = channels.firstIndex(where: { $0.id == channel.id }) {
            channels[index] = channel
        } else {
            channels.append(channel)
        }
    }

    // MARK: Parsing

    public static func parseServerMessage(_ input: String) -> Message? {
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

        // 3. Parse command
        rest = rest.drop(while: { $0 == " " }) // remove leading spaces
        guard let firstSpace = rest.firstIndex(of: " ") else {
            // Only command, no params
            let command = String(rest)
            return .init(
                kind: .server,
                prefix: IRC.parsePrefix(prefix),
                command: .init(command),
                tags: tags            )
        }
        let command = String(rest[..<firstSpace])
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
            prefix: IRC.parsePrefix(prefix),
            command: .init(command),
            params: params,
            tags: tags
        )
    }

    public static func parsePrefix(_ prefix: String?) -> Message.Prefix? {
        guard let prefix else {
            return nil
        }
        if let exclam = prefix.firstIndex(of: "!") {
            let nick = String(prefix[..<exclam])
            let rest = prefix[prefix.index(after: exclam)...]
            if let at = rest.firstIndex(of: "@") {
    //            let user = String(rest[..<at])
    //            let host = String(rest[rest.index(after: at)...])
                if knownServices.contains(nick) {
                    return .service(nick)
                }
                return .user(nick)
            } else {
                if knownServices.contains(nick) {
                    return .service(nick)
                }
                return .user(nick)
            }
        } else if let at = prefix.firstIndex(of: "@") {
            let nick = String(prefix[..<at])
    //        let host = String(prefix[prefix.index(after: at)...])
            if knownServices.contains(nick) {
                return .service(nick)
            }
            return .user(nick)
        } else if prefix.contains(".") {
            return .server(prefix)
        } else {
            if knownServices.contains(prefix) {
                return .service(prefix)
            }
            return .user(prefix)
        }
    }

    private static let knownServices: Set<String> = [
        "NickServ", "ChanServ", "MemoServ", "OperServ", "BotServ", "HostServ", "HelpServ", "Global"
    ]
}
