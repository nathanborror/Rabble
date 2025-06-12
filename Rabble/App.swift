import SwiftUI

@main
struct RabbleApp: App {
    var body: some Scene {
        WindowGroup {
            ChatView()
                .containerBackground(.background, for: .window)
        }
    }
}
