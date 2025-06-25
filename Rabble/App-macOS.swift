import SwiftUI
import RabbleKit

@main
struct MainApp: App {
    @State private var state = AppState.shared
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                ServerSidebar()
                    .frame(minWidth: 200)
            } detail: {
                if let fileID = state.selection?.fileID, let session = state.sessionPool[fileID] {
                    if let channelID = state.selection?.channelID {
                        ChannelView(session: session)
                            .id(fileID+channelID)
                    } else {
                        ServerView(session: session)
                            .id(fileID)
                    }
                } else {
                    ContentUnavailableView("No Server", systemImage: "apple.terminal")
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
                if let fileID = fileID.wrappedValue, let session = state.sessionPool[fileID] {
                    ChannelList(session: session)
                } else {
                    ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
                }
            }
        }
        .environment(state)
        .defaultSize(width: 500, height: 600)

        WindowGroup("Server Info", id: "server", for: String.self) { fileID in
            if let fileID = fileID.wrappedValue, let session = state.sessionPool[fileID] {
                ServerInfo(session: session)
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
