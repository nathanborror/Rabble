import SwiftUI
import RabbleKit

@main
struct RabbleApp: App {
    @State private var state = AppState.shared

    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                List {
                    ForEach(state.files) { file in
                        Button(file.name ?? file.path) {
                            state.selectedFileID = file.id
                        }
                    }
                }
            } detail: {
                SessionView()
            }
            .onAppear {
                Task { await appActive() }
            }
        }
        .environment(state)

        WindowGroup("Channels", id: "channels", for: String.self) { fileID in
            NavigationStack {
                if let fileID = fileID.wrappedValue {
                    ChannelList(fileID: fileID)
                } else {
                    ContentUnavailableView("No Channels", image: "list.bullet.rectangle")
                }
            }
        }
        .environment(state)
    }

    func appActive() async {
        do {
            try await state.ready()
        } catch {
            state.log(error: error)
        }
    }

    func appReset() async {
        state.resetAll()
        await appActive()
    }
}
