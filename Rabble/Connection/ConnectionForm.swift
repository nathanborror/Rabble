import SwiftUI
import RabbleKit

struct ConnectionForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State var server = "localhost"
    @State var port: UInt16 = 6667
    @State var nick = "sketch22"
    @State var username = "nathanborror"
    @State var password = ""
    @State var name = "Nathan Borror"

    var body: some View {
        Form {
            TextField("Server", text: $server)
                .textContentType(.URL)
            TextField("Port", value: $port, format: .number)
            TextField("Nick", text: $nick)
                .textContentType(.username)
            TextField("Username", text: $username)
                .textContentType(.username)
            TextField("Password", text: $password)
                .textContentType(.password)
            TextField("Name", text: $name)
                .textContentType(.name)
        }
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
                try await state.createConnection(server: server, port: port, nick: nick, username: username, password: password, name: name)
                dismiss()
            } catch {
                print(error)
            }
        }
    }
}
