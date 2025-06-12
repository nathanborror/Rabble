import Foundation

struct ChatChannel: Identifiable, Hashable {
    let name: String
    let topic: String
    let count: Int

    var id: String { name }
}
