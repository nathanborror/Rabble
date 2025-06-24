import SwiftUI
import RabbleKit

@main
struct MainApp: App {
    @State private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                ConnectionSidebar()
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
        state.resetAll()
        await appActive()
    }
}
