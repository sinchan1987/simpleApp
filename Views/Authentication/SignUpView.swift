//
//  SignUpView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var agreedToTerms = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showLoginSheet = false

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
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 80))
                                .foregroundColor(AppColors.accent)

                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Start capturing your life's moments")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.top, 40)

                        // Form
                        VStack(spacing: 20) {
                            // Name Field
                            NostalgicTextField(
                                placeholder: "Full Name",
                                text: $name,
                                icon: "person.fill"
                            )

                            // Email Field
                            NostalgicTextField(
                                placeholder: "Email",
                                text: $email,
                                icon: "envelope.fill",
                                errorMessage: emailError,
                                keyboardType: .emailAddress
                            )
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()

                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                                        .stroke(passwordError != nil ? Color.red : Color.clear, lineWidth: 2)
                                )

                                if let error = passwordError {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .font(.system(size: 14))
                                        Text(error)
                                            .font(.system(size: 14))
                                    }
                                    .foregroundColor(.red)
                                }
                            }

                            // Confirm Password Field
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.textSecondary)

                                if showConfirmPassword {
                                    TextField("Confirm Password", text: $confirmPassword)
                                        .font(.system(size: 18))
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                } else {
                                    SecureField("Confirm Password", text: $confirmPassword)
                                        .font(.system(size: 18))
                                        .autocorrectionDisabled()
                                        .textInputAutocapitalization(.never)
                                }

                                Button(action: {
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
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
                            .overlay(
                                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                                    .stroke(passwordMismatch ? Color.red : Color.clear, lineWidth: 2)
                            )

                            // Terms Agreement
                            Button(action: {
                                agreedToTerms.toggle()
                            }) {
                                HStack(spacing: 12) {
                                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 24))
                                        .foregroundColor(agreedToTerms ? AppColors.primary : AppColors.textSecondary)

                                    Text("I agree to the Terms of Service and Privacy Policy")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textPrimary)
                                        .multilineTextAlignment(.leading)
                                }
                            }
                        }

                        // Sign Up Button
                        AnimatedButton(
                            title: "Create Account",
                            icon: "arrow.right",
                            action: handleSignUp,
                            style: .primary,
                            isDisabled: !isFormValid,
                            isLoading: isLoading
                        )

                        // Already have an account?
                        HStack(spacing: 4) {
                            Text("Already have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)

                            Button(action: {
                                showLoginSheet = true
                            }) {
                                Text("Sign In")
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
            .sheet(isPresented: $showLoginSheet) {
                LoginView()
                    .environmentObject(authService)
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var emailError: String? {
        if !email.isEmpty && !authService.validateEmail(email) {
            return "Please enter a valid email"
        }
        return nil
    }

    private var passwordError: String? {
        if !password.isEmpty {
            let validation = authService.validatePassword(password)
            return validation.isValid ? nil : validation.message
        }
        return nil
    }

    private var passwordMismatch: Bool {
        return !confirmPassword.isEmpty && password != confirmPassword
    }

    private var isFormValid: Bool {
        return !name.isEmpty &&
               authService.validateEmail(email) &&
               authService.validatePassword(password).isValid &&
               password == confirmPassword &&
               agreedToTerms
    }

    private func handleSignUp() {
        isLoading = true

        Task { @MainActor in
            do {
                print("🔵 Attempting sign up with email: \(email)")
                _ = try await authService.signUp(email: email, password: password, name: name)
                print("✅ Sign up successful!")

                // Give the system a moment to propagate the state change
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                isLoading = false
            } catch {
                print("❌ Sign up error: \(error)")
                print("❌ Error details: \(error.localizedDescription)")
                if let authError = error as? AuthError {
                    print("❌ AuthError type: \(authError)")
                    errorMessage = authError.localizedDescription
                } else {
                    errorMessage = "An unknown error occurred: \(error.localizedDescription)"
                }
                showError = true
                isLoading = false
            }
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthenticationService.shared)
}
