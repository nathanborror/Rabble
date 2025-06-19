import SwiftUI
import RabbleKit

struct ConnectionForm: View {
    @Environment(AppState.self) var state
    @Environment(\.dismiss) var dismiss

    @State var server = "irc.zeronode.net"
    @State var port: UInt16 = 6667
    @State var nick = "sketch22"
    @State var name = "Nathan Borror"

    var body: some View {
        Form {
            TextField("Server", text: $server)
            TextField("Port", value: $port, format: .number)
            TextField("Nickname", text: $nick)
            TextField("Name", text: $name)
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
                let fileID = try await state.create(server: server, port: port, nick: nick, name: name)
                state.selectedFileID = fileID
                dismiss()
            } catch {
                print(error)
            }
        }
    }
}
