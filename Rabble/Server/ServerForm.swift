import SwiftUI
import RabbleKit

struct ServerForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State var kind = IRCConfig.Kind.network
    @State var server = "localhost"
    @State var port: UInt16 = 6667
    @State var nick = "nathan"
    @State var ident = "nathan"
    @State var username = "nathan"
    @State var email = "nathan@nathan.run"
    @State var password = "abc"
    @State var realname = "Nathan Borror"

    @State var service = "openai"
    @State var model = "gpt-4o"

    var body: some View {
        Form {
            Section {
                Picker("Kind", selection: $kind) {
                    Text("Network").tag(IRCConfig.Kind.network)
                    Text("Simulation").tag(IRCConfig.Kind.simulation)
                }
                .pickerStyle(.inline)
            }
            switch kind {
            case .network:
                Section {
                    TextField("Server", text: $server)
                        .textContentType(.URL)
                    TextField("Port", value: $port, format: .number.grouping(.never))
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
            case .simulation:
                Section {
                    Picker("Service", selection: $service) {
                        Text("OpenAI").tag("openai")
                    }
                    Picker("Model", selection: $model) {
                        Text("gpt-4o").tag("gpt-4o")
                        Text("gpt-4o-mini").tag("gpt-4o-mini")
                    }
                }
                Section {
                    TextField("Nick", text: $nick)
                        .textContentType(.username)
                    TextField("Name", text: $realname)
                        .textContentType(.name)
                }
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
        Task {
            do {
                if kind == .simulation {
                    server = "\(model)@\(service)"
                }
                try await state.createServer(
                    kind: kind,
                    server: server,
                    port: port,
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
