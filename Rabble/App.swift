import SwiftUI
import RabbleKit

@main
struct RabbleApp: App {
    @State private var state = AppState.shared
    @State private var showingNewConnectionForm = false
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                VStack {
                    List(selection: $state.selection) {
                        ForEach(Array(state.connectionPool.values), id: \.file.id) { connection in
                            DisclosureGroup {
                                ForEach(Array(connection.channels.values).sorted(by: { $0.name < $1.name })) { channel in
                                    Label(channel.cleanName, systemImage: "number")
                                        .tag(AppState.Selection(fileID: connection.file.id, channelID: channel.id))
                                }
                            } label: {
                                Text(connection.hostname)
                                    .fontWeight(.semibold)
                            }
                            .tag(AppState.Selection(fileID: connection.file.id, channelID: nil))
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
                .frame(minWidth: 200)
            } detail: {
                if let fileID = state.selection?.fileID, let manager = state.connectionPool[fileID] {
                    if state.selection?.channelID != nil {
                        ChannelView(manager: manager)
                    } else {
                        ConnectionView(manager: manager)
                    }
                } else {
                    ContentUnavailableView("No Connection", systemImage: "apple.terminal")
                }
            }
            .containerBackground(.background, for: .window)
            .sheet(isPresented: $showingNewConnectionForm) {
                NavigationStack {
                    ConnectionForm()
                }
            }
            .onAppear {
                Task { await appActive() }
            }
        }
        .environment(state)
        .commands {
            CommandMenu("Rabble") {
                Button("Reset All Data") {
                    state.resetAll()
                }
            }
        }

        WindowGroup("Channels", id: "channels", for: String.self) { fileID in
            NavigationStack {
                if let fileID = fileID.wrappedValue, let manager = state.connectionPool[fileID] {
                    ChannelList(manager: manager, channels: manager.list)
                } else {
                    ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
                }
            }
        }
        .environment(state)
        .defaultSize(width: 500, height: 600)

        WindowGroup("Connection Info", id: "connection", for: String.self) { fileID in
            if let fileID = fileID.wrappedValue, let manager = state.connectionPool[fileID] {
                ConnectionInfo(manager: manager)
            } else {
                ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
            }
        }
        .environment(state)
        .defaultSize(width: 350, height: 500)
    }

    func appActive() async {
        do {
            try await state.ready()
        } catch {
            state.log(error: error)
        }
    }

    func appReset() async {
        state.resetAll()
        await appActive()
    }
}
