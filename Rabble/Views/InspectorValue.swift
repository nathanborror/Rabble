import SwiftUI

struct InspectorValue: View {
    @Environment(\.openURL) var openURL

    let key: String
    let value: String?
    let url: URL?

    init(_ key: String, value: String? = nil, url: URL? = nil) {
        self.key = key
        self.value = value
        self.url = url
    }

    var body: some View {
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
