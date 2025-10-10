import SwiftUI
import IRC

struct ServerForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State var server = "localhost"
    @State var port: Int = 6697
    @State var nick = "nathan"
    @State var username = "nathan"
    @State var email = ""
    @State var password = ""
    @State var realname = "Nathan Borror"
    @State var useTLS = true

    var body: some View {
        Form {
            Section {
                TextField("Server", text: $server)
                    .textContentType(.URL)
                TextField("Port", value: $port, format: .number.grouping(.never))
                Toggle("Use TLS", isOn: $useTLS)
            }
            Section {
                TextField("Nick", text: $nick)
                    .textContentType(.username)
                TextField("Username", text: $username)
                    .textContentType(.username)
                TextField("Email", text: $email)
                    .textContentType(.emailAddress)
                SecureField("Password", text: $password)
                    .textContentType(.password)
                TextField("Real Name", text: $realname)
                    .textContentType(.name)
            }
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
        state.serverCreate(server, port: port, useTLS: useTLS, nick: nick, username: username, realname: realname)
        dismiss()
    }
}
