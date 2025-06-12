import Foundation

public struct Message: Codable, Identifiable, Sendable {
    public var id = UUID()
    public var created: Date = .now

    public let tags: [String: String]?
    public let prefix: String?
    public let command: Command
    public let params: [String]

    init?(raw: String) {
        var rest = raw[...]

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
                // Only tags, invalid message
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
                // Only prefix, invalid message
                return nil
            }
        }

        // 3. Parse command
        rest = rest.drop(while: { $0 == " " }) // remove leading spaces
        guard let firstSpace = rest.firstIndex(of: " ") else {
            // Only command, no params
            let command = String(rest)
            self.tags = tags
            self.prefix = prefix
            self.command = .init(command)
            self.params = []
            return
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

        self.tags = tags
        self.prefix = prefix
        self.command = .init(command)
        self.params = params
    }
}

//public struct Message: Identifiable, Hashable {
//    public let id = UUID()
//    public let created: Date = .now
//
//    public let prefix: String?
//    public let command: String
//    public let params: [String]
//    public let trailing: String?
//
//    public init?(raw: String) {
//        var rest = raw[...]
//        var prefix: String? = nil
//        if rest.first == ":" {
//            rest.removeFirst()
//            if let space = rest.firstIndex(of: " ") {
//                prefix = String(rest[..<space])
//                rest = rest[rest.index(after: space)...]
//            } else {
//                return nil
//            }
//        }
//        guard let commandRange = rest.rangeOfCharacter(from: .whitespaces) else {
//            self.prefix = prefix
//            self.command = String(rest)
//            self.params = []
//            self.trailing = nil
//            return
//        }
//        let command = String(rest[..<commandRange.lowerBound])
//        rest = rest[commandRange.upperBound...]
//
//        // Params & trailing
//        var params: [String] = []
//        var trailing: String? = nil
//        while !rest.isEmpty {
//            if rest.first == ":" {
//                rest.removeFirst()
//                trailing = String(rest)
//                break
//            }
//            if let space = rest.firstIndex(of: " ") {
//                params.append(String(rest[..<space]))
//                rest = rest[rest.index(after: space)...]
//            } else {
//                params.append(String(rest))
//                break
//            }
//        }
//
//        self.prefix = prefix
//        self.command = command
//        self.params = params
//        self.trailing = trailing
//    }
//}
