import SwiftUI

struct ServerMessageField: View {
    @Environment(AppState.self) var state
    @Environment(ServerState.self) var serverState

    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil

    var body: some View {
        @Bindable var serverState = serverState
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .bottom) {
                if serverState.state == .connected {
                    TextField("Message", text: $serverState.draft, axis: .vertical)
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
                    .disabled(serverState.draft.isEmpty)
                } else {
                    Spacer()
                    Button("Reconnect") {
                        serverState.connect()
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
        history.append(serverState.draft)
        historyIndex = nil
        serverState.submit()
    }

    func handleHistoryBackward() {
        guard !history.isEmpty else { return }
        if let index = historyIndex {
            historyIndex = (index > 0) ? index - 1 : historyIndex
        } else {
            historyIndex = history.count - 1
        }
        serverState.draft = history[historyIndex!]
    }

    func handleHistoryForward() {
        guard let index = historyIndex else { return }
        if index < (history.count - 1) {
            historyIndex = index + 1
            serverState.draft = history[historyIndex!]
        } else {
            historyIndex = nil
            serverState.draft = ""
        }
    }
}
