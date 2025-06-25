import SwiftUI
import RabbleKit

struct MessageField: View {
    let session: IRCSession
    @Binding var text: String
    let submit: () -> Void

    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .bottom) {
                if session.isConnected {
                    TextField("Message", text: $text, axis: .vertical)
                        .onKeyPress { press in
                            switch press.key {
                            case .upArrow:
                                handleHistoryBackward()
                                return .handled
                            case .downArrow:
                                handleHistoryForward()
                                return .handled
                            default:
                                return .ignored
                            }
                        }
                        .textFieldStyle(.plain)
                        .padding()
                        .onSubmit {
                            handleSubmit()
                        }
                    Button {
                        handleSubmit()
                    } label: {
                        Image(systemName: "arrow.up")
                            .padding(8)
                            .background(.blue, in: .rect(cornerRadius: 5))
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(text.isEmpty)
                } else {
                    Spacer()
                    Button("Reconnect") {
                        Task { try await session.connect() }
                    }
                    #if os(macOS)
                    .buttonStyle(.link)
                    #endif
                    .padding()
                    Spacer()
                }
            }
        }
        .background(.background)
    }

    func handleSubmit() {
        history.append(text)
        historyIndex = nil

        submit()
    }

    func handleHistoryBackward() {
        guard !history.isEmpty else { return }
        if let index = historyIndex {
            historyIndex = (index > 0) ? index - 1 : historyIndex
        } else {
            historyIndex = history.count - 1
        }
        text = history[historyIndex!]
    }

    func handleHistoryForward() {
        guard let index = historyIndex else { return }
        if index < (history.count - 1) {
            historyIndex = index + 1
            text = history[historyIndex!]
        } else {
            historyIndex = nil
            text = ""
        }
    }
}
