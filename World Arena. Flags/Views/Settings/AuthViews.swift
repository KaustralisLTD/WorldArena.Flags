import SwiftUI
import AuthenticationServices

struct AuthGatewayView: View {
    enum Mode: String, CaseIterable {
        case login = "Login"
        case register = "Register"
    }

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var mode: Mode = .login
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var loading = false
    @State private var errorText: String?
    @State private var showReset = false
    @State private var googleEmail = ""
    @State private var showGooglePrompt = false
    @State private var passwordVisible = false

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.20), Color.cyan.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Text("⚡️")
                                .font(.system(size: 48))
                            Text(localizationManager.localizedString("Account login title"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                            Text(localizationManager.localizedString("Account login subtitle"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)

                        Picker("", selection: $mode) {
                            Text(localizationManager.localizedString("Login")).tag(Mode.login)
                            Text(localizationManager.localizedString("Register")).tag(Mode.register)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 12)

                        VStack(spacing: 10) {
                            if mode == .register {
                                TextField(localizationManager.localizedString("Username"), text: $username)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .padding(12)
                                    .background(Color.white.opacity(0.85))
                                    .cornerRadius(12)
                            }

                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .textContentType(mode == .login ? .username : .emailAddress)
                                .padding(12)
                                .background(Color.white.opacity(0.85))
                                .cornerRadius(12)

                            HStack {
                                Group {
                                    if passwordVisible {
                                        TextField(localizationManager.localizedString("Password"), text: $password)
                                            .textInputAutocapitalization(.never)
                                            .disableAutocorrection(true)
                                    } else {
                                        SecureField(localizationManager.localizedString("Password"), text: $password)
                                            .textInputAutocapitalization(.never)
                                    }
                                }
                                .textContentType(mode == .login ? .password : .newPassword)
                                .padding(12)
                                Button {
                                    passwordVisible.toggle()
                                } label: {
                                    Image(systemName: passwordVisible ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.secondary)
                                        .font(.system(size: 18))
                                }
                                .padding(.trailing, 8)
                            }
                            .background(Color.white.opacity(0.85))
                            .cornerRadius(12)
                        }
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)

                        if let errorText, !errorText.isEmpty {
                            Text(errorText)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        Button {
                            Task { await submitEmailAuth() }
                        } label: {
                            HStack {
                                if loading {
                                    ProgressView().tint(.white)
                                }
                                Text(mode == .login
                                     ? localizationManager.localizedString("Login")
                                     : localizationManager.localizedString("Create account"))
                                    .fontWeight(.bold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundColor(.white)
                            .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                        }
                        .disabled(loading)

                        if mode == .login {
                            Button(localizationManager.localizedString("Forgot password?")) {
                                showReset = true
                            }
                            .font(.subheadline)
                        }

                        Divider().padding(.vertical, 6)

                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            Task { await handleAppleLogin(result) }
                        }
                        .signInWithAppleButtonStyle(.black)
                        .frame(height: 50)
                        .cornerRadius(10)

                        Button {
                            showGooglePrompt = true
                        } label: {
                            HStack(spacing: 10) {
                                Text("G")
                                    .font(.system(size: 20, weight: .bold))
                                Text(localizationManager.localizedString("Continue with Google"))
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.92))
                            .cornerRadius(12)
                        }

                        if auth.biometricEnabled || auth.hasBiometricRestoreAvailable {
                            Button {
                                Task {
                                    let unlocked = await auth.unlockWithBiometrics()
                                    if unlocked { dismiss() }
                                }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: "faceid")
                                    Text(localizationManager.localizedString("Login with biometrics"))
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString("Close")) { dismiss() }
                }
            }
            .sheet(isPresented: $showReset) { ResetPasswordView() }
            .alert(localizationManager.localizedString("Google login"), isPresented: $showGooglePrompt) {
                TextField("Email", text: $googleEmail)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                Button(localizationManager.localizedString("Continue")) {
                    Task { await loginWithGoogleEmail() }
                }
                Button(localizationManager.localizedString("Cancel"), role: .cancel) { }
            } message: {
                Text(localizationManager.localizedString("Enter Google email"))
            }
        }
    }

    private func submitEmailAuth() async {
        guard !email.isEmpty, !password.isEmpty else { return }
        loading = true
        errorText = nil
        do {
            if mode == .login {
                try await auth.login(email: email, password: password)
            } else {
                try await auth.register(email: email, password: password, username: username)
            }
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func handleAppleLogin(_ result: Result<ASAuthorization, any Error>) async {
        switch result {
        case .failure(let error):
            print("[Auth] Apple Sign In failed: \(error.localizedDescription)")
            if let authError = error as? ASAuthorizationError {
                print("[Auth] Apple ASAuthorizationError code: \(authError.code.rawValue)")
            }
            errorText = error.localizedDescription
        case .success(let authResult):
            guard let credential = authResult.credential as? ASAuthorizationAppleIDCredential else {
                print("[Auth] Apple: credential is not ASAuthorizationAppleIDCredential")
                errorText = "Apple sign in failed. Try again."
                return
            }
            let appleId = credential.user
            let email = credential.email
            let displayName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")
            print("[Auth] Apple credential received, userId: \(appleId.prefix(8))..., email: \(email ?? "nil")")
            do {
                try await auth.loginWithSocial(provider: "apple", providerUserId: appleId, email: email, displayName: displayName.isEmpty ? nil : displayName)
                dismiss()
            } catch {
                print("[Auth] Apple social-login API error: \(error.localizedDescription)")
                if let duelError = error as? DuelAPIError, case .serverError(let body) = duelError {
                    print("[Auth] Server response: \(body.prefix(500))")
                }
                errorText = error.localizedDescription
            }
        }
    }

    private func loginWithGoogleEmail() async {
        let normalized = googleEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard normalized.contains("@") else { return }
        do {
            try await auth.loginWithSocial(provider: "google", providerUserId: normalized, email: normalized, displayName: nil)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
    }
}

struct ChangePasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var repeatPassword = ""
    @State private var currentPasswordVisible = false
    @State private var newPasswordVisible = false
    @State private var repeatPasswordVisible = false
    @State private var loading = false
    @State private var errorText: String?

    var body: some View {
        NavigationView {
            Form {
                passwordRow(
                    label: localizationManager.localizedString("Current password"),
                    text: $currentPassword,
                    visible: $currentPasswordVisible
                )
                passwordRow(
                    label: localizationManager.localizedString("New password"),
                    text: $newPassword,
                    visible: $newPasswordVisible
                )
                passwordRow(
                    label: localizationManager.localizedString("Repeat new password"),
                    text: $repeatPassword,
                    visible: $repeatPasswordVisible
                )

                if let errorText {
                    Text(errorText).foregroundColor(.red)
                }

                Button(localizationManager.localizedString("Save")) {
                    Task { await submit() }
                }
                .disabled(loading || currentPassword.isEmpty || newPassword.count < 6 || newPassword != repeatPassword)
            }
            .navigationTitle(localizationManager.localizedString("Change password"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString("Close")) { dismiss() }
                }
            }
        }
    }

    private func submit() async {
        loading = true
        errorText = nil
        do {
            try await auth.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    @ViewBuilder
    private func passwordRow(label: String, text: Binding<String>, visible: Binding<Bool>) -> some View {
        HStack {
            Group {
                if visible.wrappedValue {
                    TextField(label, text: text)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                } else {
                    SecureField(label, text: text)
                        .textInputAutocapitalization(.never)
                }
            }
            Button {
                visible.wrappedValue = !visible.wrappedValue
            } label: {
                Image(systemName: visible.wrappedValue ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.secondary)
                    .font(.system(size: 18))
            }
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var newPasswordVisible = false
    @State private var requested = false
    @State private var errorText: String?
    @State private var loading = false

    var body: some View {
        NavigationView {
            Form {
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                if requested {
                    TextField(localizationManager.localizedString("Reset code"), text: $code)
                        .keyboardType(.numberPad)
                    HStack {
                        Group {
                            if newPasswordVisible {
                                TextField(localizationManager.localizedString("New password"), text: $newPassword)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField(localizationManager.localizedString("New password"), text: $newPassword)
                                    .textInputAutocapitalization(.never)
                            }
                        }
                        Button {
                            newPasswordVisible.toggle()
                        } label: {
                            Image(systemName: newPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 18))
                        }
                    }
                }
                if let errorText { Text(errorText).foregroundColor(.red) }

                if !requested {
                    Button(localizationManager.localizedString("Send reset code")) {
                        Task { await requestCode() }
                    }.disabled(loading || email.isEmpty)
                } else {
                    Button(localizationManager.localizedString("Reset password")) {
                        Task { await confirmReset() }
                    }.disabled(loading || code.isEmpty || newPassword.count < 6)
                }
            }
            .navigationTitle(localizationManager.localizedString("Reset password"))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(localizationManager.localizedString("Close")) { dismiss() }
                }
            }
        }
    }

    private func requestCode() async {
        loading = true
        errorText = nil
        do {
            let emailSent = try await auth.requestPasswordReset(email: email)
            if emailSent {
                requested = true
            } else {
                errorText = localizationManager.localizedString("No account with this email")
            }
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }

    private func confirmReset() async {
        loading = true
        errorText = nil
        do {
            try await auth.confirmPasswordReset(email: email, code: code, newPassword: newPassword)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
        loading = false
    }
}

