import SwiftUI
import RabbleKit

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
