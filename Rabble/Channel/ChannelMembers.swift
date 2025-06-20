import SwiftUI
import RabbleKit

struct ChannelMembers: View {
    @Environment(AppState.self) var state

    let manager: ConnectionManager

    var body: some View {
        ScrollView {
            LazyVStack {
                if let channelID = state.selection?.channelID, let channel = manager.channels[channelID] {
                    ForEach(Array(channel.users.values)) { user in
                        HStack {
                            Text(user.nick)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Members")
    }
}
