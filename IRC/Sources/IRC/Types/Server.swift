import Foundation

public struct Server: Identifiable, Codable, Sendable {
    public var id: String
    public var config: Config
    public var logs: [String]
    public var channels: [Channel]
    public var channelList: [ChannelRef]

    public init(id: String = UUID().uuidString, config: Config, logs: [String] = [], channels: [Channel] = [],
                channelList: [ChannelRef] = []) {
        self.id = id
        self.config = config
        self.logs = logs
        self.channels = channels
        self.channelList = channelList
    }
}
