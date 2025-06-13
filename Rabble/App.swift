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
                Button("Reset App") {
                    client.reset()
                }
            }
        }
    }
}
