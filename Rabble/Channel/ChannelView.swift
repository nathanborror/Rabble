import SwiftUI
import RabbleKit

struct ChannelView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var manager: ConnectionManager
    @State private var messageText = ""
    @State private var showingInspector = false

    init(manager: ConnectionManager) {
        self.manager = manager
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                if let channelID = state.selection?.channelID, let channel = manager.channels[channelID] {
                    ForEach(channel.messages) { message in
                        message.render
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                HStack(alignment: .bottom) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .onSubmit {
                            handleSubmit()
                        }

                    Button {
                        handleSubmit()
                    } label: {
                        Image(systemName: "arrow.up")
                            .padding(8)
                            .background(.blue, in: .circle)
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.background)
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
    }

    func handleSubmit() {
        guard let channelID = state.selection?.channelID else { return }
        guard let channel = manager.channels[channelID] else { return }

        manager.send("PRIVMSG \(channel.name) :\(messageText)")
        messageText = ""
    }
}
