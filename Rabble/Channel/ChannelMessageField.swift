import SwiftUI

struct ChannelMessageField: View {
    @Environment(AppState.self) var state
    @Environment(ServerState.self) var serverState
    @Environment(ChannelState.self) var channelState

    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil

    var body: some View {
        @Bindable var channelState = channelState
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .bottom) {
                if serverState.state == .connected {
                    TextField("Say something...", text: $channelState.draft, axis: .vertical)
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
                    .disabled(channelState.draft.isEmpty)
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
        history.append(channelState.draft)
        historyIndex = nil

        let input = channelState.draft
        channelState.draft = ""
        
        if let command = SlashCommand.parse(input) {
            serverState.executeSlashCommand(command, currentChannel: channelState.name)
        } else {
            serverState.privmsg(target: channelState.name, text: input)
        }
    }

    func handleHistoryBackward() {
        guard !history.isEmpty else { return }
        if let index = historyIndex {
            historyIndex = (index > 0) ? index - 1 : historyIndex
        } else {
            historyIndex = history.count - 1
        }
        channelState.draft = history[historyIndex!]
    }

    func handleHistoryForward() {
        guard let index = historyIndex else { return }
        if index < (history.count - 1) {
            historyIndex = index + 1
            channelState.draft = history[historyIndex!]
        } else {
            historyIndex = nil
            channelState.draft = ""
        }
    }
}
