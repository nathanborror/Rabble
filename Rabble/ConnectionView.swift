import SwiftUI
import RabbleKit

struct ConnectionView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var manager: ConnectionManager
    @State private var messageText = ""
    @State private var showingChannels = false

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
                }
            }
            .padding()
        }
        .background(.background)
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
                Button("Connect", systemImage: "cloud") {
                    handleConnect()
                }
            }
        }
        .onDisappear {
            print("note implemented: disconnect all connections")
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

//    static let formatter: DateFormatter = {
//        let out = DateFormatter()
//        out.dateFormat = "yyyy-MM-dd hh:mma"
//        out.locale = Locale(identifier: "en_US_POSIX")
//        return out
//    }()
}

