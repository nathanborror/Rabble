import SwiftUI
import RabbleKit

struct ChannelMembers: View {
    @Environment(AppState.self) var state
    
    let manager: ConnectionManager

    var body: some View {
        ScrollView {
            LazyVStack {
                if let channel = manager.channels[manager.selectedChannel] {
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
