import SwiftUI
import IRC

struct ChannelList: View {
    @Environment(AppState.self) var state
    @Environment(ServerState.self) var serverState
    @Environment(\.dismiss) var dismiss

    @State private var selected: String? = nil
    @State private var showingCreateForm = false
    @State private var createChannelName = ""

    var channels: [IRC.ListAggregation.Entry] {
        Array(serverState.channels.values)
    }

    var body: some View {
        List(selection: $selected) {
            ForEach(channels, id: \.channel) { channel in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading) {
                        Text(channel.channel)
                        Text(channel.topic)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(channel.userCount)")
                }
                .tag(channel.channel)
            }
        }
        .navigationTitle("Channels")
        .toolbar {
            ToolbarItemGroup {
                Button("List", systemImage: "arrow.clockwise") {
                    handleList()
                }
                Button("Create", systemImage: "plus") {
                    showingCreateForm = true
                }
            }
        }
        .sheet(isPresented: $showingCreateForm) {
            Form {
                TextField("Channel Name", text: $createChannelName)
                    .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        handleCreate(createChannelName)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showingCreateForm = false
                    }
                }
            }
        }
    }

    func handleList() {
        serverState.list()
    }

    func handleJoin() {
        guard let name = selected, !name.isEmpty else { return }
        serverState.join(name)
    }

    func handleCreate(_ name: String) {
        guard !name.isEmpty else { return }
        serverState.join(name)
        handleList()
        createChannelName = ""
        showingCreateForm = false
    }
}
