import SwiftUI
import RabbleKit

struct ChannelMessageField: View {
    @Environment(AppState.self) var state
    @Environment(ChannelViewModel.self) var viewModel

    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil

    var body: some View {
        @Bindable var viewModel = viewModel
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .bottom) {
                if viewModel.session.isConnected {
                    TextField("Say something...", text: $viewModel.draft, axis: .vertical)
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
                    .disabled(viewModel.draft.isEmpty)
                } else {
                    Spacer()
                    Button("Reconnect") {
                        Task { try await state.sessionConnect(session: viewModel.session) }
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
        history.append(viewModel.draft)
        historyIndex = nil

        viewModel.submit()
    }

    func handleHistoryBackward() {
        guard !history.isEmpty else { return }
        if let index = historyIndex {
            historyIndex = (index > 0) ? index - 1 : historyIndex
        } else {
            historyIndex = history.count - 1
        }
        viewModel.draft = history[historyIndex!]
    }

    func handleHistoryForward() {
        guard let index = historyIndex else { return }
        if index < (history.count - 1) {
            historyIndex = index + 1
            viewModel.draft = history[historyIndex!]
        } else {
            historyIndex = nil
            viewModel.draft = ""
        }
    }
}
