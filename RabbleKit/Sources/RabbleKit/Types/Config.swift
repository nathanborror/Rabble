import Foundation
import SharedKit

public struct Config: Codable, Sendable {
    public var metadata: [String: Value]

    public init() {
        self.metadata = [:]
    }

    func apply(_ config: Config) -> Config {
        var existing = self
        existing.metadata = config.metadata
        return existing
    }
}
