import SwiftUI
import RabbleKit

@main
struct RabbleApp: App {
    @State private var client = Client()

    var body: some Scene {
        WindowGroup {
            ChatView()
                .environment(client)
        }
        .commands {
            CommandMenu("Rabble") {
                Button("Save") {
                    client.save()
                }
                .keyboardShortcut("s", modifiers: .command)
                Button("Regenerate") {
                    client.regenerate()
                }
                Divider()
                Button("Reset App") {
                    client.reset()
                }
            }
        }
    }
}
