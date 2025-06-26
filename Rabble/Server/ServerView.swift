import SwiftUI
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
                VStack(alignment: .leading) {
                    ForEach(viewModel.logs) { message in
                        Text(message.raw)
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
            .background(.background)

            VStack(alignment: .leading) {
                if let motd = viewModel.config.motd {
                    StickyView(title: "MOTD", text: motd, kind: .informative, expanded: false)
                }
                if let error = viewModel.session.error {
                    StickyView(title: "Error", text: "\(error)", kind: .error, expanded: true)
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
                Button("Clear Logs", systemImage: "eraser") {
                    handleClearLogs()
                }
            }
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
        .onAppear {
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
        viewModel.session.send("LIST")
        openWindow(id: "channels", value: viewModel.session.fileID)
    }

    func handleChannelInfo() {
        openWindow(id: "server", value: viewModel.session.fileID)
    }

    func handleClearLogs() {
        viewModel.session.clearLogs()
    }
}

