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
                .frame(width: 80, alignment: .trailing)

            switch message.command {
            case let .PRIVMSG(_, text):
                HStack(alignment: .firstTextBaseline) {
                    HStack {
                        Spacer(minLength: 0)
                        Text(message.nick ?? "unknown")
                    }
                    .fontWeight(.semibold)
                    .frame(width: 120)
                    Text(text)
                }
            case .JOIN:
                HStack(alignment: .firstTextBaseline) {
                    HStack {
                        Spacer(minLength: 0)
                        Image(systemName: "hand.wave.fill")
                    }
                    .fontWeight(.semibold)
                    .frame(width: 120)
                    .foregroundStyle(.mint)
                    Text("\(message.nick ?? "Unknown user") joined")
                }
            case let .PART(_, reason):
                HStack(alignment: .firstTextBaseline) {
                    HStack {
                        Spacer(minLength: 0)
                        Image(systemName: "door.left.hand.closed")
                    }
                    .fontWeight(.semibold)
                    .frame(width: 120)
                    .foregroundStyle(.mint)
                    Text("\(message.nick ?? "Unknown user") left \(reason != nil ? "(\(reason!))" : "")")
                }
            case let .KICK(_, nick, comment):
                HStack(alignment: .firstTextBaseline) {
                    HStack {
                        Spacer(minLength: 0)
                        Image(systemName: "figure.kickboxing")
                    }
                    .fontWeight(.semibold)
                    .frame(width: 120)
                    .foregroundStyle(.mint)
                    Text("\(nick) was kicked \(comment != nil ? "(\(comment!))" : "")")
                }

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
        if message.nick == channelViewModel.config.nick {
            return .yellow.opacity(0.2)
        }
        return .clear
    }
}
