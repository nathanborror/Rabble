import Foundation

enum SlashCommand {
    case join(channel: String, key: String? = nil)
    case part(channel: String, reason: String? = nil)
    case topic(newTopic: String?)
    case kick(channel: String, nick: String, reason: String? = nil)
    case mode(target: String, modes: String)
    case whois(nick: String)
    case names
    case list(channel: String?)
    case quit(reason: String?)
    case nick(newNick: String)
    case msg(target: String, text: String)

    /// Parse a slash command from user input
    /// Returns nil if the input is not a slash command or is invalid
    static func parse(_ input: String) -> SlashCommand? {
        guard input.hasPrefix("/") else { return nil }

        let trimmed = input.dropFirst().trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let components = trimmed.split(
            separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        let command = String(components[0]).lowercased()
        let args = components.count > 1 ? String(components[1]) : ""

        switch command {
        case "join", "j":
            return parseJoin(args)

        case "part", "leave":
            return parsePart(args)

        case "topic", "t":
            return parseTopic(args)

        case "kick":
            return parseKick(args)

        case "mode", "m":
            return parseMode(args)

        case "whois", "wi":
            return parseWhois(args)

        case "names":
            return parseNames(args)

        case "list":
            return parseList(args)

        case "quit":
            return .quit(reason: args.isEmpty ? nil : args)

        case "nick":
            guard !args.isEmpty else { return nil }
            return .nick(newNick: args.trimmingCharacters(in: .whitespaces))

        case "msg", "query":
            return parseMsg(args)

        default:
            return nil
        }
    }

    // MARK: - Private Parsing Helpers

    private static func parseJoin(_ args: String) -> SlashCommand? {
        let parts = args.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard !parts.isEmpty else { return nil }

        let channel = String(parts[0])
        let key = parts.count > 1 ? String(parts[1]) : nil
        return .join(channel: channel, key: key)
    }

    private static func parsePart(_ args: String) -> SlashCommand? {
        let parts = args.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard !parts.isEmpty else { return nil }

        let channel = String(parts[0])
        let reason = parts.count > 1 ? String(parts[1]) : nil
        return .part(channel: channel, reason: reason)
    }

    private static func parseTopic(_ args: String) -> SlashCommand? {
        let newTopic = args.isEmpty ? nil : args
        return .topic(newTopic: newTopic)
    }

    private static func parseKick(_ args: String) -> SlashCommand? {
        let parts = args.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }

        let channel = String(parts[0])
        let nick = String(parts[1])
        let reason = parts.count > 2 ? String(parts[2]) : nil
        return .kick(channel: channel, nick: nick, reason: reason)
    }

    private static func parseMode(_ args: String) -> SlashCommand? {
        let parts = args.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }

        let target = String(parts[0])
        let modes = String(parts[1])
        return .mode(target: target, modes: modes)
    }

    private static func parseWhois(_ args: String) -> SlashCommand? {
        let nick = args.trimmingCharacters(in: .whitespaces)
        guard !nick.isEmpty else { return nil }
        return .whois(nick: nick)
    }

    private static func parseNames(_ args: String) -> SlashCommand? {
        return .names
    }

    private static func parseList(_ args: String) -> SlashCommand? {
        let channel = args.trimmingCharacters(in: .whitespaces)
        return .list(channel: channel.isEmpty ? nil : channel)
    }

    private static func parseMsg(_ args: String) -> SlashCommand? {
        let parts = args.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count >= 2 else { return nil }

        let target = String(parts[0])
        let text = String(parts[1])
        return .msg(target: target, text: text)
    }
}
