import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                Picker(String(localized: "auth.mode"), selection: $viewModel.mode) {
                    Text(String(localized: "auth.login")).tag(AuthMode.login)
                    Text(String(localized: "auth.register")).tag(AuthMode.register)
                }
                .pickerStyle(.segmented)

                if viewModel.mode == .register {
                    TextField(String(localized: "auth.displayName"), text: $viewModel.displayName)
                }

                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField(String(localized: "auth.password"), text: $viewModel.password)

                Button(viewModel.mode == .register ? String(localized: "auth.register") : String(localized: "auth.login")) {
                    viewModel.submit()
                }
            }
            .navigationTitle(String(localized: "auth.title"))
            .alert(String(localized: "auth.alertTitle"), isPresented: Binding(
                get: { viewModel.statusMessage != nil },
                set: { if !$0 { viewModel.statusMessage = nil } }
            )) {
                Button(String(localized: "common.confirm"), role: .cancel) { viewModel.statusMessage = nil }
            } message: {
                Text(viewModel.statusMessage ?? "")
            }
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(service: MockAuthService()))
}
