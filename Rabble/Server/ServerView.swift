import SwiftUI
import IRC

struct ServerView: View {
    @Environment(AppState.self) var state
    @Environment(ServerState.self) var serverState
    @Environment(\.openWindow) var openWindow

    @State private var scrollPosition = ScrollPosition()

    var messages: [IRC.Message] {
        serverState.events.compactMap {
            guard case .message(let message) = $0 else { return nil }
            return message
        }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(messages.indices, id: \.self) { index in
                        Text(messages[index].raw)
                            .font(.footnote)
                            .fontDesign(.monospaced)
                            .textSelection(.enabled)
                            .scrollTargetLayout()
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollPosition($scrollPosition, anchor: .bottom)
            .defaultScrollAnchor(.bottom)
        }
        .navigationTitle("\(serverState.nick)@\(serverState.server)")
        #if os(macOS)
        .navigationSubtitle("\(serverState.channels.count) channels")
        #endif
        .safeAreaInset(edge: .bottom) {
            ServerMessageField()
        }
        .toolbar {
            ToolbarItem {
                Button("Channels", systemImage: "list.dash.header.rectangle") {
                    handleChannelList()
                }
            }
            ToolbarItem {
                Button("Info", systemImage: "info.circle") {
                    handleChannelInfo()
                }
            }
        }
        .onChange(of: serverState.events.count) { _, _ in
            scrollPosition.scrollTo(edge: .bottom)
        }
    }

    func handleConnect() {
        serverState.connect()
    }

    func handleChannelList() {
        serverState.list()
        openWindow(id: "channels", value: serverState.server)
    }

    func handleChannelInfo() {
        openWindow(id: "server", value: serverState.server)
    }
}
