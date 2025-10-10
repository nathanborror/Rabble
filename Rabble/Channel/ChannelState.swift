import Foundation
import Network
import IRC

@MainActor
@Observable
final class ChannelState {

    var name: String
    var members: Set<String>
    var topic: String?

    var draft: String = ""
    var showingInspector = false

    init(name: String, members: Set<String> = [], topic: String? = nil) {
        self.name = name
        self.members = members
        self.topic = topic
    }
}
