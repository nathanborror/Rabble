import Foundation
import Network
import IRC
import RabbleKit

@Observable
@MainActor
final class ServerViewModel {

    var session: IRCSession
    var draft: String = ""

    var config: IRC.Config {
        session.server.config
    }

    var logs: [IRC.Message] {
        session.server.config.logs
    }

    var list: [IRC.Config.Channel] {
        session.server.config.list
    }

    var channels: [String: IRC.Channel] {
        Dictionary(uniqueKeysWithValues: session.server.channels.map { ($0.id, $0) })
    }

    init(session: IRCSession) {
        self.session = session
    }

    func submit() {
        Task {
            do {
                try await session.send(draft)
                draft = ""
            } catch {
                print(error)
            }
        }
    }
}
