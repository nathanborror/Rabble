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
                            Label(connection.file.name ?? connection.file.path, systemImage: "bubble")
                        }
                    }
                }
            } detail: {
                if let fileID = state.selectedFileID, let manager = state.connectionPool[fileID] {
                    ConnectionView(manager: manager)
                } else {
                    ContentUnavailableView("No Session", image: "cloud")
                }
            }
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
