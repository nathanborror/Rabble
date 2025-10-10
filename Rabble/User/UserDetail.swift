import SwiftUI
import IRC

struct UserDetail: View {
    @Environment(AppState.self) var state

    let server: String
    let nick: String

    @State private var serverState: ServerState? = nil
    @State private var userState: UserState? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InspectorValue("Nick", value: userState?.nick)
                InspectorValue("Real Name", value: userState?.realname)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .task(id: "\(nick)@\(server)") {
            handleLoad()
        }
    }

    func handleLoad() {
        serverState = state.servers[server]
        userState = serverState?.users[nick]
    }
}
