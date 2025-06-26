import SwiftUI
import RabbleKit

struct MessageView: View {
    let message: IRCMessage

    var body: some View {
        HStack {
            Text(message.tags?["time"] ?? message.created.formatted(date: .numeric, time: .standard))
                .font(.system(.subheadline, design: .monospaced))
                .foregroundStyle(.tertiary)

            switch message.command {
            case let .privmsg(_, text):
                if let prefix = message.prefix {
                    switch prefix {
                    case let .user(nick, _, _):
                        PrivMsgUserView(nick: nick, text: text)
                    case .server(let nick):
                        PrivMsgServerView(nick: nick, text: text)
                    case .service(let nick):
                        PrivMsgServiceView(nick: nick, text: text)
                    }
                } else {
                    Text(message.raw)
                }
            case let .notice(_, text):
                Text(text)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            case let .join(channel):
                Text(channel)
                    .font(.system(.subheadline, design: .monospaced))
                    .foregroundStyle(.secondary)
            default:
                Text("nil")
            }
        }
    }
}

struct PrivMsgUserView: View {
    let nick: String
    let text: String

    var body: some View {
        HStack {
            Text(nick+":")
                .fontWeight(.semibold)
            Text(text)
        }
        .font(.system(.subheadline, design: .monospaced))
    }
}

struct PrivMsgServerView: View {
    let nick: String
    let text: String

    var body: some View {
        HStack {
            Text(nick+":")
                .fontWeight(.semibold)
                .foregroundStyle(.blue)
            Text(text)
        }
        .font(.system(.subheadline, design: .monospaced))
    }
}

struct PrivMsgServiceView: View {
    let nick: String
    let text: String

    var body: some View {
        HStack {
            Text(nick+":")
                .fontWeight(.semibold)
                .foregroundStyle(.green)
            Text(text)
        }
        .font(.system(.subheadline, design: .monospaced))
    }
}
