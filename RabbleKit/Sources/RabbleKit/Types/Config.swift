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

// MARK: - Personalization

extension Config {

    public var userName: String? {
        set { metadata["userName"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["userName"]?.stringValue }
    }

    public var userLocation: String? {
        set { metadata["userLocation"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["userLocation"]?.stringValue }
    }

    public var userBiography: String? {
        set { metadata["userBiography"] = (newValue != nil) ? .string(newValue!) : nil }
        get { metadata["userBiography"]?.stringValue }
    }
}
