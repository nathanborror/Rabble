import SwiftUI
import RabbleKit

struct ConsoleView: View {
    @Environment(Client.self) var client
    @Environment(\.openWindow) var openWindow

    @State private var selected: String? = nil
    @State private var messageText = ""
    @State private var showingNewConnectionForm = false
    @State private var showingChannels = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if let selected, let session = client.session(selected) {
                    ForEach(session.log) { log in
                        Text(log.text)
                            .font(.footnote)
                            .fontDesign(.monospaced)
                            .textSelection(.enabled)
                    }
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
        .sheet(isPresented: $showingNewConnectionForm) {
            NavigationStack {
                ConnectionForm { session in
                    client.connect(session)
                    showingNewConnectionForm = false
                    selected = session.id
                }
            }
        }
        .toolbar {
            if let selected {
                ToolbarItem {
                    Button("Channels", systemImage: "number") {
                        openWindow(id: "channels", value: selected)
                    }
                }
            }
            ToolbarItem {
                Menu {
                    Button("New Connection") {
                        showingNewConnectionForm = true
                    }
                    Divider()
                    Section("Past Sessions") {
                        ForEach(client.sessions) { session in
                            Button("\(session.nick)@\(session.server)") {
                                selected = session.id
                            }
                        }
                    }
                } label: {
                    Label("Connect", systemImage: "plus")
                }
                .menuIndicator(.hidden)
            }
        }
        .onAppear {
            client.restore()
        }
        .onDisappear {
            for session in client.sessions {
                client.disconnect(session.id)
            }
            client.save()
        }
    }

    func handleSubmit() {
        guard let selected else { return }
        client.send(messageText, sessionID: selected)
        messageText = ""
    }

//    static let formatter: DateFormatter = {
//        let out = DateFormatter()
//        out.dateFormat = "yyyy-MM-dd hh:mma"
//        out.locale = Locale(identifier: "en_US_POSIX")
//        return out
//    }()
}

