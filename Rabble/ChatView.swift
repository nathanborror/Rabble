import SwiftUI
import RabbleKit

struct ChatView: View {
    @Environment(Client.self) var client
    
    @State private var selected: String? = nil
    @State private var messageText = ""
    @State private var showingNewConnectionForm = false
    @State private var showingChannels = false

    var body: some View {
        List {
            if let selected, let session = client.session(selected) {
                ForEach(session.messages) { message in
                    VStack(alignment: .leading) {
                        Text("prefix: \(message.prefix ?? "nil"), command: \(message.command), params: \(message.params), tags: \(message.tags ?? [:])")
                            .font(.subheadline)
                        Text(message.raw)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .fontDesign(.monospaced)
                    .textSelection(.enabled)
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        handleSubmit()
                    }

                Button {
                    handleSubmit()
                } label: {
                    Image(systemName: "arrow.up")
                }
            }
            .padding()
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
        .sheet(isPresented: $showingChannels) {
            NavigationStack {
                if let selected, let session = client.session(selected) {
                    ChannelList(channels: Array(session.channels))
                } else {
                    ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
                }
            }
            .frame(width: 600, height: 700)
        }
        .toolbar {
            ToolbarItem {
                Menu {
                    Button("New Connection") {
                        showingNewConnectionForm = true
                    }
                    Divider()
                    ForEach(client.sessions) { session in
                        Button("\(session.nickname)@\(session.server)") {
                            selected = session.id
                        }
                    }
                } label: {
                    Label("Connect", systemImage: "plus")
                }
                .menuIndicator(.hidden)
            }
            if let selected, let session = client.session(selected) {
                ToolbarItem {
                    Button("List Channels", systemImage: "number") {
                        client.send("LIST", sessionID: session.id)
                    }
                }
                ToolbarItem {
                    Button("List", systemImage: "list.bullet.rectangle") {
                        showingChannels = true
                    }
                }
                ToolbarItem {
                    if session.connected {
                        Button("Disconnect", systemImage: "network.slash") {
                            client.disconnect(sessionID: session.id)
                        }
                    } else {
                        Button("Connect", systemImage: "network") {
                            client.connect(session)
                        }
                    }
                }
            }
        }
        .onAppear {
            client.restore()
        }
    }

    func handleSubmit() {
        guard let selected else { return }
        client.send(messageText, sessionID: selected)
        messageText = ""
    }
}
