import SwiftUI
import RabbleKit

struct ServerView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var viewModel: ServerViewModel
    @State private var messageText = ""
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
                .padding()
            }
            .scrollPosition($scrollPosition, anchor: .bottom)
            .background(.background)

            if let motd = viewModel.config.motd {
                StickyView(title: "MOTD", text: motd, expanded: false)
                    .padding()
            }
        }
        .navigationTitle("\(viewModel.config.nick)@\(viewModel.config.server)")
        #if os(macOS)
        .navigationSubtitle("\(viewModel.list.count) channels")
        #endif
        .safeAreaInset(edge: .bottom) {
            MessageField(session: viewModel.session, text: $messageText) {
                handleSubmit()
            }
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

    func handleSubmit() {
        viewModel.session.send(messageText)
        messageText = ""
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

//    static let formatter: DateFormatter = {
//        let out = DateFormatter()
//        out.dateFormat = "yyyy-MM-dd hh:mma"
//        out.locale = Locale(identifier: "en_US_POSIX")
//        return out
//    }()
}

