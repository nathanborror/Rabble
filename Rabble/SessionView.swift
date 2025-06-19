import SwiftUI
import RabbleKit

struct SessionView: View {
    @Environment(AppState.self) var state
    @Environment(\.openWindow) var openWindow

    @State private var messageText = ""
    @State private var showingNewConnectionForm = false
    @State private var showingChannels = false

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if let fileID = state.selectedFileID, let package: IRC = try? state.filePackage(fileID), let logs = package.session?.logs {
                    ForEach(logs) { log in
                        Text(log.text)
                            .font(.footnote)
                            .fontDesign(.monospaced)
                            .textSelection(.enabled)
                    }
                }
            }
            .padding()
        }
        .background(.background)
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 0) {
                Divider()
                HStack(alignment: .bottom) {
                    TextField("Message", text: $messageText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .padding()
                        .onSubmit {
                            handleSubmit()
                        }

                    Button {
                        handleSubmit()
                    } label: {
                        Image(systemName: "arrow.up")
                            .padding(8)
                            .background(.blue, in: .circle)
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.background)
        }
        .sheet(isPresented: $showingNewConnectionForm) {
            NavigationStack {
                ConnectionForm()
            }
        }
        .toolbar {
            if let fileID = state.selectedFileID {
                ToolbarItem {
                    Button("Channels", systemImage: "number") {
                        openWindow(id: "channels", value: fileID)
                    }
                }
            }
            ToolbarItem {
                Button("New Connection", systemImage: "plus") {
                    showingNewConnectionForm = true
                }
            }
        }
        .onDisappear {
            print("note implemented: disconnect all connections")
        }
    }

    func handleSubmit() {
        guard let fileID = state.selectedFileID else { return }
        state.send(messageText, fileID: fileID)
        messageText = ""
    }

//    static let formatter: DateFormatter = {
//        let out = DateFormatter()
//        out.dateFormat = "yyyy-MM-dd hh:mma"
//        out.locale = Locale(identifier: "en_US_POSIX")
//        return out
//    }()
}

