import SwiftUI
import RabbleKit

@main
struct RabbleApp: App {
    @State private var state = AppState.shared
    @State private var showingNewConnectionForm = false
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List(selection: $state.selectedFileID) {
                    ForEach(Array(state.connectionPool.values), id: \.file.id) { connection in
                        NavigationLink(value: connection.file.id) {
                            Label(connection.hostname, systemImage: "apple.terminal")
                        }
                    }
                }
            } content: {
                if let fileID = state.selectedFileID, let manager = state.connectionPool[fileID] {
                    @Bindable var manager = manager
                    List(selection: $manager.selectedChannel) {
                        NavigationLink(value: "__console__") {
                            Text("Console")
                        }
                        ForEach(Array(manager.channels.values)) { channel in
                            NavigationLink(value: channel.id) {
                                Text(channel.name)
                            }
                            .contextMenu {
                                Button("Leave") {
                                    manager.leave(channel.id)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("No Channels", systemImage: "bubble")
                }
            } detail: {
                if let fileID = state.selectedFileID, let manager = state.connectionPool[fileID] {
                    if manager.selectedChannel == "__console__" {
                        ConnectionView(manager: manager)
                    } else {
                        ChannelView(manager: manager)
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
            .toolbar {
                ToolbarItem {
                    Button("New Connection", systemImage: "plus") {
                        showingNewConnectionForm = true
                    }
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
                    ChannelList(manager: manager)
                } else {
                    ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
                }
            }
        }
        .environment(state)
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
