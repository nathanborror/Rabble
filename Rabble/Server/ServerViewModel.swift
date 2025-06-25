import Foundation
import Network
import RabbleKit

@Observable
@MainActor
final class ServerViewModel {

    var session: IRCSession
    var draft: String = ""

    var config: IRCConfig {
        session.server.config
    }

    var logs: [IRCMessage] {
        session.server.config.logs
    }

    var list: [IRCConfig.Channel] {
        session.server.config.list
    }

    var channels: [String: IRCChannel] {
        Dictionary(uniqueKeysWithValues: session.server.channels.map { ($0.id, $0) })
    }

    init(session: IRCSession) {
        self.session = session
    }

    func submit() {
        session.send(draft)
        draft = ""
    }
}
