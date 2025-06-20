import SwiftUI
import OSLog
import UniformTypeIdentifiers
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

    struct Selection: Hashable {
        let fileID: String
        let channelID: String?
    }

    var selection: Selection? = nil
    var connectionPool: [String: ConnectionManager] = [:]

    private let filesProvider: FilesProvider
    private let logsProvider: LogsProvider

    var config: Config {
        filesProvider.config
    }

    var files: [File] {
        filesProvider.files
    }

    var fileTree: [FileTree] {
        let files = try? API.shared.fileListTree()
        return files ?? []
    }

    var logs: [Log] {
        logsProvider.logs
    }

    private init() {
        self.filesProvider = .shared
        self.logsProvider = .shared

        logger.info("🍱 \(URL.documentsDirectory.path())")

        Task { try await ready() }
    }

    func ready() async throws {
        async let filesReady: Void = filesProvider.ready()
        async let logsReady: Void = logsProvider.ready()
        _ = try await [filesReady, logsReady]

        for file in files.filter({ $0.isIRC }) {
            let manager = try ConnectionManager(file: file)
            connectionPool[file.id] = manager
        }
    }

    func resetAll() {
        do {
            // Reset providers
            filesProvider.reset()
            logsProvider.reset()

            // Delete all files
            try FileManager.default.removeItems(at: URL.documentsDirectory)

            // Clear connection pool
            connectionPool = [:]
            selection = nil
        } catch {
            log(error: error)
        }
    }

    // MARK: - IRC

    func createConnection(server: String, port: UInt16, nick: String, username: String, name: String) async throws {
        let session = IRC.Session(server: server, port: port, nick: nick, username: username, name: name)
        let package = IRC(session: session)
        let fileID = String.id
        _ = try await fileCreate(id: fileID, filename: "\(fileID).irc", mimetype: .package, package: package)

        let file = try file(fileID)
        connectionPool[file.id] = try ConnectionManager(file: file)
        selection = .init(fileID: file.id, channelID: nil)
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
