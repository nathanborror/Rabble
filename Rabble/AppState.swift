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

        public var description: String {
            switch self {
            case .restorationError(let detail):
                "Restoration error: \(detail)"
            case .serviceError(let detail):
                "Service error: \(detail)"
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

            switch server.config.kind {
            case .network:
                sessionPool[file.id] = IRCSessionServer(server)
            case .simulation:
                sessionPool[file.id] = IRCSessionSimulation(server)
            }
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

    func createServer(kind: IRC.Config.Kind, server: String, port: UInt16, nick: String, ident: String?, username: String, email: String?, password: String?, realname: String) async throws {
        let fileID = String.id
        let config = IRC.Config(kind: kind, server: server, port: port, nick: nick, ident: ident, username: username, realname: realname, email: email, password: password)
        let server = IRC.Server(id: fileID, config: config)

        _ = try await fileCreate(id: fileID, filename: "\(fileID).irc", mimetype: .package, package: server)

        switch server.config.kind {
        case .network:
            sessionPool[fileID] = IRCSessionServer(server)
        case .simulation:
            sessionPool[fileID] = IRCSessionSimulation(server)
        }

        selection = .init(fileID: fileID)

        // Connect to server
        try await sessionPool[fileID]?.connect()
    }

    func deleteServer(fileID: String) async throws {
        try await filesProvider.cacheFileDelete(fileID)
        sessionPool.removeValue(forKey: fileID)
        if selection?.sessionID == fileID {
            selection = nil
        }
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
