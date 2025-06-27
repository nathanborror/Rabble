import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCSession", category: "IRC")

@MainActor
public protocol IRCSession {

    var fileID: String { get }
    var server: IRCServer { get }
    var isConnected: Bool { get }
    var isAuthenticated: Bool { get }
    var error: IRCSessionError? { get }

    func connect() async throws
    func disconnect()
    func channel(_ channelID: String) throws -> IRCChannel
    func send(_ line: String)
    func send(_ line: String, expecting: @escaping (IRCMessage) -> Bool, timeout: TimeInterval) async throws
    func sendChannelJoin(_ channel: String)
    func sendChannelInfo(_ channel: String)
    func sendChannelPart(_ channel: String)
    func sendRegistrationAttempt(email: String, password: String)
    func save()
    func clearLogs()
}

public enum IRCSessionError: Error, CustomStringConvertible {
    case channelNotFound
    case authenticationFailed
    case timeout
    case unhandled(Error)

    public var description: String {
        switch self {
        case .channelNotFound:
            "Channel not found"
        case .authenticationFailed:
            "Authentication failed"
        case .timeout:
            "Timeout"
        case .unhandled(let error):
            "Unhandled error: \(error)"
        }
    }
}
