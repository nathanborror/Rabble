import Foundation
import SwiftUI
import SharedKit
import IRC

@MainActor @Observable
public final class API {
    public static let shared = API()

    private let filesProvider = FilesProvider.shared
    private let logsProvider = LogsProvider.shared

    private var session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 60       // keep it conservative
        cfg.waitsForConnectivity = true          // keeps behaviour similar
        return URLSession(configuration: cfg)
    }()

    public enum Error: Swift.Error, CustomStringConvertible {
        case missingConfig
        case missingService
        case missingModel

        public var description: String {
            switch self {
            case .missingConfig:
                "Missing config file"
            case .missingService:
                "Missing service ID"
            case .missingModel:
                "Missing model ID"
            }
        }
    }
}

// MARK: - Config

extension API {

    public var config: Config {
        filesProvider.config
    }

    /// Creates a new config and caches it locally. Does NOT upload to a remote server.
    public func configCreate() async throws {
        let config = Config()
        try filesProvider.cacheConfig(config)
    }

    /// Updates the config by replacing the cached data. Does NOT upload to a remote server.
    public func configUpdate(_ config: Config) async throws {
        try filesProvider.cacheConfig(config)
    }
}

// MARK: - Files

extension API {

    public func fileList(flag: String? = nil) -> [File] {
        filesProvider.cachedFileList()
            .filter { $0.flag == flag }
            .sorted { $0.order < $1.order }
    }

    public func fileListTree(fileID: String? = nil) throws -> [FileTree] {
        try filesProvider.cachedFileDirectoryTree(parentID: fileID)
    }

    public func file(_ fileID: String) throws -> File {
        try filesProvider.cachedFileMetadata(fileID)
    }

    public func file(path: String) throws -> File {
        try filesProvider.cachedFileMetadata(path: path)
    }

    public func fileData<T: Decodable>(_ fileID: String, type: T.Type) async throws -> T {
        try filesProvider.cachedFileObject(fileID)
    }

    public func fileData(_ fileID: String) async throws -> Data {
        try filesProvider.cachedFileData(fileID)
    }

    // File Create

    public func fileCreate(_ file: File, object: any Encodable) async throws -> String {
        try await filesProvider.cacheFileMetadata(file)
        try await filesProvider.cacheFileObject(object, fileID: file.id)
        return file.id
    }

    public func fileCreate(_ file: File, package: any Packagable) async throws -> String {
        try await filesProvider.cacheFileMetadata(file)
        try await filesProvider.cacheFilePackage(package, fileID: file.id)
        return file.id
    }

    public func fileCreate(_ file: File, data: Data = Data()) async throws -> String {
        try await filesProvider.cacheFileMetadata(file)

        // Skip caching and uploading of file data if directory
        if file.isDirectory {
            return file.id
        }

        try await filesProvider.cacheFileData(data, fileID: file.id)
        return file.id
    }

    // File Update

    public func fileUpdate(_ file: File) async throws {
        try await filesProvider.cacheFileMetadata(file)
    }

    public func fileUpdate(_ fileID: String, object: any Encodable) async throws {
        try await filesProvider.cacheFileObject(object, fileID: fileID)
    }

    public func fileUpdate(_ fileID: String, package: any Packagable) async throws {
        try await filesProvider.cacheFilePackage(package, fileID: fileID)
    }

    public func fileUpdate(_ fileID: String, data: Data) async throws {
        try await filesProvider.cacheFileData(data, fileID: fileID)
    }

    public func fileUpdateOrder(_ indexSet: IndexSet, to offset: Int, context: [File]) async throws {
        try await filesProvider.moveFiles(indexSet, to: offset, context: context)
    }

    // File Delete

    public func fileDelete(_ fileID: String) async throws {
        try await filesProvider.cacheFileDelete(fileID)
    }
}
