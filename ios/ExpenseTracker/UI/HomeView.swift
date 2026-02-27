import SwiftUI

struct HomeView: View {
    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Expense Tracker")
                .font(.title)

            Text("MVP-0: empty home screen")
                .foregroundStyle(.secondary)

            Button("Go to Settings", action: onOpenSettings)
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationTitle("Home")
    }
}

#Preview {
    HomeView(onOpenSettings: {})
}
