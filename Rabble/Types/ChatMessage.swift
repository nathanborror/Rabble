import Foundation

struct ChatMessage: Identifiable, Hashable {
    let id = UUID()
    let host: String
    let status: Int
    let user: String
    let message: String
    let created: Date = .now
}
