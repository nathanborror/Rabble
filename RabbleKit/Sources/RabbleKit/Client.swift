import Foundation
import Network

@MainActor
@Observable
public final class Client {
    public var sessions: [Session] = []

    private var pool: [String: NWConnection] = [:]
    private let sessionsURL = URL.documentsDirectory.appending(path: "sessions.json")

    public init() {}

    // State management

    public func restore() {
        do {
            let data = try Data(contentsOf: sessionsURL)
            let sessions = try JSONDecoder().decode([Session].self, from: data)
            self.sessions = sessions
        } catch {
            print(error)
        }
    }

    public func save() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: sessionsURL)
        } catch {
            print(error)
        }
    }

    public func reset() {
        do {
            try FileManager.default.removeItem(at: sessionsURL)
            sessions = []
            pool = [:]
        } catch {
            print(error)
        }
    }

    public func regenerate() {
        let sessions = sessions.map { $0.regenerate() }
        self.sessions = sessions
        save()
    }

    // Session management

    public func session(_ id: String) -> Session? {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return sessions[index]
    }

    public func upsert(session: Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            let existing = sessions[index]
            sessions[index] = existing.apply(session)
        } else {
            sessions.append(session)
        }
    }

    public func upsert(message: Message, sessionID: String) {
        guard var session = session(sessionID) else { return }
        session.messages.append(message)
        upsert(session: session)
    }

    public func upsert(connected: Bool, sessionID: String) {
        guard var session = session(sessionID) else { return }
        session.connected = connected
        upsert(session: session)
    }

    public func connect(_ session: Session) {
        upsert(session: session)

        let endpoint = NWEndpoint.hostPort(host: .init(session.server), port: .init(integerLiteral: session.port))
        pool[session.id] = NWConnection(to: endpoint, using: .tcp)
        pool[session.id]?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                switch state {
                case .ready:
                    upsert(connected: true, sessionID: session.id)
                    upsert(message: .init(kind: .client, command: .connected), sessionID: session.id)

                    // TODO: What is the difference between a nickname and a username?
                    let messages = [
                        "NICK \(session.nickname)",
                        "USER \(session.nickname) 0 * :\(session.name)",
                    ]
                    for message in messages {
                        send(message, sessionID: session.id)
                    }
                    listen(sessionID: session.id)
                case .failed(let error):
                    upsert(message: .init(kind: .client, command: .error("\(error)")), sessionID: session.id)
                    disconnect(sessionID: session.id)
                case .cancelled:
                    upsert(connected: false, sessionID: session.id)
                    disconnect(sessionID: session.id)
                default:
                    break
                }
            }
        }
        pool[session.id]?.start(queue: .main)
    }

    public func send(_ input: String, sessionID: String) {
        let input = input+"\r\n" // required, IRC is a line-oriented protocol
        if let message = Message.user(input) {
            upsert(message: message, sessionID: sessionID)
        }
        // Send input to server session
        guard let data = input.data(using: .utf8) else { return }
        pool[sessionID]?.send(content: data, completion: .contentProcessed { error in
            guard let error else { return }
            Task { await self.upsert(message: .init(kind: .client, command: .error("\(error)")), sessionID: sessionID) }
        })
    }

    public func disconnect(sessionID: String) {

        // Update session pool
        pool[sessionID]?.cancel()
        pool[sessionID] = nil

        // Update session
        upsert(message: .init(kind: .client, command: .disconnected), sessionID: sessionID)
        upsert(connected: false, sessionID: sessionID)
    }

    private func listen(sessionID: String) {
        pool[sessionID]?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                if let data = content, let message = String(data: data, encoding: .utf8) {
                    let lines = message.components(separatedBy: "\r\n")
                    for line in lines where !line.isEmpty {
                        if let message = Message.server(line) {
                            upsert(message: message, sessionID: sessionID)
                        }
                        if line.hasPrefix("PING ") { // maintain connection
                            let payload = line.trimmingPrefix("PING ")
                            send("PONG \(payload)", sessionID: sessionID)
                        }
                    }
                }
                if error == nil {
                    listen(sessionID: sessionID)
                }
            }
        }
    }
}
