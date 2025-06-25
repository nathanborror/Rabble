import Foundation
import SharedKit

public struct IRCServer: Packagable {
    public var id: String
    public var config: IRCConfig
    public var channels: [IRCChannel]

    public init(id: String = .id, config: IRCConfig, channels: [IRCChannel] = []) {
        self.id = id
        self.config = config
        self.channels = channels
    }

    public static func load(url: URL) throws -> Self {
        let configData = try Data(contentsOf: url.appending(path: "config.json"))
        let config = try JSONDecoder().decode(IRCConfig.self, from: configData)

        let channelURLs = try FileManager.default.contentsOfDirectory(at: url.appending(path: "channels"), includingPropertiesForKeys: nil)
        var channels: [IRCChannel] = []
        for url in channelURLs {
            let channelData = try Data(contentsOf: url)
            let channel = try JSONDecoder().decode(IRCChannel.self, from: channelData)
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
