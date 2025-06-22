import SwiftUI
import RabbleKit

struct ConnectionSidebar: View {
    @Environment(AppState.self) var state

    @State private var showingNewConnectionForm = false
    
    var body: some View {
        @Bindable var state = state
        VStack {
            List(selection: $state.selection) {
                ForEach(Array(state.connectionPool.values), id: \.file.id) { manager in
                    ConnectionRow(manager: manager)
                        .tag(AppState.Selection(fileID: manager.file.id, channelID: nil))
                }
            }
            Spacer()
            HStack {
                Button {
                    showingNewConnectionForm = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingNewConnectionForm) {
            NavigationStack {
                ConnectionForm()
            }
        }
    }
}

struct ConnectionRow: View {
    @Environment(AppState.self) var state

    let manager: ConnectionManager

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

            Text(manager.hostname)
                .fontWeight(.semibold)
        }

        if isExpanded {
            ForEach(Array(manager.channels.values).sorted(by: { $0.name < $1.name })) { channel in
                HStack(spacing: 0) {
                    Image(systemName: "number")
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.secondary)

                    Text(channel.cleanName)
                }
                .padding(.leading, 16+4)
                .tag(AppState.Selection(fileID: manager.file.id, channelID: channel.id))
            }
        }
    }
}
