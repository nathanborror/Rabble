import SwiftUI

struct MessageField: View {

    @Binding var text: String
    let action: () -> Void

    @State private var history: [String] = []
    @State private var historyIndex: Int? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .bottom) {
                TextField("Message", text: $text, axis: .vertical)
                    .font(.system(.subheadline, design: .monospaced))
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
                    .padding(.bottom, 6)
                    .onSubmit {
                        handleSubmit()
                    }

                Button {
                    handleSubmit()
                } label: {
                    Image(systemName: "arrow.up")
                        .padding(8)
                        .background(.blue, in: .circle)
                        .foregroundStyle(.white)
                        .padding(12)
                }
                .buttonStyle(.plain)
                .disabled(text.isEmpty)
            }
        }
        .background(.background)
    }

    func handleSubmit() {
        history.append(text)
        historyIndex = nil
        action()
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
