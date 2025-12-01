//
//  LoginView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showSignUpSheet = false
    @State private var showUserNotFoundAlert = false
    @State private var showWrongPasswordAlert = false
    @State private var showUnknownErrorAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [AppColors.background, AppColors.secondary.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(AppColors.primary)

                            Text("Welcome Back")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Sign in to save your memories")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.top, 40)

                        // Form
                        VStack(spacing: 20) {
                            // Email Field
                            NostalgicTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                keyboardType: .emailAddress
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            // Password Field
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.textSecondary)

                                if showPassword {
                                    TextField("Password", text: $password)
                                        .font(.system(size: 18))
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Password", text: $password)
                                        .font(.system(size: 18))
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }

                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(AppColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, Constants.Layout.paddingMedium)
                            .padding(.vertical, Constants.Layout.paddingMedium)
                            .background(
                                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                            )

                            // Forgot Password
                            Button(action: {
                                // Handle forgot password
                            }) {
                                Text("Forgot Password?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Sign In Button
                        AnimatedButton(
                            title: "Sign In",
                            icon: "arrow.right",
                            action: handleSignIn,
                            style: .primary,
                            isLoading: isLoading
                        )
                        .disabled(!isFormValid)

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)

                            Text("or")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .padding(.horizontal, 12)

                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }

                        // Sign in with Apple (Placeholder)
                        Button(action: {
                            Task {
                                do {
                                    _ = try await authService.signInWithApple()
                                    dismiss()
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showError = true
                                }
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20))
                                Text("Continue with Apple")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: Constants.Layout.buttonHeight)
                            .background(Color.black)
                            .cornerRadius(Constants.Layout.cornerRadiusMedium)
                        }

                        // Don't have an account?
                        HStack(spacing: 4) {
                            Text("Don't have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)

                            Button(action: {
                                showSignUpSheet = true
                            }) {
                                Text("Sign Up")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.primary)
                            }
                        }
                        .padding(.top, 8)

                        Spacer()
                    }
                    .padding(Constants.Layout.paddingLarge)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .sheet(isPresented: $showSignUpSheet) {
                SignUpView()
                    .environmentObject(authService)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("No Account Found", isPresented: $showUserNotFoundAlert) {
                Button("Sign Up", role: .none) {
                    showSignUpSheet = true
                }
                Button("Continue as Guest", role: .none) {
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("We couldn't find an account with this email address. Would you like to create a new account or continue as a guest?")
            }
            .alert("Incorrect Password", isPresented: $showWrongPasswordAlert) {
                Button("Reset Password", role: .none) {
                    // TODO: Implement password reset flow
                    Task {
                        do {
                            try await authService.resetPassword(email: email)
                            errorMessage = "Password reset email sent to \(email)"
                            showError = true
                        } catch {
                            errorMessage = "Failed to send reset email: \(error.localizedDescription)"
                            showError = true
                        }
                    }
                }
                Button("Try Again", role: .cancel) {
                    password = ""
                }
            } message: {
                Text("The password you entered is incorrect. Would you like to reset your password?")
            }
            .alert("Sign In Failed", isPresented: $showUnknownErrorAlert) {
                Button("Sign Up", role: .none) {
                    showSignUpSheet = true
                }
                Button("Continue as Guest", role: .none) {
                    dismiss()
                }
                Button("Try Again", role: .cancel) {}
            } message: {
                Text("We couldn't sign you in. This might be because there's no account with this email. Would you like to create a new account or continue as a guest?")
            }
        }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && authService.validateEmail(email)
    }

    private func handleSignIn() {
        print("🟢 LoginView: handleSignIn() called")
        isLoading = true

        Task { @MainActor in
            do {
                print("🟢 LoginView: Calling authService.signIn()...")
                _ = try await authService.signIn(email: email, password: password)
                print("🟢 LoginView: Sign in succeeded, isAuthenticated = \(authService.isAuthenticated)")

                // Give the system a moment to propagate the state change
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                isLoading = false
                print("🟢 LoginView: isLoading set to false")
            } catch {
                print("🔴 LoginView: Sign in failed with error: \(error)")
                isLoading = false

                // Check for specific errors and show helpful alerts
                if let authError = error as? AuthError {
                    switch authError {
                    case .userNotFound:
                        print("🔴 LoginView: User not found, showing helpful alert")
                        showUserNotFoundAlert = true
                    case .wrongPassword:
                        print("🔴 LoginView: Wrong password, showing helpful alert")
                        showWrongPasswordAlert = true
                    case .unknown:
                        print("🔴 LoginView: Unknown error, showing helpful alert with sign-up/guest options")
                        showUnknownErrorAlert = true
                    default:
                        // Show generic error for other cases
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                } else {
                    // Show generic error for non-AuthError cases
                    print("🔴 LoginView: Non-AuthError, showing unknown error alert")
                    showUnknownErrorAlert = true
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthenticationService.shared)
}
