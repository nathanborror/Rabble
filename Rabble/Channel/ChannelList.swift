import SwiftUI
import IRC
import RabbleKit

struct ChannelList: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    let session: IRCSession

    @State private var selected: Set<String> = []
    @State private var sortOrder = [KeyPathComparator(\IRC.Config.Channel.name)]

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
        Task {
            do {
                try await session.send("LIST")
            } catch {
                print(error)
            }
        }
    }

    func handleJoin(_ names: Set<String>) {
        Task {
            do {
                for name in names {
                    try await session.channelJoin(name)
                    state.selection = .init(fileID: session.server.id, channelID: name)
                }
            } catch {
                print(error)
            }
        }
    }
}
