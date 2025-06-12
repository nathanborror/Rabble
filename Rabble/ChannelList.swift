import SwiftUI

struct ChannelList: View {
    @Environment(ChatManager.self) var manager

    @Binding var isPresented: Bool

    @State var channels: [ChatChannel] = []
    @State var selection: String? = nil
    @State var sort: KeyPathComparator<ChatChannel>? = nil
    @State var sortOrder = [
        KeyPathComparator(\ChatChannel.name),
        KeyPathComparator(\ChatChannel.count),
    ]

    var body: some View {
        Group {
            #if os(macOS)
            Table(channels, selection: $selection, sortOrder: $sortOrder) {
                TableColumn("Name", value: \.name)
                    .width(min: 100, ideal: 100)
                TableColumn("Topic", value: \.topic)
                TableColumn("Users", value: \.count) { channel in
                    Text(channel.count, format: .number)
                }
                .width(60)
            }
            .navigationTitle("Channels")
            .navigationSubtitle("\(channels.count) channels")
            #else
            List {
                ForEach(channels) { channel in
                    VStack(alignment: .leading) {
                        Text(channel.name)
                        Text(channel.topic)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Channels")
            #endif
        }
        .toolbar {
            ToolbarItem {
                Button("Done") {
                    isPresented = false
                }
            }
            ToolbarItem {
                Button {
                    manager.listChannels()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(manager.isListingChannels)
            }
        }
        .onChange(of: sortOrder) { _, _ in
            sortChannels()
        }
        .onChange(of: manager.channels) { _, _ in
            sortChannels()
        }
        .onAppear {
            manager.listChannels()
        }
    }

    func sortChannels() {
        Task.detached {
            let channels = await manager.channels
            let sorted = await channels.sorted(using: sortOrder)
            await MainActor.run {
                self.channels = sorted
            }
        }
    }

    func handleJoin(_ channelIDs: Set<String>) {
        for channelID in channelIDs {
            manager.join(channelID)
        }
    }
}
