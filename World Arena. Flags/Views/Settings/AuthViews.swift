import SwiftUI
import AuthenticationServices
#if os(iOS)
import UIKit
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

private struct AuthScrollDismissKeyboardModifier: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, *) {
            content.scrollDismissesKeyboard(.interactively)
        } else {
            content
        }
    }
}

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
    @State private var isGoogleSigningIn = false
    @Environment(\.colorScheme) private var colorScheme

    private var fieldBackground: Color {
        #if os(iOS)
        return Color(UIColor.tertiarySystemFill)
        #else
        return Color(NSColor.controlBackgroundColor)
        #endif
    }

    private func modeTitle(_ m: Mode) -> String {
        switch m {
        case .login: return localizationManager.localizedString("Login")
        case .register: return localizationManager.localizedString("Register")
        }
    }

    @ViewBuilder
    private func modeChoiceButton(_ m: Mode) -> some View {
        let selected = mode == m
        Button {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                mode = m
            }
        } label: {
            Text(modeTitle(m))
                .font(.system(size: 19, weight: .semibold, design: .rounded))
                .tracking(0.2)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 56)
                .foregroundStyle(selected ? Color.white : Color.primary)
                .background {
                    if selected {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.22, green: 0.45, blue: 0.95), Color(red: 0.45, green: 0.28, blue: 0.92)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: Color.blue.opacity(0.35), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(fieldBackground.opacity(colorScheme == .dark ? 0.55 : 0.9))
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            selected ? Color.white.opacity(0.25) : Color.primary.opacity(0.06),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var authGatewayRoot: some View {
        ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.25), Color.purple.opacity(0.20), Color.cyan.opacity(0.18)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 48))
                            Text(localizationManager.localizedString("Account login title"))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text(localizationManager.localizedString("Account login subtitle"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 12)

                        HStack(spacing: 10) {
                            modeChoiceButton(.login)
                            modeChoiceButton(.register)
                        }
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.08), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, 12)

                        VStack(spacing: 10) {
                            if mode == .register {
                                TextField(localizationManager.localizedString("Username"), text: $username)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                                    .foregroundColor(.primary)
                                    .padding(12)
                                    .background(fieldBackground)
                                    .cornerRadius(12)
                            }

                            TextField("Email", text: $email)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .textContentType(mode == .login ? .username : .emailAddress)
                                .foregroundColor(.primary)
                                .padding(12)
                                .background(fieldBackground)
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
                                .foregroundColor(.primary)
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
                            .background(fieldBackground)
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
                            HStack(spacing: 10) {
                                if loading {
                                    ProgressView().tint(.white)
                                }
                                Text(mode == .login
                                     ? localizationManager.localizedString("Login")
                                     : localizationManager.localizedString("Create account"))
                                    .font(.system(size: 18, weight: .bold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .foregroundColor(.white)
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(loading)
                        .buttonStyle(.plain)

                        if mode == .login {
                            Button(localizationManager.localizedString("Forgot password?")) {
                                showReset = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        }

                        Divider().padding(.vertical, 6)

                        SignInWithAppleButton(.continue) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            Task { await handleAppleLogin(result) }
                        }
                        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                        .frame(height: 54)
                        .cornerRadius(14)

                        Button {
                            Task { await startGoogleSignInFlow() }
                        } label: {
                            HStack(spacing: 10) {
                                Text("G")
                                    .font(.system(size: 20, weight: .bold))
                                Text(localizationManager.localizedString("Continue with Google"))
                                    .font(.system(size: 17, weight: .semibold))
                            }
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(fieldBackground)
                            .cornerRadius(14)
                        }
                        .disabled(isGoogleSigningIn || loading)

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
                                        .font(.system(size: 16, weight: .semibold))
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(fieldBackground)
                                .cornerRadius(14)
                            }
                        }
                    }
                    .padding(16)
                }
                .modifier(AuthScrollDismissKeyboardModifier())
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

    var body: some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    authGatewayRoot
                }
            } else {
                NavigationView {
                    authGatewayRoot
                }
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
                if authError.code.rawValue == 1000 {
                    errorText = localizationManager.localizedString("Sign in with Apple error 1000")
                    return
                }
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

    @MainActor
    private func startGoogleSignInFlow() async {
        #if canImport(GoogleSignIn) && os(iOS)
        guard !isGoogleSigningIn else { return }
        isGoogleSigningIn = true
        defer { isGoogleSigningIn = false }

        func topMostViewController() -> UIViewController? {
            let scenes = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .filter { $0.activationState == .foregroundActive }
            let window = scenes
                .flatMap(\.windows)
                .first(where: { $0.isKeyWindow }) ?? scenes.flatMap(\.windows).first
            var top = window?.rootViewController
            while let presented = top?.presentedViewController {
                top = presented
            }
            return top
        }

        guard let presentingVC = topMostViewController() else {
            showGooglePrompt = true
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingVC)
            let user = result.user
            let providerUserId = user.userID ?? user.profile?.email.lowercased() ?? UUID().uuidString
            let email = user.profile?.email
            let name = user.profile?.name
            try await auth.loginWithSocial(provider: "google", providerUserId: providerUserId, email: email, displayName: name)
            dismiss()
        } catch {
            errorText = error.localizedDescription
        }
        #else
        // fallback, если SDK GoogleSignIn не подключён в проекте
        showGooglePrompt = true
        #endif
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
                    visible: $currentPasswordVisible,
                    contentType: .password
                )
                passwordRow(
                    label: localizationManager.localizedString("New password"),
                    text: $newPassword,
                    visible: $newPasswordVisible,
                    contentType: .newPassword
                )
                passwordRow(
                    label: localizationManager.localizedString("Repeat new password"),
                    text: $repeatPassword,
                    visible: $repeatPasswordVisible,
                    contentType: .newPassword
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
    private func passwordRow(label: String, text: Binding<String>, visible: Binding<Bool>, contentType: UITextContentType = .password) -> some View {
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
            .textContentType(contentType)
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
                        .textContentType(.newPassword)
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

