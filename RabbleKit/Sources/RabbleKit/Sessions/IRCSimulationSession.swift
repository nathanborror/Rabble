import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCSimulationSession", category: "IRC")

@MainActor
@Observable
public class IRCSimulationSession: IRCSession {
    public var fileID: String
    public var server: IRCServer

    public var isConnected = true
    public var isAuthenticated = false
    public var error: IRCSessionError? = nil

    public init(fileID: String, server: IRCServer) {
        self.fileID = fileID
        self.server = server
    }

    // MARK: Session Interface

    public func connect() async throws {
        print("not implemented")
    }

    public func disconnect() {
        print("not implemented")
    }

    public func channel(_ channelID: String) throws -> IRCChannel {
        guard let channel = server.channels.first(where: { $0.id == channelID }) else {
            throw IRCSessionError.channelNotFound
        }
        return channel
    }

    public func send(_ input: String) {
        print("not implemented")
    }

    public func send(_ line: String, expecting: @escaping (IRCMessage) -> Bool, timeout: TimeInterval = 10) async throws {
        print("not implemented")
    }

    public func sendChannelJoin(_ channel: String) {
        print("not implemented")
    }

    public func sendChannelInfo(_ channel: String) {
        print("not implemented")
    }

    public func sendChannelPart(_ channel: String) {
        print("not implemented")
    }

    public func sendRegistrationAttempt(email: String, password: String) {
        print("not implemented")
    }

    public func save() {
        Task {
            do {
                try await API.shared.fileUpdate(fileID, package: server)
            } catch {
                logger.error("\(error)")
            }
        }
    }

    public func clearLogs() {
        server.config.logs = []
    }
}
