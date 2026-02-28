import SwiftUI

struct AuthView: View {
    @ObservedObject var viewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            Form {
                Picker("模式", selection: $viewModel.mode) {
                    Text("登入").tag(AuthMode.login)
                    Text("註冊").tag(AuthMode.register)
                }
                .pickerStyle(.segmented)

                if viewModel.mode == .register {
                    TextField("顯示名稱", text: $viewModel.displayName)
                }

                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                SecureField("密碼", text: $viewModel.password)

                Button(viewModel.mode == .register ? "註冊" : "登入") {
                    viewModel.submit()
                }
            }
            .navigationTitle("帳號")
            .alert("Auth", isPresented: Binding(
                get: { viewModel.statusMessage != nil },
                set: { if !$0 { viewModel.statusMessage = nil } }
            )) {
                Button("確定", role: .cancel) { viewModel.statusMessage = nil }
            } message: {
                Text(viewModel.statusMessage ?? "")
            }
        }
    }
}

#Preview {
    AuthView(viewModel: AuthViewModel(service: MockAuthService()))
}
