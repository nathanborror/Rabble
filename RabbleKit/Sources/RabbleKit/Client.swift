import Foundation
import Network

@MainActor
@Observable
public final class Client {
    public var sessions: [Session] = []

    private var pool: [String: NWConnection] = [:]
    private let sessionsURL = URL.documentsDirectory.appending(path: "sessions.json")

    public enum Error: Swift.Error {
        case sessionNotFound
    }

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
        } catch {
            print(error)
        }
    }

    // Session management

    public func session(_ id: String) throws -> Session {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            throw Error.sessionNotFound
        }
        return sessions[index]
    }

    public func upsert(session: Session) throws {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            let existing = sessions[index]
            sessions[index] = existing.apply(session)
        } else {
            sessions.append(session)
        }
        save()
    }

    public func upsert(message: Message, sessionID: String) throws {
        var session = try session(sessionID)
        session.messages.append(message)
        try upsert(session: session)
    }

    public func connect(session: Session) {
        let endpoint = NWEndpoint.hostPort(host: .init(session.server), port: .init(integerLiteral: session.port))
        pool[session.id] = NWConnection(to: endpoint, using: .tcp)
        pool[session.id]?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                var session = session
                switch state {
                case .ready:
                    session.connected = true
                    // TODO: What is the difference between a nickname and a username?
                    let messages = [
                        "NICK \(session.nickname)\n",
                        "USER \(session.nickname) 0 * :\(session.name)\n",
                    ]
                    for message in messages {
                        do {
                            try self.send(message, sessionID: session.id)
                        } catch {
                            print(error)
                        }
                    }
                    do {
                        try self.listen(sessionID: session.id)
                    } catch {
                        print(error)
                    }
                case .failed(let error):
                    // TODO: Format this correctly
                    if let message = Message.parse("ERROR: \(error)") {
                        session.messages.append(message)
                    }
                    session.connected = false
                case .cancelled:
                    session.connected = false
                default:
                    break
                }
                try upsert(session: session)
            }
        }
        pool[session.id]?.start(queue: .main)
    }

    public func send(_ message: String, sessionID: String) throws {
        var session = try session(sessionID)
        if let message = Message.parse(message) {
            session.messages.append(message)
        }
        guard let data = message.data(using: .utf8) else { return }
        pool[session.id]?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        })
    }

    public func command(_ command: String, sessionID: String) throws {
        try send(command+"\n", sessionID: sessionID)
    }

    public func disconnect(sessionID: String) throws {
        var session = try session(sessionID)
        pool[session.id]?.cancel()
        pool[session.id] = nil
        session.connected = false
        try upsert(session: session)
    }

    private func listen(sessionID: String) throws {
        pool[sessionID]?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                var session = try session(sessionID)
                if let data = content, let message = String(data: data, encoding: .utf8) {
                    let lines = message.components(separatedBy: "\r\n")
                    for line in lines where !line.isEmpty {
                        if let message = Message.parse(line) {
                            session.messages.append(message)
                        }

                        // Handle PINGs
                        if line.hasPrefix("PING ") {
                            let payload = line.trimmingPrefix("PING ")
                            try self.send("PONG \(payload)\n", sessionID: session.id)
                        }
                    }
                }
                if error == nil {
                    try self.listen(sessionID: session.id)
                }
                try upsert(session: session)
            }
        }
    }
}
