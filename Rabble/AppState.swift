import SwiftUI
import OSLog
import UniformTypeIdentifiers
import IRC
import RabbleKit

private let logger = Logger(subsystem: "AppState", category: "App")

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    enum Error: Swift.Error, CustomStringConvertible {
        case restorationError(String)
        case serviceError(String)
        case notConnected

        public var description: String {
            switch self {
            case .restorationError(let detail):
                "Restoration error: \(detail)"
            case .serviceError(let detail):
                "Service error: \(detail)"
            case .notConnected:
                "Not connected to the server"
            }
        }
    }

    struct Selection: Codable, Hashable {
        var sessionID: String
        var channelID: String?
        var userID: String?

        init(fileID: String, channelID: String? = nil, nick: String? = nil) {
            self.sessionID = fileID
            self.channelID = channelID
            self.userID = nick
        }
    }

    var selection: Selection? = nil
    var sessionPool: [String: IRC.IRCSession] = [:]
    var showingServerForm = false

    private let filesProvider: FilesProvider
    private let logsProvider: LogsProvider

    var config: RabbleKit.Config {
        filesProvider.config
    }

    var files: [File] {
        filesProvider.files
    }

    var fileTree: [FileTree] {
        let files = try? API.shared.fileListTree()
        return files ?? []
    }

    var instructions: [File] {
        filesProvider.files.filter { $0.isInstruction }
    }
    
    var logs: [Log] {
        logsProvider.logs
    }

    private init() {
        self.filesProvider = .shared
        self.logsProvider = .shared
        logger.info("🍱 \(URL.documentsDirectory.path())")
    }

    func ready() async throws {
        async let filesReady: Void = filesProvider.ready()
        async let logsReady: Void = logsProvider.ready()
        _ = try await [filesReady, logsReady]

        for file in files.filter({ $0.isIRC }) {
            var server: IRC.Server = try filePackage(file.id)
            server.id = file.id // This needs to be set because the Server.ID does not get saved because Server is a package
            sessionPool[file.id] = IRCSessionServer(server)
        }
    }

    func resetAll() async throws {
        do {

            // Disconnect all sessions
            for (_, session) in sessionPool {
                try await session.disconnect()
            }

            // Reset providers
            filesProvider.reset()
            logsProvider.reset()

            // Delete all files
            try FileManager.default.removeItems(at: URL.documentsDirectory)

            // Clear session pool
            sessionPool = [:]
            selection = nil
        } catch {
            log(error: error)
        }
    }

    func save() async throws {
        for (fileID, session) in sessionPool {
            try await API.shared.fileUpdate(fileID, package: session.server)
        }
    }

    // MARK: - IRC

    func sessionCreate(kind: IRC.Config.Kind, server: String, port: UInt16, useTLS: Bool, nick: String, ident: String?, username: String, email: String?, password: String?, realname: String) async throws {
        let fileID = String.id
        let config = IRC.Config(kind: kind, server: server, port: port, useTLS: useTLS, nick: nick, ident: ident, username: username, realname: realname, email: email, password: password)
        let server = IRC.Server(id: fileID, config: config)

        _ = try await fileCreate(id: fileID, filename: "\(fileID).irc", mimetype: .package, package: server)

        let session = IRCSessionServer(server)
        sessionPool[fileID] = session
        selection = .init(fileID: fileID)

        // Connect to server
        try await sessionConnect(session: session)
    }

    func sessionDelete(session: IRCSession) async throws {
        let fileID = session.server.id
        try await filesProvider.cacheFileDelete(fileID)
        sessionPool.removeValue(forKey: fileID)
        if selection?.sessionID == fileID {
            selection = nil
        }
    }

    func sessionConnect(session: IRCSession) async throws {
        try await session.connect()
        try await self.sessionConnectSequence(session: session)
    }

    private func sessionConnectSequence(session: IRCSession) async throws {
        let nick = session.server.config.nick
        let username = session.server.config.username
        let realname = session.server.config.realname ?? ""

        if let password = session.server.config.password {
            let token = sessionToken(nick: nick, username: username, password: password)
            try await session.send("CAP LS")
            try await session.send("NICK \(nick)")
            try await session.send("USER \(username) 0 * :\(realname)")
            try await session.sendCapRequest("sasl", "echo-message")
            try await session.sendAuthentication(token)
            try await session.sendCapEnd()
        } else {
            try await session.send("CAP LS")
            try await session.send("NICK \(nick)")
            try await session.send("USER \(username) 0 * :\(realname)")
            try await session.sendCapRequest("sasl", "echo-message")
            try await session.sendCapEnd()
        }

        for channel in session.server.channels {
            try await session.channelJoin(channel.id)
        }
    }

    func sessionRegister(session: IRCSession, email: String, password: String) async throws {
        guard session.isConnected else {
            throw Error.notConnected
        }
        try await session.nickServRegister(email: email, password: password)
    }

    func sessionDisconnect(session: IRCSession) async throws {
        try await session.disconnect()
    }

    private func sessionToken(nick: String, username: String, password: String) -> String {
        let authString = "\(nick)\u{0000}\(username)\u{0000}\(password)"
        let data = authString.data(using: .utf8)!
        return data.base64EncodedString()
    }

    // MARK: - File Handling

    func file(_ fileID: String) throws -> File {
        try filesProvider.cachedFileMetadata(fileID)
    }

    func fileObject<T: Decodable>(_ fileID: String) throws -> T {
        try filesProvider.cachedFileObject(fileID)
    }

    func filePackage<T: Packagable>(_ fileID: String) throws -> T {
        return try filesProvider.cachedFilePackage(fileID)
    }

    private func fileCreate(id: String, filename: String, path: String? = nil, name: String? = nil, mimetype: UTType, package: any Packagable) async throws -> String {
        let path = path ?? filename
        let file = File(id: id, path: path, name: name, mimetype: mimetype)
        return try await API.shared.fileCreate(file, package: package)
    }

    private func fileCreate(id: String, filename: String, path: String? = nil, name: String? = nil, mimetype: UTType, object: any Encodable) async throws -> String {
        let path = path ?? filename
        let file = File(id: id, path: path, name: name, mimetype: mimetype)
        return try await API.shared.fileCreate(file, object: object)
    }

    private func fileCreate(id: String, filename: String, path: String? = nil, name: String? = nil, mimetype: UTType) async throws -> String {
        let path = path ?? filename
        let file = File(id: id, path: path, name: name, mimetype: mimetype)
        return try await API.shared.fileCreate(file)
    }

    // MARK: - Logging

    func log(error: Swift.Error) {
        logsProvider.log(error: error)
    }

    func logsReset() {
        logsProvider.reset()
    }
}
