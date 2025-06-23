import SwiftUI
import RabbleKit

@main
struct MainApp: App {
    @State private var state = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                ConnectionSidebar()
                    .frame(minWidth: 200)
            } detail: {
                if let fileID = state.selection?.fileID, let manager = state.connectionPool[fileID] {
                    if let channelID = state.selection?.channelID {
                        ChannelView(manager: manager)
                            .id(fileID+channelID)
                    } else {
                        ConnectionView(manager: manager)
                            .id(fileID)
                    }
                } else {
                    ContentUnavailableView("No Connection", systemImage: "apple.terminal")
                }
            }
            .containerBackground(.background, for: .window)
            
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
