import Foundation

public struct Server: Identifiable, Codable, Sendable {
    public var id: String
    public var config: Config
    public var channels: [Channel]

    public init(id: String = UUID().uuidString, config: Config, channels: [Channel] = []) {
        self.id = id
        self.config = config
        self.channels = channels
    }

    public static func load(url: URL) throws -> Self {
        let configData = try Data(contentsOf: url.appending(path: "config.json"))
        let config = try JSONDecoder().decode(Config.self, from: configData)

        let channelURLs = try FileManager.default.contentsOfDirectory(at: url.appending(path: "channels"), includingPropertiesForKeys: nil)
        var channels: [Channel] = []
        for url in channelURLs {
            let channelData = try Data(contentsOf: url)
            let channel = try JSONDecoder().decode(Channel.self, from: channelData)
            channels.append(channel)
        }
        return .init(config: config, channels: channels)
    }

    public func write(url: URL) throws -> [(URL, Data)] {
        var out = [(URL, Data)]()

        // Encode config
        let configData = try JSONEncoder().encode(config)
        let configURL = url.appending(path: "config.json")
        out.append((configURL, configData))

        // Encode channels
        let channelsURL = url.appending(path: "channels")
        try FileManager.default.createDirectory(at: channelsURL, withIntermediateDirectories: true)

        for channel in channels {
            let channelData = try JSONEncoder().encode(channel)
            let channelURL = channelsURL.appending(path: "\(channel.id).json")
            out.append((channelURL, channelData))
        }
        return out
    }
}
