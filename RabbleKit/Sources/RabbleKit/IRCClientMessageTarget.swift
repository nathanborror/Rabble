import NIO
import NIOIRC

public protocol IRCClientMessageTarget: IRCMessageTarget {
}

public extension IRCClientMessageTarget {

    func send(_ command: IRCCommand) {
        let message = IRCMessage(command: command)
        sendMessages([message], promise: nil)
    }
}
