import SwiftUI
import IRC
import RabbleKit

struct ChannelMembers: View {
    @Environment(AppState.self) var state

    let session: IRCSession

    var body: some View {
        ScrollView {
            LazyVStack {
                if let channelID = state.selection?.channelID, let channel = try? session.getChannel(channelID) {
                    ForEach(Array(channel.users.values)) { user in
                        HStack {
                            Text(user.nick)
                            Spacer()

                            if let membership = user.membership {
                                Group {
                                    switch membership {
                                    case .owner:
                                        Text("owner")
                                    case .admin:
                                        Text("admin")
                                    case .op:
                                        Text("operator")
                                    case .half:
                                        Text("halfop")
                                    case .voice:
                                        Text("voice")
                                    }
                                }
                                .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Members")
    }
}
