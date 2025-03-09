import SwiftUI

struct LoginView: View {
    @StateObject private var authService = AuthService.shared
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isRegistering = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var rememberMe = false
    @State private var showBiometricButton = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.blue)
                            .padding(.bottom, 20)
                        
                        if !isRegistering {
                            if showBiometricButton {
                                Button(action: biometricLogin) {
                                    Label(
                                        BiometricAuthUtil.shared.biometricType == .faceID ? "Face ID 登录" : "Touch ID 登录",
                                        systemImage: BiometricAuthUtil.shared.biometricType == .faceID ? "faceid" : "touchid"
                                    )
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                                }
                                .disabled(isLoading)
                            }
                        }
                        
                        if isRegistering {
                            registerView
                        } else {
                            loginView
                        }
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.immediately)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.2))
                }
            }
            .alert("错误", isPresented: $showError) {
                Button("确定", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .navigationTitle(isRegistering ? "注册" : "登录")
            .onAppear {
                checkBiometricAvailability()
            }
        }
    }
    
    private var loginView: some View {
        VStack {
            TextField("用户名", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .textContentType(.username)
            
            SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(isRegistering ? .newPassword : .password)
            
            if !isRegistering {
                Toggle("记住我", isOn: $rememberMe)
                    .padding(.vertical, 5)
            }
            
            Button(action: {
                Task {
                    await handleLoginRegister()
                }
            }) {
                Text("登录")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading || username.isEmpty || password.isEmpty)
            
            Button(action: {
                isRegistering.toggle()
                clearFields()
            }) {
                Text("没有账号？注册")
                    .foregroundColor(.blue)
            }
            .padding(.top, 10)
        }
    }
    
    private var registerView: some View {
        VStack {
            TextField("用户名", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.none)
                .textContentType(.username)
            
            SecureField("密码", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(isRegistering ? .newPassword : .password)
            
            SecureField("确认密码", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.newPassword)
            
            Button(action: {
                Task {
                    await handleLoginRegister()
                }
            }) {
                Text("注册")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .disabled(isLoading || username.isEmpty || password.isEmpty || confirmPassword.isEmpty)
            
            Button(action: {
                isRegistering.toggle()
                clearFields()
            }) {
                Text("已有账号？登录")
                    .foregroundColor(.blue)
            }
            .padding(.top, 10)
        }
    }
    
    private func checkBiometricAvailability() {
        showBiometricButton = BiometricAuthUtil.shared.biometricType != .none
    }
    
    private func biometricLogin() {
        Task {
            await handleBiometricLogin()
        }
    }
    
    private func handleBiometricLogin() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await authService.loginWithBiometric()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
    
    private func handleLoginRegister() async {
        if isRegistering {
            // 验证密码匹配
            guard password == confirmPassword else {
                showError = true
                errorMessage = "两次输入的密码不匹配"
                return
            }
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            if isRegistering {
                try await authService.register(username: username, password: password)
                print("注册成功: \(username)")
            } else {
                try await authService.login(username: username, password: password, rememberMe: rememberMe)
                print("登录成功: \(username)")
            }
            clearFields()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
            print("错误: \(error.localizedDescription)")
        }
    }
    
    private func clearFields() {
        username = ""
        password = ""
        confirmPassword = ""
    }
}

#Preview {
    LoginView()
}
