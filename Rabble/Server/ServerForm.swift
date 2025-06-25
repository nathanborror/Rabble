import SwiftUI
import RabbleKit

struct ServerForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State var kind = IRCConfig.Kind.network
    @State var server = "localhost"
    @State var port: UInt16 = 6667
    @State var nick = "sketch22"
    @State var username = "sketch22"
    @State var password = "buoyant"
    @State var name = "Nathan Borror"

    var body: some View {
        Form {
            Picker("Kind", selection: $kind) {
                Text("Network").tag(IRCConfig.Kind.network)
                Text("Simulation").tag(IRCConfig.Kind.simulation)
            }
            TextField("Server", text: $server)
                .textContentType(.URL)
            TextField("Port", value: $port, format: .number)
            TextField("Nick", text: $nick)
                .textContentType(.username)
            TextField("Username", text: $username)
                .textContentType(.username)
            SecureField("Password", text: $password)
                .textContentType(.password)
            TextField("Name", text: $name)
                .textContentType(.name)
        }
        .navigationTitle("Server Form")
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    handleSubmit()
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    func handleSubmit() {
        Task {
            do {
                try await state.createServer(kind, server: server, port: port, nick: nick, username: username, password: password, name: name)
                dismiss()
            } catch {
                print(error)
            }
        }
    }
}
