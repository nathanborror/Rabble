<img src="Images/Animals.png" width="256">

# Rabble

An experimental IRC client written in pure Swift.

## Resources

[Documentation](https://modern.ircdocs.horse)
[Numerics](https://www.alien.net.au/irc/irc2numerics.html)

## Tasks

- [ ] Show error messages in timeline
- [ ] Show disconnection messages in timeline
- [ ] Sidebar to show channels
- [ ] Channel view
- [ ] Channel message timeline
- [ ] Some sort of command palette
- [x] Connection pool

## File Structure

~/
├─ <HOST_ID>.irc/
│ ├─ init.json
│ ├─ <CHANNEL_ID>.json
│ ├─ <CHANNEL_ID>.json
│ └─ ...
├─ <HOST_ID>.irc/
├─ <HOST_ID>.irc/
└─ ...

IRC sessions are stored as packages which contain files that maintain the state of the session (e.g. configuration, channel history, session logs).
