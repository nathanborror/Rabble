import SwiftUI
import RabbleKit

@main
struct MainApp: App {
    @State private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                ServerList()
                    .frame(minWidth: 200)
                    .sheet(isPresented: $state.showingServerForm) {
                        NavigationStack {
                            ServerForm()
                        }
                    }
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
            CommandGroup(replacing: .newItem) {
                Button("New Server") {
                    state.showingServerForm = true
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(after: .newItem) {
                Button("Save All") {
                    Task {
                        do {
                            try await state.save()
                        } catch {
                            print(error)
                        }
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
            }
            CommandMenu("Rabble") {
                Button("Reset All Data") {
                    Task {
                        do {
                            try await state.resetAll()
                        } catch {
                            print(error)
                        }
                    }
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

        WindowGroup("User Info", id: "user", for: AppState.Selection.self) { selection in
            if let selection = selection.wrappedValue, let channelID = selection.channelID, let userID = selection.userID {
                ChannelMemberInfo(sessionID: selection.sessionID, channelID: channelID, userID: userID)
            } else {
                ContentUnavailableView("No Channel Member", image: "person.text.rectangle")
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
        try? await state.resetAll()
        await appActive()
    }
}
