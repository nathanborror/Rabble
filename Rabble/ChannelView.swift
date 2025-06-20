import SwiftUI
import RabbleKit

struct ChannelView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var manager: ConnectionManager
    @State private var messageText = ""

    init(manager: ConnectionManager) {
        self.manager = manager
    }
    
    var body: some View {
        Text("ChannelView")
    }
}
