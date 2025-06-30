import SwiftUI
import IRC
import RabbleKit

struct ChannelView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var viewModel: ChannelViewModel
    @State private var scrollPosition = ScrollPosition()

    init(channelID: String, session: IRCSession) {
        self.viewModel = .init(channelID: channelID, session: session)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.messages) { message in
                        MessageView(message: message)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .scrollTargetLayout()
                    }
                }
            }
            .scrollPosition($scrollPosition, anchor: .bottom)
            .defaultScrollAnchor(.bottom)

            if let topic = viewModel.channel?.topic {
                StickyView(kind: .informative, title: "Topic", expanded: true) {
                    Text(topic.message)
                }
                .padding()
            }
        }
        .environment(viewModel)
        .navigationTitle(viewModel.title)
        #if os(macOS)
        .navigationSubtitle(viewModel.subtitle)
        #endif
        .safeAreaInset(edge: .bottom) {
            ChannelMessageField()
                .environment(viewModel)
        }
        .toolbar {
            ToolbarItem {
                Button("Inspector", systemImage: "sidebar.right") {
                    viewModel.showingInspector.toggle()
                }
            }
        }
        .inspector(isPresented: $viewModel.showingInspector) {
            NavigationStack {
                ChannelDetails(session: viewModel.session)
            }
            .environment(viewModel)
            .inspectorColumnWidth(ideal: 200)
        }
        .onChange(of: viewModel.messages.count) { _, _ in
            scrollPosition.scrollTo(edge: .bottom)
        }
    }
}
