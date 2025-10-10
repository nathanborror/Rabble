import SwiftUI
import IRC

struct ServerList: View {
    @Environment(AppState.self) var state

    var body: some View {
        @Bindable var state = state
        VStack {
            List(selection: $state.selection) {
                ForEach(Array(state.servers.keys), id: \.self) { host in
                    if let serverState = state.servers[host] {
                        ServerRow()
                            .environment(serverState)
                            .tag(AppState.Selection(server: host))
                    }
                }
            }
//            .sheet(item: $showingConfig) { config in
//                ServerForm(config: config)
//            }
//            .contextMenu(forSelectionType: AppState.Selection.self) { selections in
//                if let selection = selections.first, let server = state.servers[selection.server] {
//                    if let channel = selection.channel {
//                        Button("Get Info") {
//                            print("not implemented")
//                        }
//                        Divider()
//                        Button("Leave") {
//                            print("not implemented")
//                        }
//                    } else {
//                        Button("Edit") {
//                            showingConfig = session.server.config
//                        }
//                        Divider()
//                        Button("Connect") {
//                            print("not implemented")
//                        }
//                        Button("Disconnect") {
//                            print("not implemented")
//                        }
//                        Divider()
//                        Button("Delete") {
//                            print("not implemented")
//                        }
//                    }
//                }
//            }
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
    @Environment(ServerState.self) var serverState

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

            Text("\(serverState.nick)@\(serverState.server)")
                .fontWeight(.semibold)

            Spacer()

            if serverState.state != .connected {
                Button {
                    serverState.connect()
                } label: {
                    Image(systemName: "bolt.horizontal.fill")
                        .imageScale(.small)
                }
                .foregroundStyle(.tertiary)
                .buttonStyle(.borderless)
            }
        }

        if isExpanded {
            ForEach(Array(serverState.joined.values), id: \.name) { channel in
                HStack(spacing: 0) {
                    Image(systemName: "number")
                        .frame(width: 16, height: 16)
                        .foregroundStyle(.secondary)

                    Text(channel.name.trimmingPrefix("#"))
                        .fontDesign(.monospaced)
                }
                .padding(.leading, 16)
                .tag(AppState.Selection(server: serverState.server, channel: channel.name))
            }
        }
    }
}
