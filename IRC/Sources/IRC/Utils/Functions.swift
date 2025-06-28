import Foundation

/// Returns a list of unique items based on the given lists of identifiable items.
func union<T: Identifiable>(_ lists: [T]...) -> [T] {
    var seen: [T.ID: T] = [:]
    for list in lists {
        for item in list {
            seen[item.id] = item
        }
    }
    return Array(seen.values)
}

func parseMessage(_ input: String) -> Message? {
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
        var message = Message(
            kind: .server,
            prefix: prefix,
            numeric: .init(value, params: []),
            command: .init(value, params: []),
            tags: tags,
            raw: input
        )
        parseMessagePrefix(&message)
        return message
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
    var message = Message(
        kind: .server,
        prefix: prefix,
        numeric: .init(instruction, params: params),
        command: .init(instruction, params: params),
        params: params,
        tags: tags,
        raw: input
    )
    parseMessagePrefix(&message)
    return message
}

func parseMessagePrefix(_ message: inout Message) {
    guard let prefix = message.prefix else { return }
    if let exclam = prefix.firstIndex(of: "!") {
        let nick = String(prefix[..<exclam])
        let rest = prefix[prefix.index(after: exclam)...]
        if let at = rest.firstIndex(of: "@") {
            let ident = String(rest[..<at])
            let host = String(rest[rest.index(after: at)...])
            if knownServices.contains(nick) {
                message.nick = nick
            }
            message.nick = nick
            message.ident = ident
            message.host = host
        } else {
            if knownServices.contains(nick) {
                message.nick = nick
            }
            message.nick = nick
        }
    } else if let at = prefix.firstIndex(of: "@") {
        let nick = String(prefix[..<at])
        let host = String(prefix[prefix.index(after: at)...])
        if knownServices.contains(nick) {
            message.nick = nick
        }
        message.nick = nick
        message.host = host
    } else if prefix.contains(".") {
        message.nick = prefix
    } else {
        if knownServices.contains(prefix) {
            message.nick = prefix
        }
        message.nick = prefix
    }
}

func parseTime(_ input: String?) -> Date? {
    guard let input else { return nil }
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: input)
}

let knownServices: Set<String> = [
    "NickServ", "ChanServ", "MemoServ", "OperServ", "BotServ", "HistServ", "HostServ", "HelpServ", "Global"
]
