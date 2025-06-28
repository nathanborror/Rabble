import SwiftUI
import IRC
import RabbleKit

struct MessageRow: View {
    let message: IRC.Message

    @State private var showingDetails = false

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            MessageView(message: message)
            Spacer()
            Button {
                showingDetails.toggle()
            } label: {
                Image(systemName: "info.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.tertiary)
            .popover(isPresented: $showingDetails) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading) {
                        Text("Command")
                        Text("\(message.command)")
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading) {
                        Text("Prefix")
                        Text("\(message.prefix)")
                            .foregroundStyle(.secondary)
                    }
                    VStack(alignment: .leading) {
                        Text("Params")
                        Text("\(message.params)")
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .fontDesign(.monospaced)
                .textSelection(.enabled)
            }
        }
        .fontDesign(.monospaced)
        .textSelection(.enabled)
    }
}
