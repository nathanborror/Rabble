import SwiftUI
import RabbleKit

struct ChannelList: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State private var manager: ConnectionManager
    @State private var selected: Set<String> = []
    @State private var sortOrder = [KeyPathComparator(\IRC.Session.Channel.name)]

    init(manager: ConnectionManager) {
        self.manager = manager
    }

    var body: some View {
        Table(manager.list, selection: $selected, sortOrder: $sortOrder) {
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
//        .onChange(of: sortOrder) { _, newSortOrder in
//            channels.sort(using: newSortOrder)
//        }
        .toolbar {
            ToolbarItem {
                Button("List", systemImage: "arrow.clockwise") {
                    handleList()
                }
            }
        }
    }

    func handleList() {
        manager.send("LIST")
    }

    func handleJoin(_ names: Set<String>) {
        for name in names {
            manager.send("JOIN \(name)")
        }
    }
}
