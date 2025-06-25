import SwiftUI
import RabbleKit

struct ServerList: View {
    @Environment(AppState.self) var state

    var body: some View {
        @Bindable var state = state
        VStack {
            List(selection: $state.selection) {
                ForEach(Array(state.sessionPool.values), id: \.fileID) { session in
                    ServerRow(session: session)
                        .tag(AppState.Selection(fileID: session.fileID, channelID: nil))
                }
            }
            .contextMenu(forSelectionType: AppState.Selection.self) { selections in
                if let selection = selections.first, let session = state.sessionPool[selection.fileID], let channelID = selection.channelID {
                    Button("Get Info") {
                        session.sendChannelInfo(channelID)
                    }
                    Divider()
                    Button("Leave") {
                        session.sendChannelPart(channelID)
                    }
                }
            }
            Spacer()
            HStack {
                Button {
                    state.showingServerForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding()
        }
    }
}

struct ServerRow: View {
    @Environment(AppState.self) var state

    let session: IRCSession

    @State var isExpanded = true

    var body: some View {
        HStack(spacing: 4) {
            Button {
                isExpanded.toggle()
            } label: {
                Image(systemName: isExpanded ? "chevron.down" :"chevron.right")
                    .frame(width: 16, height: 16)
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)

            Text("\(session.server.config.nick)@\(session.server.config.server)")
                .fontWeight(.semibold)

            Spacer()

            if !session.isConnected {
                Button {
                    Task { try await session.connect() }
                } label: {
                    Image(systemName: "bolt.horizontal.fill")
                        .imageScale(.small)
                }
                .foregroundStyle(.tertiary)
                .buttonStyle(.borderless)
            }
        }

        if isExpanded {
            ForEach(session.server.channels.sorted(by: { $0.name < $1.name })) { channel in
                HStack(spacing: 0) {
                    Image(systemName: "number")
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.secondary)

                    Text(channel.cleanName)
                        .fontDesign(.monospaced)
                }
                .padding(.leading, 16)
                .tag(AppState.Selection(fileID: session.fileID, channelID: channel.id))
            }
        }
    }
}
