import Foundation

func ParseServerMessage(_ input: String) -> Message? {
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
            prefix: ParsePrefix(prefix),
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
        prefix: ParsePrefix(prefix),
        command: .init(command),
        params: params,
        tags: tags
    )
}

func ParsePrefix(_ prefix: String?) -> Message.Prefix? {
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

private let knownServices: Set<String> = [
    "NickServ", "ChanServ", "MemoServ", "OperServ", "BotServ", "HostServ", "HelpServ", "Global"
]
