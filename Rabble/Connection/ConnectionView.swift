import SwiftUI
import RabbleKit

struct ConnectionView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var manager: ConnectionManager
    @State private var messageText = ""
    @State private var scrollPosition = ScrollPosition()

    init(manager: ConnectionManager) {
        self.manager = manager
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(manager.logs) { log in
                    Text(log.text)
                        .font(.footnote)
                        .fontDesign(.monospaced)
                        .textSelection(.enabled)
                        .scrollTargetLayout()
                }
            }
            .padding()
        }
        .scrollPosition($scrollPosition, anchor: .bottom)
        .navigationTitle(manager.hostname)
        .navigationSubtitle("\(manager.list.count) channels")
        .background(.background)
        .safeAreaInset(edge: .bottom) {
            MessageField(text: $messageText, manager: manager) {
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
        .onChange(of: manager.logs.count) { _, _ in
            scrollPosition.scrollTo(edge: .bottom)
        }
        .onAppear {
            scrollPosition.scrollTo(edge: .bottom)
        }
    }

    func handleSubmit() {
        manager.send(messageText)
        messageText = ""
    }

    func handleConnect() {
        Task {
            do {
                try await manager.connect()
            } catch {
                print(error)
            }
        }
    }

    func handleChannelList() {
        manager.send("LIST")
        openWindow(id: "channels", value: manager.file.id)
    }

    func handleChannelInfo() {
        openWindow(id: "connection", value: manager.file.id)
    }

    func handleClearLogs() {
        manager.clear()
    }

//    static let formatter: DateFormatter = {
//        let out = DateFormatter()
//        out.dateFormat = "yyyy-MM-dd hh:mma"
//        out.locale = Locale(identifier: "en_US_POSIX")
//        return out
//    }()
}

