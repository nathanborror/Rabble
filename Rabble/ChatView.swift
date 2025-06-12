import SwiftUI
import RabbleKit

struct ChatView: View {

    @State private var manager = ChatManager()
    @State private var messageText = ""
    @State private var showingChannelList = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(manager.messages, id: \.self) { message in
                    Text(message.message)
                        .font(.system(size: 12))
                        .fontDesign(.monospaced)
                        .padding(.horizontal)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Channels", systemImage: "number") {
                    showingChannelList = true
                }
            }
            ToolbarItem {
                if manager.client?.state.isRegistered ?? false {
                    Button("Disconnect", systemImage: "network.slash") {
                        manager.disconnect()
                    }
                } else {
                    Button("Connect", systemImage: "network") {
                        manager.connect()
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                TextField("Message", text: $messageText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        handleSubmit()
                    }

                Button {
                    handleSubmit()
                } label: {
                    Image(systemName: "arrow.up")
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingChannelList) {
            NavigationStack {
                ChannelList(isPresented: $showingChannelList)
                    .frame(width: 500, height: 400)
            }
            .environment(manager)
        }
    }

    func handleSubmit() {
        manager.send(messageText+"\n")
        messageText = ""
    }
}
