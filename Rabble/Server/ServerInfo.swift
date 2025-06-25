import SwiftUI
import RabbleKit

struct ServerInfo: View {
    @Environment(AppState.self) var state
    @Environment(ServerViewModel.self) var viewModel
    @Environment(\.openURL) var openURL

    let session: IRCSession

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                info("Server", value: session.server.config.server)
                info("Nick", value: session.server.config.nick)
                info("Name", value: session.server.config.name)
                info("Capabilities", value: Array(session.server.config.capabilities.keys).joined(separator: ", "))
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
