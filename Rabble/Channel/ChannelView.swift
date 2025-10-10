import SwiftUI
import IRC

struct ChannelView: View {
    @Environment(AppState.self) var state
    @Environment(ServerState.self) var serverState
    @Environment(ChannelState.self) var channelState
    @Environment(\.openWindow) var openWindow

    @State private var scrollPosition = ScrollPosition()

    var messages: [Message] {
        serverState.events
            .compactMap {
                guard case .message(let message) = $0 else { return nil }
                return message
            }
            .filter {
                $0.params.first == channelState.name
            }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(messages.indices, id: \.self) { index in
                    MessageView(message: messages[index])
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .scrollTargetLayout()
                }
            }
        }
        .scrollPosition($scrollPosition, anchor: .bottom)
        .defaultScrollAnchor(.bottom)
        .navigationTitle(channelState.name)
        #if os(macOS)
        .navigationSubtitle(channelState.topic ?? "No topic")
        #endif
        .safeAreaInset(edge: .bottom) {
            ChannelMessageField()
        }
        .toolbar {
            ToolbarItem {
                Button("Inspector", systemImage: "sidebar.right") {
                    channelState.showingInspector.toggle()
                }
            }
        }
//        .inspector(isPresented: $channelState.showingInspector) {
//            NavigationStack {
//                ChannelDetails(session: viewModel.session)
//            }
//            .inspectorColumnWidth(ideal: 200)
//        }
        .onChange(of: messages.count) { _, _ in
            scrollPosition.scrollTo(edge: .bottom)
        }
    }
}
