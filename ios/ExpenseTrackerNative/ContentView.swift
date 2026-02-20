import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 56))
                    .foregroundStyle(.green)
                Text("Expense Tracker Native")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("MVP-0 iOS skeleton is buildable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Dashboard")
        }
    }
}

#Preview {
    ContentView()
}
