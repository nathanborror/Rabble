import SwiftUI
import RabbleKit

struct ChannelList: View {
    @Environment(\.dismiss) var dismiss

    let channels: [ChannelRef]

    var body: some View {
        List {
            ForEach(channels) { channel in
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading) {
                        Text(channel.name)
                        if let topic = channel.topic {
                            Text(topic)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("\(channel.users)")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
