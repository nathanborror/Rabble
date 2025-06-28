import Foundation
import SwiftUI
import SharedKit
import GenKit
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

// MARK: - Services

extension API {

    public func generate(_ lines: [String]) async throws -> [GenKit.Message] {
        let (service, model) = try preferredChatService()

        let message = Message(role: .user, content: lines.joined(separator: "\n"))

        var req = ChatSessionRequest(service: service, model: model)
        req.with(system: """
            You are to behave as if you are an IRCv3 server. Your task is to respond to IRC messages exactly as an IRCv3 server would. 

            Parse the incoming IRC logs and generate an appropriate response. Follow these guidelines:

            - Responses should be in the format of IRC protocol messages.
            - Each response line should start with a colon (:) followed by the server name (use "irc.example.com" as the server name).
            - Each message should always be on a new line.
            - Include appropriate numeric replies or command responses as per IRC protocol.
            - If the message is invalid or unrecognized, respond with an appropriate error message.
            - Do not add any explanations or comments outside of the IRC protocol format.
            - Channels should be social, simulate other users in the channel and always return 1-3 responses. 

            Here are some examples of common IRC messages and their corresponding server responses:

            Example 1:
            Input: 
                NICK Alice
            Response: 
                :irc.example.com 001 Alice :Welcome to the Internet Relay Network Alice!user@host

            Example 2:
            Input: 
                JOIN #channel
            Response:
                :irc.example.com 353 Alice = #channel :Alice @ChannelOp +Voice
                :irc.example.com 366 Alice #channel :End of /NAMES list.

            Example 3:
            Input: 
                INVALID_COMMAND
            Response: 
                :irc.example.com 421 * INVALID_COMMAND :Unknown command
            
            Example 4:
            Input:
                PRIVMSG #channel :hi
            Response:
                :Bob!~u@ghi789.irc PRIVMSG #channel :Hello Alice!
                :Charlie!~u@aib123.irc PRIVMSG #channel :Welcome to this fine corner of the IRC

            Remember, you must respond ONLY as an IRCv3 server would. Do not provide any additional information, explanations, or engage in conversation outside of the IRC protocol. Your entire response should be formatted as valid IRC server messages.
            """)
        req.with(history: [message])

        let resp = try await ChatSession.shared.completion(req)
        return resp.messages
    }

    public func preferredChatService() throws -> (GenKit.ChatService, GenKit.Model) {
        let service = try get(serviceID: config.serviceChatDefault, config: config)
        let model = try get(modelID: service.preferredChatModel, service: service)
        return (try service.chatService(session: session), model)
    }

    public func preferredImageService() throws -> (GenKit.ImageService, GenKit.Model) {
        let service = try get(serviceID: config.serviceImageDefault, config: config)
        let model = try get(modelID: service.preferredImageModel, service: service)
        return (try service.imageService(session: session), model)
    }

    public func preferredSummarizationService() throws -> (GenKit.ChatService, GenKit.Model) {
        let service = try get(serviceID: config.serviceSummarizationDefault, config: config)
        let model = try get(modelID: service.preferredSummarizationModel, service: service)
        return (try service.summarizationService(session: session), model)
    }

    func get(serviceID: String?, config: Config) throws -> GenKit.Service {
        guard let service = config.services.first(where: { $0.id == serviceID }) else {
            throw Error.missingService
        }
        return service
    }

    func get(modelID: String?, service: GenKit.Service) throws -> GenKit.Model {
        guard let model = service.models.first(where: { $0.id == modelID }) else {
            throw Error.missingModel
        }
        return model
    }
}
