import SwiftUI
import IRC

struct MessageView: View {

    let message: IRC.Message

    var body: some View {
        switch message.command {
        case "PRIVMSG":
            MessageLine(
                timestamp: timestamp(for: message),
                nick: message.nick ?? "guest",
                text: message.params.last ?? ""
            )
        case "JOIN":
            MessageLine(
                timestamp: timestamp(for: message),
                symbol: "hand.wave.fill",
                text: "\(message.nick ?? "Unknown user") joined"
            )
        case "PART":
            MessageLine(
                timestamp: timestamp(for: message),
                symbol: "door.left.hand.closed",
                text: "\(message.nick ?? "Unknown") left" // TODO: Add reason
            )
        case "KICK":
            MessageLine(
                timestamp: timestamp(for: message),
                symbol: "figure.kickboxing",
                text: "\(message.nick ?? "Unknown") was kicked" // TODO: Add reason
            )
        case "TOPIC":
            MessageLine(
                timestamp: timestamp(for: message),
                symbol: "megaphone.fill",
                text: "Topic changed '\(message.params.last ?? "")'"
            )
        default:
            Text("nil")
        }
    }

    func timestamp(for message: Message) -> Date {
        if let timeTag = message.tags["time"] {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: timeTag) {
                return date
            }
        }
        // Fall back to current time if no server-time tag
        return Date()
    }
}

struct MessageLine: View {
    @Environment(ServerState.self) var serverState

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
                            .foregroundStyle(.tertiary)
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
    }
}
