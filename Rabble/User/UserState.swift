import Foundation

@MainActor
@Observable
final class UserState {

    var nick: String
    var realname: String

    init(nick: String, realname: String) {
        self.nick = nick
        self.realname = realname
    }
}
