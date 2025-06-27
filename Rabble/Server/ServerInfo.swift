import SwiftUI
import RabbleKit

struct ServerInfo: View {
    @Environment(AppState.self) var state
    @Environment(\.openURL) var openURL

    let session: IRCSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                info("Server", value: "\(session.server.config.server):\(session.server.config.port)")
                info("Nick", value: session.server.config.nick)
                info("Ident", value: session.server.config.ident)
                info("Username", value: session.server.config.username)
                info("Host", value: session.server.config.host)
                info("Real Name", value: session.server.config.realname)
                info("Email", value: session.server.config.email)
                info("Capabilities", value: Array(session.server.config.capabilities.keys).joined(separator: ", "))
                info("Available User Modes", value: session.server.config.availableUserModes)
                info("Available Channel Modes", value: session.server.config.availableChannelModes)
                info("Support", value: session.server.config.support.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
            }
            .padding()
        }
    }

    func info(_ key: String, value: String? = nil, url: URL? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 2) {
                Text(key)
                    .fontWeight(.medium)
                if let value = value ?? url?.absoluteString {
                    Button {
                        copy(value)
                    } label: {
                        Image(systemName: "square.on.square")
                            .imageScale(.small)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
            Group {
                if let value, !value.isEmpty {
                    Text(value)
                } else if let url {
                    HStack(alignment: .firstTextBaseline) {
                        Text(url.absoluteString)
                        Spacer()
                        Button {
                            openURL(url)
                        } label: {
                            Text("Open")
                        }
                    }
                } else {
                    Text("<none>")
                }
            }
            .foregroundStyle(.secondary)
        }
    }

    func copy(_ contents: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(contents, forType: .string)
        #else
        let pasteboard = UIPasteboard.general
        pasteboard.string = contents
        #endif
    }
}
