import Foundation
import OSLog
import Network

private let logger = Logger(subsystem: "IRCSimulationSession", category: "IRC")

@MainActor
@Observable
public class IRCSimulationSession: IRCSession {

    public var fileID: String
    public var server: IRCServer

    public enum Error: Swift.Error {
        case channelNotFound
    }

    public init(fileID: String, server: IRCServer) {
        self.fileID = fileID
        self.server = server
    }

    // MARK: Convenience

    public var isConnected: Bool {
        true
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
            throw Error.channelNotFound
        }
        return channel
    }

    public func send(_ input: String) {
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
