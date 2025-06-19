import SwiftUI
import OSLog
import UniformTypeIdentifiers
import Network
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

    var selectedFileID: String? = nil

    private let filesProvider: FilesProvider
    private let logsProvider: LogsProvider

    private var pool: [String: NWConnection] = [:]

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

    var sessions: [File] {
        filesProvider.files.filter { $0.isSession }
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
    }

    func restore() async throws {
        try await filesProvider.restore()
        try await logsProvider.restore()
    }

    func resetAll() {
        do {
            // Reset providers
            filesProvider.reset()
            logsProvider.reset()

            // Delete all files
            try FileManager.default.removeItems(at: URL.documentsDirectory)
        } catch {
            log(error: error)
        }
    }

    // MARK: - File Handling

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

    // MARK: - IRC

    func create(server: String, port: UInt16, nick: String, name: String) async throws -> String {
        let session = IRC.Session(server: server, port: port, nick: nick, name: name)
        let package = IRC(session: session)
        let fileID = String.id
        return try await fileCreate(id: fileID, filename: "\(fileID).irc", mimetype: .package, package: package)
    }

    func connect(_ fileID: String) async throws {
        let package: IRC = try filePackage(fileID)
        let endpoint = NWEndpoint.hostPort(host: .init(package.session!.server), port: .init(integerLiteral: package.session!.port))
        pool[fileID] = NWConnection(to: endpoint, using: .tcp)
        pool[fileID]?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                try await self.handleStateUpdate(state: state, fileID: self.selectedFileID!)
            }
        }
        pool[fileID]?.start(queue: .main)
    }

    func disconnect(_ fileID: String) async throws {

        // Update session pool
        pool[fileID]?.cancel()
        pool[fileID] = nil

        // Update session
        var package: IRC = try filePackage(fileID)
        package.session?.connected = false
        try await API.shared.fileUpdate(fileID, package: package)
    }

    func send(_ input: String, fileID: String) {

        // Required, IRC is a line-oriented protocol
        let input = input+"\r\n"

        // Send input to server session
        guard let data = input.data(using: .utf8) else { return }
        pool[fileID]?.send(content: data, completion: .contentProcessed { error in
            guard let error else { return }
            print(error)
        })
    }

    private func handleStateUpdate(state: NWConnection.State, fileID: String) async throws {
        var package: IRC = try filePackage(fileID)

        switch state {
        case .ready:
            package.session?.connected = true

            // TODO: What is the difference between a nickname and a username?
            let messages = [
                "NICK \(package.session!.nick)",
                "USER \(package.session!.nick) 0 * :\(package.session!.name)",
            ]
            for message in messages {
                send(message, fileID: fileID)
            }
            handleListen(fileID)
        case .failed(let error):
            print(error)
            try await disconnect(fileID)
        case .cancelled:
            try await disconnect(fileID)
        default:
            break
        }

        try await API.shared.fileUpdate(fileID, package: package)
    }

    private func handleListen(_ fileID: String) {
        pool[fileID]?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                try await self.handleIncomingData(data, fileID: fileID)
                if error == nil {
                    self.handleListen(fileID)
                }
            }
        }
    }

    private func handleIncomingData(_ data: Data?, fileID: String) async throws {
        guard let data, let newText = String(data: data, encoding: .utf8) else { return }
        incomingDataBuffer += newText

        while let range = incomingDataBuffer.range(of: "\r\n") {
            let line = String(incomingDataBuffer[..<range.lowerBound])
            incomingDataBuffer = String(incomingDataBuffer[range.upperBound...]) // Remove parsed line + delimiter

            // Upsert new line to session object
            var package: IRC = try filePackage(fileID)
            package.session?.upsert(log: .init(line))
            try await API.shared.fileUpdate(fileID, package: package)

            // Respond to periodic PINGs to maintain the connection
            if line.hasPrefix("PING ") {
                let payload = line.trimmingPrefix("PING ")
                send("PONG \(payload)", fileID: fileID)
            }
        }
    }

    private func apply(message: IRC.Message, fileID: String) async throws {
        guard case .numeric(let numeric) = message.command else {
            return
        }
        switch numeric {
        case .RPL_LIST:
            guard message.params.count >= 4 else {
                return
            }
            let name = message.params[1]
            let users = Int(message.params[2]) ?? 0
            let topic = message.params[3].isEmpty ? nil : message.params[3]
            guard name != "*" else {
                return
            }

            var package: IRC = try filePackage(fileID)
            package.session?.upsert(channel: .init(name: name, users: users, topic: topic))
            try await API.shared.fileUpdate(fileID, package: package)
        default:
            return
        }
    }

    private var incomingDataBuffer = ""
}
