import SwiftUI
import Network
import RabbleKit

@MainActor
@Observable
class ChatManager {

    //var host: String = "irc.libera.chat" // Libera Chat is the successor to Freenode
    var host: String = "irc.zeronode.net"
    var port: Int = 6667
    var nickname = "wild_one_25"

    var channels: [ChatChannel] = []
    var messages: [ChatMessage] = []

    var isConnected = false
    var isListingChannels = false

    var client: IRCClient? = nil

    func connect() {
        client = IRCClient(options: .init(port: port, host: host, nickname: .init(nickname)!))
        client?.delegate = self
        client?.connect()
    }

    func disconnect() {
        client = nil
        channels = []
        messages = []
    }

    func send(_ message: String) {
        print("not implemented")
    }

    func command(_ command: String) {
        send(command+"\n")
    }

    func listChannels() {
        command("LIST")
    }

    func join(_ channel: String) {
        command("JOIN \(channel)")
    }

    func part(_ channel: String) {
        command("PART \(channel)")
    }
}

extension ChatManager: IRCClientDelegate {

    nonisolated func client(_ client: IRCClient, changeTopic: String, of channel: IRCChannelName) {
        print("changed topic:", changeTopic, channel)
    }

    nonisolated func client(_ client: IRCClient, changedNickTo nick: IRCNickName) {
        print("changed nick to:", nick)
    }

    nonisolated func client(_ client: IRCClient, changedUserModeTo mode: IRCUserMode) {
        print("changed user mode to:", mode)
    }

    nonisolated func client(_ client: IRCClient, messageOfTheDay: String) {
        Task { @MainActor in
            let message = ChatMessage(
                host: "",
                status: 0,
                user: "",
                message: messageOfTheDay
            )
            messages.append(message)
        }
    }

    nonisolated func client(_ client: IRCClient, notice message: String, for recipients: [IRCMessageRecipient]) {
        Task { @MainActor in
            let message = ChatMessage(
                host: "",
                status: 0,
                user: "",
                message: message
            )
            messages.append(message)
        }
    }

    nonisolated func client(_ client: IRCClient, received message: IRCMessage) {
        Task { @MainActor in
            let message = ChatMessage(
                host: "",
                status: 0,
                user: "",
                message: message.description
            )
            messages.append(message)
        }
    }

    nonisolated func client(_ client: IRCClient, registered nick: IRCNickName, with userInfo: IRCUserInfo) {
        print("registered \(nick) with \(userInfo)")
    }

    nonisolated func clientFailedToRegister(_ client: IRCClient) {
        print("failed to register")
    }
}
