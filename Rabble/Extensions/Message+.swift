import SwiftUI
import RabbleKit

extension IRC.Message {

    var render: some View {
        Group {
            switch command {
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
            default:
                Text("nil")
            }
        }
    }
}
