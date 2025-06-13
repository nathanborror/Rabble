import SwiftUI
import RabbleKit

struct ChatView: View {
    @Environment(Client.self) var client
    
    @State private var selected: String? = nil
    @State private var messageText = ""
    @State private var showingNewConnectionForm = false

    var body: some View {
        List {
            if let selected, let session = try? client.session(selected) {
                ForEach(session.messages) { message in
                    Text("prefix: \(message.prefix ?? "nil"), command: \(message.command), params: \(message.params), tags: \(message.tags ?? [:])")
                        .font(.subheadline)
                        .fontDesign(.monospaced)
                        .padding(.horizontal)
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
                    client.connect(session: session)
                    showingNewConnectionForm = false
                    selected = session.id
                }
            }
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
            if let selected, let session = try? client.session(selected) {
                ToolbarItem {
                    Button("List Channels", systemImage: "number") {
                        try? client.command("LIST", sessionID: session.id)
                    }
                }
                ToolbarItem {
                    if session.connected {
                        Button("Disconnect", systemImage: "network.slash") {
                            try? client.disconnect(sessionID: session.id)
                        }
                    } else {
                        Button("Connect", systemImage: "network") {
                            client.connect(session: session)
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
        do {
            try client.send("\(messageText)\n", sessionID: selected)
            messageText = ""
        } catch {
            try? client.upsert(message: .init(command: .error("\(error)")), sessionID: selected)
        }
    }
}

struct ConnectionForm: View {
    @Environment(\.dismiss) var dismiss

    var connect: (Session) -> Void

    @State var session = Session(server: "irc.libera.chat", nickname: "", name: "")

    var body: some View {
        Form {
            TextField("Server", text: $session.server)
            TextField("Port", value: $session.port, format: .number)
            TextField("Nickname", text: $session.nickname)
            TextField("Name", text: $session.name)
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    connect(session)
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }
}
