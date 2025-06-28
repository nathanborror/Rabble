import SwiftUI
import IRC
import RabbleKit

struct MessageView: View {
    @Environment(ChannelViewModel.self) var channelViewModel

    let message: IRC.Message

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(message.timestamp.formatted(date: .omitted, time: .standard))
                .foregroundStyle(.tertiary)

            switch message.command {
            case let .privmsg(_, text):
                HStack(alignment: .firstTextBaseline) {
                    HStack {
                        Spacer(minLength: 0)
                        Text(message.nick ?? "unknown")
                    }
                    .fontWeight(.semibold)
                    .frame(width: 120)
                    Text(text)
                }
            case .join:
                Text("\(message.nick ?? "Unknown user") joined the channel")
            case .part:
                Text("\(message.nick ?? "Unknown user") left the channel")
            default:
                Text("nil")
            }

            Text(message.id)
        }
        .padding(.vertical, 4)
        .padding(.horizontal)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(.system(.subheadline, design: .monospaced))
        .background(backgroundColor)
    }

    var backgroundColor: Color {
        if message.nick == channelViewModel.config.nick {
            return .yellow.opacity(0.2)
        }
        return .clear
    }
}
