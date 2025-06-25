import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCSession", category: "IRC")

@MainActor
public protocol IRCSession {

    var fileID: String { get }
    var server: IRCServer { get }
    var isConnected: Bool { get }

    func connect() async throws
    func disconnect()
    func channel(_ channelID: String) throws -> IRCChannel
    func send(_ input: String)
    func sendChannelJoin(_ channel: String)
    func sendChannelInfo(_ channel: String)
    func sendChannelPart(_ channel: String)
    func save()
    func clearLogs()
}
