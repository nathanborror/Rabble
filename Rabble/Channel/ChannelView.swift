import SwiftUI
import RabbleKit

struct ChannelView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var manager: ConnectionManager
    @State private var messageText = ""
    @State private var showingInspector = false
    @State private var scrollPosition = ScrollPosition()

    init(manager: ConnectionManager) {
        self.manager = manager
    }

    var channel: IRC.Channel? {
        guard let channelID = state.selection?.channelID else { return nil }
        return manager.channels[channelID]
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                if let channel {
                    ForEach(channel.messages) { message in
                        message.render
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .scrollTargetLayout()
                    }
                }
            }
            .padding()
        }
        .scrollPosition($scrollPosition, anchor: .bottom)
        .navigationTitle(channel?.cleanName ?? "Unknown Channel")
        .navigationSubtitle("\(channel?.users.count ?? 0) users")
        .safeAreaInset(edge: .bottom) {
            MessageField(text: $messageText, manager: manager) {
                handleSubmit()
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Inspector", systemImage: "sidebar.right") {
                    showingInspector.toggle()
                }
            }
        }
        .inspector(isPresented: $showingInspector) {
            NavigationStack {
                ChannelMembers(manager: manager)
            }
            .inspectorColumnWidth(ideal: 200)
        }
        .onChange(of: manager.logs.count) { _, _ in
            scrollPosition.scrollTo(edge: .bottom)
        }
        .onAppear {
            scrollPosition.scrollTo(edge: .bottom)
        }
    }

    func handleSubmit() {
        guard let channelID = state.selection?.channelID else { return }
        guard let channel = manager.channels[channelID] else { return }

        manager.send("PRIVMSG \(channel.name) :\(messageText)")
        messageText = ""
    }
}
