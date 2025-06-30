import Testing
@testable import IRC

@MainActor
@Suite("Message Parsing Tests")
struct MessageParsingTests {

    @Test("Welcome Sequence")
    func welcomeSequence() async throws {
        let alice = IRCMockSession.alice

        let expected = [
            ":ergo.test 001 alice :Welcome to the ErgoTest IRC Network nathan",
            ":ergo.test 002 alice :Your host is ergo.test, running version ergo-2.17.0-unreleased-17ed01c1ed18da57",
            ":ergo.test 003 alice :This server was created Fri, 27 Jun 2025 15:19:15 UTC",
            ":ergo.test 004 alice ergo.test ergo-2.17.0-unreleased-17ed01c1ed18da57 BERTZios CEIMRUabefhiklmnoqstuv Iabefhkloqv",
            ":ergo.test 005 alice AWAYLEN=390 BOT=B CASEMAPPING=ascii CHANLIMIT=#:100 CHANMODES=Ibe,k,fl,CEMRUimnstu CHANNELLEN=64 CHANTYPES=# CHATHISTORY=1000 ELIST=U EXCEPTS EXTBAN=,m FORWARD=f INVEX :are supported by this server",
            ":ergo.test 005 alice KICKLEN=390 MAXLIST=beI:100 MAXTARGETS=4 MODES MONITOR=100 MSGREFTYPES=msgid,timestamp NETWORK=ErgoTest NICKLEN=32 PREFIX=(qaohv)~&@%+ SAFELIST SAFERATE STATUSMSG=~&@%+ TARGMAX=NAMES:1,LIST:1,KICK:,WHOIS:1,USERHOST:10,PRIVMSG:4,TAGMSG:4,NOTICE:4,MONITOR:100 :are supported by this server",
            ":ergo.test 005 alice TOPICLEN=390 UTF8ONLY WHOX draft/CHATHISTORY=1000 :are supported by this server",
        ]

        try await alice.connect()
        try await alice.processIncomingString(expected.joined(separator: "\n")+"\n")

        #expect(alice.server.config.host == "ergo.test")
        #expect(alice.server.config.availableUserModes == "BERTZios")
        #expect(alice.server.config.availableChannelModes == "CEIMRUabefhiklmnoqstuv")
    }

    @Test("Join channel")
    func joinChannel() async throws {
        let name = "#random"

        let alice = IRCMockSession.alice
        let expected = [
            ":alice!~u@p7wgw3kynvpai.irc JOIN \(name)",
            ":ergo.test 353 alice = \(name) :@alice",
            ":ergo.test 366 alice \(name) :End of NAMES list",
            ":ergo.test 352 alice \(name) ~u p7wgw3kynvpai.irc ergo.test alice H@ :0 Alice",
            ":ergo.test 315 alice \(name) :End of WHO list",
            ":ergo.test 324 alice \(name) +Cnt",
            ":ergo.test 329 alice \(name) 1751058144",
        ]

        try await alice.channelJoin(name)
        try await alice.processIncomingString(expected.joined(separator: "\n")+"\n")
        #expect(alice.server.channels.count == 1)

        let channel = try alice.getChannel(name)
        #expect(channel.name == name)
        #expect(channel.modes == "+Cnt")
        #expect(channel.users.count == 1)
        #expect(channel.isBlockingCTCPMessages)
        #expect(channel.isNoExternalMessages)
        #expect(channel.isTopicLocked)

        let user = channel.users["alice"]!
        #expect(user.ident == "~u")
        #expect(user.name == "Alice")
        #expect(user.hostname == "p7wgw3kynvpai.irc")
        #expect(user.server == "ergo.test")
        #expect(user.hops == 0)
        #expect(user.membership == .op)
        #expect(user.status == .online)
    }

    @Test("Join secret keyed channel")
    func joinKeyedChannel() async throws {
        let name = "#private"

        let alice = IRCMockSession.alice
        let expected = [
            ":alice!~u@p7wgw3kynvpai.irc JOIN \(name)",
            ":ergo.test 353 alice = \(name) :@alice",
            ":ergo.test 366 alice \(name) :End of NAMES list",
            ":ergo.test 324 alice \(name) +kCnst s3cr3t",
            ":ergo.test 329 alice \(name) 1751134868",
            ":ergo.test 341 alice bob \(name)",
        ]
        try await alice.channelJoin(name)
        try await alice.processIncomingString(expected.joined(separator: "\n")+"\n")
        #expect(alice.server.channels.count == 1)

        let channel = try alice.getChannel(name)
        #expect(channel.modes == "+kCnst")
        #expect(channel.users.count == 2)
        #expect(channel.isKeyed)
        #expect(channel.isSecret)

        let bob = IRCMockSession.bob
        let expectedForBob = [
            ":alice!~u@p7wgw3kynvpai.irc INVITE bob \(name)",
            ":bob!~u@p7wgw3kynvpai.irc JOIN \(name)",
            ":ergo.test 353 bob @ \(name) :@alice bob",
            ":ergo.test 366 bob \(name) :End of NAMES list",
            ":ergo.test 324 bob \(name) +kCnst s3cr3t",
            ":ergo.test 329 bob \(name) 1751134868",
        ]
        try await bob.processIncomingString(expectedForBob.joined(separator: "\n")+"\n")
        #expect(bob.server.channels.count == 1)

        let bobChannel = try bob.getChannel(name)
        #expect(bobChannel.modes == "+kCnst")
        #expect(bobChannel.key == "s3cr3t")
        #expect(bobChannel.users.count == 2)
    }

    @Test("Kick from channel")
    func kickFromChannel() async throws {
        let name = "#general"

        let alice = IRCMockSession.alice
        let expected = [
            ":alice!~u@p7wgw3kynvpai.irc JOIN \(name)",
            ":ergo.test 353 alice = \(name) :@alice",
            ":ergo.test 366 alice \(name) :End of NAMES list",
            ":ergo.test 324 alice \(name) +Cnt",
            ":ergo.test 329 alice \(name) 1751134868",
            ":alice!~u@p7wgw3kynvpai.irc JOIN #general",
            ":ergo.test 353 alice = #general :@bob alice",
            ":bob!~u@p7wgw3kynvpai.irc KICK #general alice :bye bye",
        ]
        try await alice.channelJoin(name)
        try await alice.processIncomingString(expected.joined(separator: "\n")+"\n")

        #expect(alice.server.channels.count == 0)
    }
}
