import SwiftUI
import RabbleKit

struct ServerForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State var kind = IRCConfig.Kind.network
    @State var server = "localhost"
    @State var port: UInt16 = 6667
    @State var nick = "nathan"
    @State var username = "nathan"
    @State var password = ""
    @State var name = "Nathan Borror"

    @State var service = "openai"
    @State var model = "gpt4o"

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
                    TextField("Port", value: $port, format: .number)
                }
                Section {
                    TextField("Nick", text: $nick)
                        .textContentType(.username)
                    TextField("Username", text: $username)
                        .textContentType(.username)
                    SecureField("Password", text: $password)
                        .textContentType(.password)
                    TextField("Name", text: $name)
                        .textContentType(.name)
                }
            case .simulation:
                Section {
                    Picker("Service", selection: $service) {
                        Text("OpenAI").tag("openai")
                        Text("Anthropic").tag("anthropic")
                        Text("Mistral").tag("mistral")
                        Text("Meta").tag("meta")
                        Text("Ollama").tag("ollama")
                    }
                    Picker("Model", selection: $model) {
                        Text("gpt4o").tag("gpt4o")
                        Text("gpt4o-mini").tag("gpt4o-mini")
                    }
                }
                Section {
                    TextField("Nick", text: $nick)
                        .textContentType(.username)
                    TextField("Name", text: $name)
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
                try await state.createServer(kind, server: server, port: port, nick: nick, username: username, password: password, name: name)
                dismiss()
            } catch {
                print(error)
            }
        }
    }
}
