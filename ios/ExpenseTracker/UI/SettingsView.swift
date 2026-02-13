import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("About") {
                LabeledContent("Version", value: "0.0.1")
            }
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack { SettingsView() }
}
