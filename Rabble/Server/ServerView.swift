import SwiftUI
import IRC
import RabbleKit

struct ServerView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var viewModel: ServerViewModel
    @State private var scrollPosition = ScrollPosition()

    init(session: IRCSession) {
        self.viewModel = .init(session: session)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    ForEach(viewModel.logs.indices, id: \.self) { index in
                        if index < viewModel.logs.count {
                            Text(viewModel.logs[index])
                                .font(.footnote)
                                .fontDesign(.monospaced)
                                .textSelection(.enabled)
                                .scrollTargetLayout()
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .scrollPosition($scrollPosition, anchor: .bottom)
            .defaultScrollAnchor(.bottom)
            .background(.background)

            VStack(alignment: .leading) {
                if let error = viewModel.session.error {
                    StickyView(kind: .error, title: "Error", expanded: true) {
                        Text("\(error)")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("\(viewModel.config.nick)@\(viewModel.config.server)")
        #if os(macOS)
        .navigationSubtitle("\(viewModel.list.count) channels")
        #endif
        .safeAreaInset(edge: .bottom) {
            ServerMessageField()
                .environment(viewModel)
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
        .onChange(of: viewModel.logs.count) { _, _ in
            scrollPosition.scrollTo(edge: .bottom)
        }
    }

    func handleConnect() {
        Task {
            do {
                try await viewModel.session.connect()
            } catch {
                print(error)
            }
        }
    }

    func handleChannelList() {
        Task {
            do {
                try await viewModel.session.send("LIST")
                openWindow(id: "channels", value: viewModel.session.server.id)
            } catch {
                print(error)
            }
        }
    }

    func handleChannelInfo() {
        openWindow(id: "server", value: viewModel.session.server.id)
    }
}
