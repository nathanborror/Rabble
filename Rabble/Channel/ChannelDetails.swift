import SwiftUI
import IRC
import RabbleKit

struct ChannelDetails: View {
    @Environment(AppState.self) var state
    @Environment(ChannelViewModel.self) var viewModel
    @Environment(\.openWindow) var openWindow

    let session: IRCSession

    @State private var selection: String? = nil

    var body: some View {
        List(selection: $selection) {
            Group {
                if !viewModel.operators.isEmpty {
                    ChannelMemberSection(title: "Operators") {
                        ForEach(viewModel.operators) { user in
                            ChannelMember(user: user).tag(user.id)
                        }
                    }
                }
                if !viewModel.voice.isEmpty {
                    ChannelMemberSection(title: "Voice") {
                        ForEach(viewModel.voice) { user in
                            ChannelMember(user: user).tag(user.id)
                        }
                    }
                }
                if !viewModel.users.isEmpty {
                    ChannelMemberSection(title: "Users") {
                        ForEach(viewModel.users) { user in
                            ChannelMember(user: user).tag(user.id)
                        }
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            .listRowSeparator(.hidden)
        }
        .navigationTitle("Members")
        .contextMenu(forSelectionType: String.self) { userIDs in
            if !userIDs.contains(viewModel.config.nick) {
                Button("Give Operator") {
                    print("not implemented")
                }
                Button("Give Voice") {
                    print("not implemented")
                }
                Divider()
                Button("Kick") {
                    handleKick(userIDs)
                }
                Button("Ban") {
                    print("not implemented")
                }
            }
        } primaryAction: { userIDs in
            handleShowInfo(userIDs)
        }
    }

    func handleShowInfo(_ userIDs: Set<String>) {
        guard let userID = userIDs.first else { return }
        if var selection = state.selection {
            selection.userID = userID
            openWindow(id: "user", value: selection)
        }
    }

    func handleKick(_ userIDs: Set<String>) {
        Task {
            for userID in userIDs {
                try await viewModel.session.channelKick(viewModel.channelID, nick: userID, comment: nil)
            }
        }
    }
}

struct ChannelMemberSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    @State var isExpanded = true

    var body: some View {
        HStack(spacing: 4) {
            Button {
                isExpanded.toggle()
            } label: {
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .frame(width: 16, height: 16)
            }
            .foregroundStyle(.secondary)
            .buttonStyle(.borderless)
            
            Text(title)
                .fontWeight(.semibold)

            Spacer()
        }
        .padding(.vertical, 4)

        if isExpanded {
            content
        }
    }
}

struct ChannelMember: View {
    let user: ChannelUser

    var body: some View {
        HStack(spacing: 0) {
            Text(user.nick)
                .font(.system(.subheadline, design: .monospaced))
            Spacer()
        }
        .opacity(opacity)
        .padding(.leading, 20)
    }

    var opacity: CGFloat {
        switch user.status {
        case .online: 1
        case .away: 0.3
        case nil: 1
        }
    }
}
