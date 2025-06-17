import SwiftUI
import RabbleKit

@main
struct RabbleApp: App {
    @State private var client = Client()

    var body: some Scene {
        WindowGroup {
            ConsoleView()
                .environment(client)
        }
        .commands {
            CommandMenu("Rabble") {
                Button("Save") {
                    client.save()
                }
                .keyboardShortcut("s", modifiers: .command)
                Divider()
                Button("Reset App") {
                    client.reset()
                }
            }
        }

        WindowGroup("Channels", id: "channels", for: String.self) { sessionID in
            NavigationStack {
                if let sessionID = sessionID.wrappedValue, let session = client.session(sessionID) {
                    ChannelList(session: session)
                } else {
                    ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
                }
            }
            .environment(client)
        }
    }
}
