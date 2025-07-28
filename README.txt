
██████   █████  ██████  ██████  ██      ███████
██   ██ ██   ██ ██   ██ ██   ██ ██      ██
██████  ███████ ██████  ██████  ██      █████
██   ██ ██   ██ ██   ██ ██   ██ ██      ██
██   ██ ██   ██ ██████  ██████  ███████ ███████

An experimental IRC client written in pure Swift.

IRC sessions are stored as packages which contain files that maintain the state of the session (e.g. configuration, channel history, session logs).

File Structure:

~/
├─ <HOST_ID>.irc/
│ ├─ init.json
│ ├─ <CHANNEL_ID>.json
│ ├─ <CHANNEL_ID>.json
│ └─ ...
├─ <HOST_ID>.irc/
├─ <HOST_ID>.irc/
└─ ...

Local IRC Server:

Checkout the latest version of Ergo and run the following get get it up and running:

    cd ergo
    make
    cp default.yaml ircd.yaml
    ./ergo mkcerts
    ./ergo run

Registering Account:

    PRIVMSG NickServ :REGISTER <password> <email>
    PRIVMSG NickServ :IDENTIFY <nick> <password>

Register a channel and grant yourself auto-operator status upon joining. Must be authenticated:

    PRIVMSG ChanServ :REGISTER #channel <password> "<description>"
    PRIVMSG ChanServ :SET #channel MLOCK +nt
    PRIVMSG ChanServ :FLAGS #channel <nick> +Ao

Retrieving Channel History:

    CHATHISTORY LATEST #channel * 20

Tasks:

- [x] Sidebar to show channels
- [x] Channel view
- [x] Channel message timeline
- [x] Connection pool
- [x] Re-join rooms upon reconnecting
- [x] Enable echo-message on every connection
- [ ] Show disconnection messages in timeline
- [ ] Show error messages in timeline
- [ ] Some sort of command palette
- [ ] Show notices in channels
- [ ] Store base64 token instead of raw password
- [ ] Figure out nick registration
- [ ] Figure out channel registration
- [ ] Packagable write() needs to remove files
- [ ] Check message.prefix (user and host) when reacting to commands
- [ ] Make handleIncomingData something all IRCSession implementations can use

Resources:

- Documentation (https://modern.ircdocs.horse)
- Numerics (https://www.alien.net.au/irc/irc2numerics.html)
- Ergo (https://github.com/ergochat/ergo)
