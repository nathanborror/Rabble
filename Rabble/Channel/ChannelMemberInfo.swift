import SwiftUI
import IRC
import RabbleKit

struct ChannelMemberInfo: View {
    @Environment(AppState.self) var state

    let sessionID: String
    let channelID: String
    let userID: String

    private var member: ChannelUser? {
        guard let session = state.sessionPool[sessionID] else { return nil }
        return try? session.getChannelMember(userID, channelID: channelID)
    }

    var body: some View {
        ScrollView {
            if let member {
                VStack(alignment: .leading, spacing: 16) {
                    InspectorValue("Nick", value: member.nick)
                    InspectorValue("Ident", value: member.ident)
                    InspectorValue("Name", value: member.name)
                    InspectorValue("Hostname", value: member.hostname)
                    InspectorValue("Server", value: member.server)
                    InspectorValue("Hops", value: "\(member.hops ?? 0)")
                    InspectorValue("Modes", value: member.modes)
                    InspectorValue("Membership", value: membership)
                    InspectorValue("Status", value: status)

                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
        }
    }

    var membership: String? {
        switch member?.membership {
        case .owner:
            "Owner"
        case .admin:
            "Admin"
        case .op:
            "Operator"
        case .half:
            "Halfops"
        case .voice:
            "Voice"
        case nil:
            nil
        }
    }

    var status: String? {
        switch member?.status {
        case .online:
            "Online"
        case .away:
            "Away"
        case nil:
            nil
        }
    }
}
