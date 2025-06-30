import SwiftUI
import IRC
import RabbleKit

struct ChannelMembers: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    let session: IRCSession

    var body: some View {
        List {
            if let channelID = state.selection?.channelID, let channel = try? session.getChannel(channelID) {
                Section("Members") {
                    ForEach(Array(channel.users.values)) { user in
                        ChannelMember(name: user.nick, membership: user.membership?.rawValue)
                            .contextMenu {
                                Button("Show Info") {
                                    if var selection = state.selection {
                                        selection.userID = user.nick
                                        openWindow(id: "user", value: selection)
                                    }
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle("Members")
    }
}

struct ChannelMember: View {
    let name: String
    let membership: String?

    var body: some View {
        HStack(spacing: 0) {
            if let membership {
                Text(membership)
                    .foregroundStyle(.tertiary)
            }
            Text(name)
            Spacer()
        }
        .padding(.horizontal)
    }
}

#Preview {

    List {
        Section("Members") {
            ChannelMember(name: "nathan", membership: "operator")
            ChannelMember(name: "travis", membership: "voice")
            ChannelMember(name: "aaron", membership: nil)
        }
    }
}
