import Foundation
import IRC

extension IRC.Server: Packagable {

    public static func load(url: URL) throws -> Self {
        // Decode config
        let configData = try Data(contentsOf: url.appending(path: "config.json"))
        let config = try JSONDecoder().decode(IRC.Config.self, from: configData)

        // Decode logs
        let logData = try String(contentsOf: url.appending(path: "logs"), encoding: .utf8)
        let logs = logData.components(separatedBy: .newlines).filter { !$0.isEmpty }

        // Decode channels
        let channelURLs = try FileManager.default.contentsOfDirectory(at: url.appending(path: "channels"), includingPropertiesForKeys: nil)
        var channels: [Channel] = []
        for url in channelURLs {
            let channelData = try Data(contentsOf: url)
            let channel = try JSONDecoder().decode(IRC.Channel.self, from: channelData)
            channels.append(channel)
        }
        return .init(config: config, logs: logs, channels: channels)
    }

    public func write(url: URL) throws -> [(URL, Data)] {
        var out = [(URL, Data)]()

        // Encode config
        let configData = try JSONEncoder().encode(config)
        let configURL = url.appending(path: "config.json")
        out.append((configURL, configData))

        // Encode logs
        let logData = logs.joined(separator: "\n").data(using: .utf8)!
        let logURL = url.appending(path: "logs")
        out.append((logURL, logData))

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
