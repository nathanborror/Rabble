import Foundation
import Network

@MainActor
@Observable
public final class Client {
    public var sessions: [Session] = []

    private var pool: [UUID: NWConnection] = [:]

    public enum Error: Swift.Error {
        case sessionNotFound
    }

    public init() {}

    public func restore() throws {
        let url = URL.documentsDirectory.appending(path: "sessions.json")
        let data = try Data(contentsOf: url)
        let sessions = try JSONDecoder().decode([Session].self, from: data)
        self.sessions = sessions
    }

    public func save() throws {
        let url = URL.documentsDirectory.appending(path: "sessions.json")
        let data = try JSONEncoder().encode(sessions)
        try data.write(to: url)
    }

    public func session(_ id: UUID) throws -> Session {
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
        try save()
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
                    session.isConnected = true
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
                    if let message = Message(raw: "ERROR: \(error)") {
                        session.messages.append(message)
                    }
                    session.isConnected = false
                case .cancelled:
                    session.isConnected = false
                default:
                    break
                }
                try upsert(session: session)
            }
        }
        pool[session.id]?.start(queue: .main)
    }

    public func send(_ message: String, sessionID: UUID) throws {
        var session = try session(sessionID)
        if let message = Message(raw: message) {
            session.messages.append(message)
        }
        guard let data = message.data(using: .utf8) else { return }
        pool[session.id]?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Error sending message: \(error)")
            }
        })
    }

    public func command(_ command: String, sessionID: UUID) throws {
        try send(command+"\n", sessionID: sessionID)
    }

    public func disconnect(sessionID: UUID) throws {
        var session = try session(sessionID)
        pool[session.id]?.cancel()
        pool[session.id] = nil
        session.isConnected = false
        try upsert(session: session)
    }

    private func listen(sessionID: UUID) throws {
        pool[sessionID]?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                var session = try session(sessionID)
                if let data = content, let message = String(data: data, encoding: .utf8) {
                    let lines = message.components(separatedBy: "\r\n")
                    for line in lines where !line.isEmpty {
                        if let message = Message(raw: line) {
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
