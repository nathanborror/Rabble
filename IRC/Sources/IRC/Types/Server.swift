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
}
