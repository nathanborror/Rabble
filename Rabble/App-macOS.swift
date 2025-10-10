import SwiftUI

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
                if let server = state.selection?.server, let serverState = state.servers[server] {
                    if let channel = state.selection?.channel, let channelState = serverState.joined[channel] {
                        ChannelView()
                            .environment(serverState)
                            .environment(channelState)
                    } else {
                        ServerView()
                            .environment(serverState)
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

        WindowGroup("Channels", id: "channels", for: String.self) { server in
            NavigationStack {
                if let server = server.wrappedValue, let serverState = state.servers[server] {
                    ChannelList()
                        .environment(serverState)
                } else {
                    ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
                }
            }
        }
        .environment(state)
        .defaultSize(width: 500, height: 600)

        WindowGroup("Server Info", id: "server", for: String.self) { server in
            if let server = server.wrappedValue, let serverState = state.servers[server] {
                ServerInfo()
                    .environment(serverState)
            } else {
                ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
            }
        }
        .environment(state)
        .defaultSize(width: 350, height: 500)

        WindowGroup("User Info", id: "user", for: AppState.Selection.self) { selection in
            if let selection = selection.wrappedValue, let nick = selection.nick {
                UserDetail(server: selection.server, nick: nick)
            } else {
                ContentUnavailableView("No Channel Member", image: "person.text.rectangle")
            }
        }
        .environment(state)
        .defaultSize(width: 350, height: 500)
    }

    func appActive() async {
        print("appActive: not implemented")
    }

    func appReset() async {
        try? await state.resetAll()
        await appActive()
    }
}
