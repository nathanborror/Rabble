import SwiftUI
import IRC
import RabbleKit

struct ServerForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    let config: IRC.Config?

    @State var server = "localhost"
    @State var port: UInt16 = 6667
    @State var nick = "nathan"
    @State var ident = ""
    @State var username = "nathan"
    @State var email = ""
    @State var password = ""
    @State var realname = "Nathan Borror"
    @State var useTLS = false

    init(config: IRC.Config? = nil) {
        self.config = config
    }

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
                TextField("Ident", text: $ident)
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
        .task(id: config) {
            handleLoad()
        }
    }

    func handleLoad() {
        guard let config else { return }

        self.server = config.server
        self.port = config.port
        self.nick = config.nick
        self.ident = config.ident ?? ident
        self.username = config.username
        self.email = config.email ?? email
        self.password = config.password ?? password
        self.realname = config.realname ?? realname
        self.useTLS = config.useTLS
    }

    func handleSubmit() {
        Task {
            do {
                try await state.sessionCreate(
                    kind: .network,
                    server: server,
                    port: port,
                    useTLS: useTLS,
                    nick: nick,
                    ident: ident.isEmpty ? nil : ident,
                    username: username,
                    email: email.isEmpty ? nil : email,
                    password: password.isEmpty ? nil : password,
                    realname: realname
                )
                dismiss()
            } catch {
                print(error)
            }
        }
    }
}
