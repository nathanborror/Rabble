import SwiftUI
import IRC
import RabbleKit

struct MessageView: View {
    @Environment(ChannelViewModel.self) var channelViewModel

    let message: IRC.Message

    var body: some View {
        switch message.command {
        case let .PRIVMSG(_, text):
            MessageLine(
                timestamp: message.timestamp,
                nick: message.nick ?? "guest",
                text: text
            )
        case .JOIN:
            MessageLine(
                timestamp: message.timestamp,
                symbol: "hand.wave.fill",
                text: "\(message.nick ?? "Unknown user") joined"
            )
        case let .PART(_, reason):
            MessageLine(
                timestamp: message.timestamp,
                symbol: "door.left.hand.closed",
                text: "\(message.nick ?? "Unknown user") left \(reason != nil ? "(\(reason!))" : "")"
            )
        case let .KICK(_, nick, comment):
            MessageLine(
                timestamp: message.timestamp,
                symbol: "figure.kickboxing",
                text: "\(nick) was kicked \(comment != nil ? "(\(comment!))" : "")"
            )
        case let .TOPIC(_, text):
            MessageLine(
                timestamp: message.timestamp,
                symbol: "megaphone.fill",
                text: text
            )
        default:
            Text("nil")
        }
    }
}

struct MessageLine: View {
    @Environment(ChannelViewModel.self) var channelViewModel

    let timestamp: Date
    let nick: String?
    let symbol: String?
    let text: String

    init(timestamp: Date, nick: String, text: String) {
        self.timestamp = timestamp
        self.nick = nick
        self.symbol = nil
        self.text = text
    }

    init(timestamp: Date, symbol: String, text: String) {
        self.timestamp = timestamp
        self.nick = nil
        self.symbol = symbol
        self.text = text
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(timestamp.formatted(date: .omitted, time: .standard))
                .foregroundStyle(.tertiary)
                .frame(width: 80, alignment: .trailing)

            HStack(alignment: .firstTextBaseline) {
                HStack {
                    Spacer(minLength: 0)
                    if let nick {
                        Text(nick)
                            .lineLimit(1)
                    }
                    if let symbol {
                        Image(systemName: symbol)
                    }
                }
                .fontWeight(.semibold)
                .frame(width: 100)

                Text(text)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(.subheadline, design: .monospaced))
        .background(backgroundColor)
    }

    var backgroundColor: Color {
        if nick == channelViewModel.config.nick {
            return .yellow.opacity(0.2)
        }
        return .clear
    }
}
