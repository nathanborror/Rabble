import SwiftUI
import RabbleKit

struct MessageField: View {
    @Binding var text: String

    let manager: ConnectionManager
    let submit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
            HStack(alignment: .bottom) {
                if manager.connected {
                    TextField("Message", text: $text, axis: .vertical)
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
                            .background(.blue, in: .circle)
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .disabled(text.isEmpty)
                } else {
                    Spacer()
                    Button("Reconnect") {
                        Task { try await manager.connect() }
                    }
                    .buttonStyle(.link)
                    .padding()
                    Spacer()
                }
            }
        }
        .background(.background)
    }

    func handleSubmit() {
        submit()
    }
}
