import SwiftUI
import RabbleKit

struct ChannelView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    let session: IRCSession

    @State private var messageText = ""
    @State private var showingInspector = false
    @State private var scrollPosition = ScrollPosition()

    var channel: IRCChannel? {
        guard let channelID = state.selection?.channelID else { return nil }
        return try? session.channel(channelID)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 4) {
                    if let channel {
                        ForEach(channel.messages) { message in
                            MessageView(message: message)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .scrollTargetLayout()
                        }
                    }
                }
                .padding()
            }
            .scrollPosition($scrollPosition, anchor: .bottom)

            if let topic = channel?.topic {
                StickyView(title: "Topic", text: topic.message, expanded: true)
                    .padding()
            }
        }
        .navigationTitle(channel?.cleanName ?? "Unknown Channel")
        #if os(macOS)
        .navigationSubtitle("\(channel?.users.count ?? 0) users")
        #endif
        .safeAreaInset(edge: .bottom) {
            MessageField(session: session, text: $messageText) {
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
                ChannelMembers(session: session)
            }
            .inspectorColumnWidth(ideal: 200)
        }
        .onChange(of: session.server.config.logs.count) { _, _ in
            scrollPosition.scrollTo(edge: .bottom)
        }
        .onAppear {
            scrollPosition.scrollTo(edge: .bottom)
        }
    }

    func handleSubmit() {
        guard let channelID = state.selection?.channelID else { return }
        guard let channel = try? session.channel(channelID) else { return }

        if messageText.hasPrefix("/topic") {
            let topic = messageText.trimmingPrefix("/topic ")
            session.send("TOPIC \(channel.name) :\(topic)")
        } else {
            session.send("PRIVMSG \(channel.name) :\(messageText)")
        }
        messageText = ""
    }
}
