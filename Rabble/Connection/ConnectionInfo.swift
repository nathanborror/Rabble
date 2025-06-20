import SwiftUI
import RabbleKit

struct ConnectionInfo: View {
    @Environment(AppState.self) var state
    @Environment(\.openURL) var openURL

    let manager: ConnectionManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let session = manager.session {
                    info("Server", value: session.server)
                    info("Nick", value: session.nick)
                    info("Name", value: session.name)
                    info("Capabilities", value: Array(session.capabilities.keys).joined(separator: ", "))
                }
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
