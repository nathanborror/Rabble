import SwiftUI
import RabbleKit

struct MessageView: View {
    @Environment(ChannelViewModel.self) var channelViewModel

    let message: IRCMessage

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(message.timestamp.formatted(date: .omitted, time: .standard))
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
            case .join:
                Text("\(message.nick ?? "Unknown user") joined the channel")
            case .part:
                Text("\(message.nick ?? "Unknown user") left the channel")
            default:
                Text("nil")
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(.subheadline, design: .monospaced))
        .background(backgroundColor)
    }

    var backgroundColor: Color {
        if case .user(let nick, _, _) = message.prefix, channelViewModel.config.nick == nick {
            return .yellow.opacity(0.2)
        }
        return .clear
    }
}

struct PrivMsgUserView: View {
    let nick: String
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            HStack {
                Spacer(minLength: 0)
                Text(nick)
            }
            .fontWeight(.semibold)
            .frame(width: 120)
            Text(text)
        }
    }
}

struct PrivMsgServerView: View {
    let nick: String
    let text: String

    var body: some View {
        Text(nick+":")
            .fontWeight(.semibold)
            .foregroundStyle(.blue)
        + Text(text)
    }
}

struct PrivMsgServiceView: View {
    let nick: String
    let text: String

    var body: some View {
        Text(nick+":")
            .fontWeight(.semibold)
            .foregroundStyle(.green)
        + Text(text)
    }
}
