import SwiftUI
import RabbleKit

struct ChannelList: View {
    @Environment(Client.self) var client
    @Environment(\.dismiss) var dismiss

    @State var session: IRC.Session

    @State private var selected: Set<String> = []
    @State private var sortOrder = [KeyPathComparator(\IRC.ChannelRef.name)]

    var body: some View {
        Table(session.list, selection: $selected, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name)
            TableColumn("Users", value: \.users) { channel in
                Text("\(channel.users)")
            }
            .width(50)
            TableColumn("Topic") { channel in
                if let topic = channel.topic {
                    Text(topic)
                }
            }
        }
        .contextMenu(forSelectionType: String.self) { names in
            Button("Join") {
                handleJoin(names)
            }
        } primaryAction: { names in
            handleJoin(names)
        }
        .navigationTitle("Channels")
        .onChange(of: sortOrder) { _, newSortOrder in
            session.list.sort(using: newSortOrder)
        }
        .toolbar {
            ToolbarItem {
                Button("List", systemImage: "arrow.clockwise") {
                    client.send("LIST", sessionID: session.id)
                }
            }
        }
    }

    func handleJoin(_ names: Set<String>) {
        for name in names {
            client.send("JOIN \(name)", sessionID: session.id)
        }
    }
}
