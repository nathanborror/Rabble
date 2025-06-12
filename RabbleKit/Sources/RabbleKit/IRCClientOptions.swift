import protocol NIO.EventLoopGroup
import class NIO.MultiThreadedEventLoopGroup

fileprivate let onDemandSharedEventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)

/// Configuration options for the socket connects
open class ConnectOptions : CustomStringConvertible {

    public var eventLoopGroup : EventLoopGroup
    public var hostname       : String?
    public var port           : Int

    public init(hostname: String? = "localhost", port: Int = 80, eventLoopGroup: EventLoopGroup? = nil) {
        self.hostname = hostname
        self.port     = port
        self.eventLoopGroup = eventLoopGroup
        ?? MultiThreadedEventLoopGroup.currentEventLoop
        ?? onDemandSharedEventLoopGroup
    }

    public var description: String {
        var ms = "<\(type(of: self)):"
        appendToDescription(&ms)
        ms += ">"
        return ms
    }

    open func appendToDescription(_ ms: inout String) {
        if let hostname = hostname { ms += " \(hostname):\(port)" }
        else { ms += " \(port)" }
    }
}


import NIOIRC

public let DefaultIRCPort = 6667

/// Configuration options for the IRC client object
open class IRCClientOptions : ConnectOptions {

    open var password: String?
    open var nickname: IRCNickName
    open var userInfo: IRCUserInfo
    open var retryStrategy: IRCRetryStrategyCB?

    public convenience init(nick: String) {
        self.init(nickname: IRCNickName(nick)!)
    }

    public init(port: Int = DefaultIRCPort,
                host: String = "localhost",
                password: String? = nil,
                nickname: IRCNickName,
                userInfo: IRCUserInfo? = nil,
                eventLoopGroup: EventLoopGroup? = nil) {
        self.password = password
        self.nickname = nickname
        self.retryStrategy = nil

        self.userInfo = userInfo ?? IRCUserInfo(username: nickname.stringValue, hostname: host, servername: host, realname: "NIO IRC User")

        super.init(hostname: host, port: port, eventLoopGroup: eventLoopGroup)
    }

    override open func appendToDescription(_ ms: inout String) {
        super.appendToDescription(&ms)
        ms += " \(nickname)"
        ms += " \(userInfo)"
        if password != nil { ms += " pwd" }
        if retryStrategy != nil { ms += " has-retryStrategy-cb" }
    }
}
