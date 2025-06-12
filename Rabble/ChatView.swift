import SwiftUI
import RabbleKit

struct ChatView: View {
    @State private var client = Client()
    @State private var selected: UUID? = nil
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
                Button("List Channels", systemImage: "number") {
                    guard let selected else { return }
                    try? client.command("LIST", sessionID: selected)
                }
            }
            ToolbarItem {
                Menu {
                    Button("New Connection") {
                        showingNewConnectionForm = true
                    }
                    Divider()
                    ForEach(client.sessions) { session in
                        Button("\(session.nickname)@\(session.server)") {
                            client.connect(session: session)
                        }
                    }
                } label: {
                    Label("Connect", systemImage: "plus")
                }
            }
            if let selected, let session = try? client.session(selected) {
                ToolbarItem {
                    if session.isConnected {
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
            do {
                try client.restore()
            } catch {
                print(error)
            }
        }
    }

    func handleSubmit() {
        do {
            guard let selected else { return }
            try client.send("\(messageText)\n", sessionID: selected)
            messageText = ""
        } catch {
            print(error)
        }
    }
}

struct ConnectionForm: View {
    @Environment(\.dismiss) var dismiss

    var connect: (Session) -> Void

    @State var session = Session(server: "irc.zeronode.net", nickname: "sketch22", name: "Nathan Borror")

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
