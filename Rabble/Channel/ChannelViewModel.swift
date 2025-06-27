import Foundation
import Network
import RabbleKit

@Observable
@MainActor
final class ChannelViewModel {

    let channelID: String

    var session: IRCSession
    var draft: String = ""
    var showingInspector = false

    var config: IRCConfig {
        session.server.config
    }

    var channel: IRCChannel? {
        try? session.channel(channelID)
    }

    var messages: [IRCMessage] {
        let messages = channel?.messages ?? []
        return messages.sorted { $0.created < $1.created }
    }

    init(channelID: String, session: IRCSession) {
        self.channelID = channelID
        self.session = session
    }

    func submit() {
        guard let channel else { return }
        if draft.hasPrefix("/topic") {
            let topic = draft.trimmingPrefix("/topic ")
            session.send("TOPIC \(channel.name) :\(topic)")
        } else {
            session.send("PRIVMSG \(channel.name) :\(draft)")
        }
        draft = ""
    }
}
