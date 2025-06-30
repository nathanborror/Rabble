import Foundation
import Network
import IRC
import RabbleKit

@Observable
@MainActor
final class ChannelViewModel {

    let channelID: String

    var session: IRCSession
    var draft: String = ""
    var showingInspector = false

    var config: IRC.Config {
        session.server.config
    }

    var title: String {
        channel?.name ?? "unknown"
    }

    var subtitle: String {
        switch config.kind {
        case .network:
            "\(config.server) · \(channel?.users.count ?? 0) users"
        case .simulation:
            "\(channel?.users.count ?? 0) users · simulation using \(config.server)"
        }
    }

    var channel: IRC.Channel? {
        try? session.getChannel(channelID)
    }

    var messages: [IRC.Message] {
        let messages = channel?.messages ?? []
        return messages.sorted { $0.created < $1.created }
    }

    var members: [IRC.ChannelUser] {
        guard let users = channel?.users.values else { return [] }
        return Array(users)
    }

    var operators: [IRC.ChannelUser] {
        members.filter {
            $0.membership == .owner ||
            $0.membership == .admin ||
            $0.membership == .op ||
            $0.membership == .half
        }
    }

    var voice: [IRC.ChannelUser] {
        members.filter { $0.membership == .voice }
    }

    var users: [IRC.ChannelUser] {
        members.filter { $0.membership == nil }
    }

    init(channelID: String, session: IRCSession) {
        self.channelID = channelID
        self.session = session
    }

    func submit() {
        Task {
            do {
                guard let channel else { return }
                if draft.hasPrefix("/topic") {
                    let topic = draft.trimmingPrefix("/topic ")
                    try await session.send("TOPIC \(channel.name) :\(topic)")
                } else {
                    try await session.send("PRIVMSG \(channel.name) :\(draft)")
                }
                draft = ""
            } catch {
                print(error)
            }
        }
    }
}
