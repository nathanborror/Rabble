import SwiftUI
import RabbleKit

struct ChannelList: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    let session: IRCSession

    @State private var selected: Set<String> = []
    @State private var sortOrder = [KeyPathComparator(\IRCConfig.Channel.name)]

    var body: some View {
        Table(session.server.config.list, selection: $selected, sortOrder: $sortOrder) {
            TableColumn("Name", value: \.name)
            TableColumn("Users") { channel in
                Text("\(channel.users ?? 0)")
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
//            manager.list.sort(using: newSortOrder)
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
        session.send("LIST")
    }

    func handleJoin(_ names: Set<String>) {
        for name in names {
            session.sendChannelJoin(name)
            state.selection = .init(fileID: session.fileID, channelID: name)
        }
    }
}
