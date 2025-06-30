import SwiftUI
import IRC
import RabbleKit

struct ServerInfo: View {
    @Environment(AppState.self) var state

    let session: IRCSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                InspectorValue("Server", value: "\(session.server.config.server):\(session.server.config.port)")
                InspectorValue("Nick", value: session.server.config.nick)
                InspectorValue("Ident", value: session.server.config.ident)
                InspectorValue("Username", value: session.server.config.username)
                InspectorValue("Host", value: session.server.config.host)
                InspectorValue("Real Name", value: session.server.config.realname)
                InspectorValue("Email", value: session.server.config.email)
                InspectorValue("Capabilities", value: Array(session.server.config.capabilities.keys).joined(separator: ", "))
                InspectorValue("Available User Modes", value: session.server.config.availableUserModes)
                InspectorValue("Available Channel Modes", value: session.server.config.availableChannelModes)
                InspectorValue("Support", value: session.server.config.support.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}
