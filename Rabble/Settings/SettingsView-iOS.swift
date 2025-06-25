import SwiftUI
import SharedKit
import GenKit
import RabbleKit

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            NavigationLink("Services") {
                ServicesView()
            }
            NavigationLink("Instructions") {
                InstructionsView()
            }
            NavigationLink("Tools") {
                ContentUnavailableView("Not Implemented", systemImage: "ellipsis.curlybraces")
            }
            NavigationLink("Permissions") {
                PermissionsView()
            }
        }
        .navigationTitle("Settings")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}
