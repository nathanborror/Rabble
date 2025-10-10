import SwiftUI

@main
struct MainApp: App {
    @State private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                ServerList()
            } detail: {
                if let fileID = state.selection?.sessionID, let session = state.sessionPool[fileID] {
                    if let channelID = state.selection?.channelID {
                        ChannelView(channelID: channelID, session: session)
                            .id(fileID+channelID)
                    } else {
                        ServerView(session: session)
                            .id(fileID)
                    }
                } else {
                    ContentUnavailableView("No Servers", systemImage: "apple.terminal")
                }
            }
            .onAppear {
                Task { await appActive() }
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
        try? await state.resetAll()
        await appActive()
    }
}
