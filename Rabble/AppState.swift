import SwiftUI
import OSLog
import UniformTypeIdentifiers
import IRC

private let logger = Logger(subsystem: "AppState", category: "App")

@MainActor
@Observable
final class AppState {
    static let shared = AppState()

    var selection: Selection? = nil
    var servers: [String: ServerState] = [:]
    var showingServerForm = false

    struct Selection: Codable, Hashable {
        var server: String
        var channel: String?
        var nick: String?

        init(server: String, channel: String? = nil, nick: String? = nil) {
            self.server = server
            self.channel = channel
            self.nick = nick
        }
    }

    private init() {
        logger.info("🍱 \(URL.documentsDirectory.path())")
    }

    func ready() async throws {
        print("not implemented")
    }

    func resetAll() async throws {
        servers = [:]
        selection = nil
    }

    func save() async throws {
        print("not implemented")
    }

    // MARK: - IRC

    func serverCreate(_ server: String, port: Int, useTLS: Bool, nick: String, username: String, realname: String) {
        let config = Config(sections: [
            "core": .dictionary([
                "server": server,
                "port": "\(port)",
                "useTLS": "\(useTLS)",
                "nick": nick,
                "username": username,
                "realname": realname,
            ])
        ])
        let transport = NWTransport()
        let serverState = ServerState(config: config, transport: transport)

        servers[server] = serverState
        selection = .init(server: server)

        // Connect to server
        serverState.connect()
    }

    func serverDelete(_ key: String) {
        servers.removeValue(forKey: key)
        if selection?.server == key {
            selection = nil
        }
    }
}
