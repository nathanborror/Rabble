import SwiftUI
import RabbleKit

extension IRC.Message {

    var render: some View {
        Group {
            switch command {
            case .connected:
                Text("Connected".uppercased())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.green)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 4))
            case .disconnected:
                Text("Disconnected".uppercased())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.red)
                    .foregroundStyle(.white)
                    .clipShape(.rect(cornerRadius: 4))
            case .privmsg:
                HStack {
                    if let prefix {
                        switch prefix {
                        case .user(let text):
                            Text(text)
                                .fontWeight(.semibold)
                        case .server(let text):
                            Text(text)
                        case .service(let text):
                            Text(text)
                        }
                    }
                    Text(params[1])
                }
            case .numeric(let numeric):
                switch numeric {
                case .RPL_MOTD:
                    Text(params[1])
                case .RPL_MOTDSTART:
                    Text("<MOTD>").foregroundStyle(.secondary)
                case .RPL_ENDOFMOTD:
                    Text("</MOTD>").foregroundStyle(.secondary)
                case .UNKNOWN:
                    Text("\(self)")
                        .foregroundStyle(.red)
                default:
                    Text("not handled")
                }
            case .unknown:
                Text("unknown")
                    .foregroundStyle(.red)
            default:
                Text("nil")
            }
        }
    }
}
