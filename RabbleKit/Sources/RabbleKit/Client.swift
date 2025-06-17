import Foundation
import Network

@MainActor
@Observable
public final class Client {

    public var sessions: [IRC.Session] = []

    private var pool: [String: NWConnection] = [:]
    private let sessionsURL = URL.documentsDirectory.appending(path: "sessions.json")

    public init() {}

    // State management

    public func restore() {
        do {
            let data = try Data(contentsOf: sessionsURL)
            let sessions = try JSONDecoder().decode([IRC.Session].self, from: data)
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

    // Session state

    public func session(_ id: String) -> IRC.Session? {
        guard let index = sessions.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return sessions[index]
    }

    public func upsert(session: IRC.Session) {
        if let index = sessions.firstIndex(where: { $0.id == session.id }) {
            let existing = sessions[index]
            sessions[index] = existing.apply(session)
        } else {
            sessions.append(session)
        }
    }

    public func upsert(line: String, sessionID: String) {

        // Append line to session
        guard var session = session(sessionID) else {
            return
        }
        session.log.append(.init(line))
        upsert(session: session)

        // Parse line as message
        guard let message = IRC.parseServerMessage(line) else {
            return
        }
        apply(message: message, sessionID: sessionID)
    }

    public func upsert(connected: Bool, sessionID: String) {
        guard var session = session(sessionID) else { return }
        session.connected = connected
        upsert(session: session)
    }

    public func upsert(join channel: IRC.Channel, sessionID: String) {
        guard var session = session(sessionID) else { return }
        if let index = session.joined.firstIndex(where: { $0.id == channel.id }) {
            session.joined[index] = channel
        } else {
            session.joined.append(channel)
        }
        upsert(session: session)
    }

    public func upsert(list ref: IRC.ChannelRef, sessionID: String) {
        guard var session = session(sessionID) else { return }
        if let index = session.list.firstIndex(where: { $0.id == ref.id }) {
            session.list[index] = ref
        } else {
            session.list.append(ref)
        }
        upsert(session: session)
    }

    // Session networking

    public func connect(_ session: IRC.Session) {
        upsert(session: session)

        let endpoint = NWEndpoint.hostPort(host: .init(session.server), port: .init(integerLiteral: session.port))
        pool[session.id] = NWConnection(to: endpoint, using: .tcp)
        pool[session.id]?.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            Task { @MainActor in
                switch state {
                case .ready:
                    upsert(connected: true, sessionID: session.id)

                    // TODO: What is the difference between a nickname and a username?
                    let messages = [
                        "NICK \(session.nick)",
                        "USER \(session.nick) 0 * :\(session.name)",
                    ]
                    for message in messages {
                        send(message, sessionID: session.id)
                    }
                    listen(sessionID: session.id)
                case .failed(let error):
                    print(error)
                    disconnect(session.id)
                case .cancelled:
                    upsert(connected: false, sessionID: session.id)
                    disconnect(session.id)
                default:
                    break
                }
            }
        }
        pool[session.id]?.start(queue: .main)
    }

    public func disconnect(_ sessionID: String) {

        // Update session pool
        pool[sessionID]?.cancel()
        pool[sessionID] = nil

        // Update session
        upsert(connected: false, sessionID: sessionID)
    }

    public func send(_ input: String, sessionID: String) {

        // Required, IRC is a line-oriented protocol
        let input = input+"\r\n"

        // Send input to server session
        guard let data = input.data(using: .utf8) else { return }
        pool[sessionID]?.send(content: data, completion: .contentProcessed { error in
            guard let error else { return }
            print(error)
        })
    }

    // Private

    private func listen(sessionID: String) {
        pool[sessionID]?.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self else { return }
            Task { @MainActor in
                handleIncomingData(data, sessionID: sessionID)
                if error == nil {
                    listen(sessionID: sessionID)
                }
            }
        }
    }

    private var buffer = ""

    func handleIncomingData(_ data: Data?, sessionID: String) {
        guard let data, let newText = String(data: data, encoding: .utf8) else { return }
        buffer += newText

        while let range = buffer.range(of: "\r\n") {
            let line = String(buffer[..<range.lowerBound])
            buffer = String(buffer[range.upperBound...]) // Remove parsed line + delimiter

            // Upsert new line to session object
            upsert(line: line, sessionID: sessionID)

            // Respond to periodic PINGs to maintain the connection
            if line.hasPrefix("PING ") {
                let payload = line.trimmingPrefix("PING ")
                send("PONG \(payload)", sessionID: sessionID)
            }
        }
    }

    private func apply(message: IRC.Message, sessionID: String) {
        guard case .numeric(let numeric) = message.command else {
            return
        }
        switch numeric {
        case .RPL_LIST:
            guard message.params.count >= 4 else {
                return
            }
            let name = message.params[1]
            let users = Int(message.params[2]) ?? 0
            let topic = message.params[3].isEmpty ? nil : message.params[3]
            guard name != "*" else {
                return
            }
            let ref = IRC.ChannelRef(name: name, users: users, topic: topic)
            upsert(list: ref, sessionID: sessionID)
        default:
            return
        }
    }
}
