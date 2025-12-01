//
//  AuthPromptView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct AuthPromptView: View {
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var showLoginSheet = false
    @State private var showSignUpSheet = false

    let title: String
    let message: String
    let icon: String

    init(
        title: String = "Sign in to save memories",
        message: String = "Create an account to save your memories and goals across all your devices",
        icon: String = "lock.shield.fill"
    ) {
        self.title = title
        self.message = message
        self.icon = icon
    }

    var body: some View {
        VStack(spacing: 32) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundColor(AppColors.primary)
                .padding(.top, 40)

            // Text
            VStack(spacing: 16) {
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Constants.Layout.paddingLarge)

            Spacer()

            // Buttons
            VStack(spacing: 16) {
                AnimatedButton(
                    title: "Sign In",
                    icon: "person.fill",
                    action: {
                        showLoginSheet = true
                    },
                    style: .primary
                )

                AnimatedButton(
                    title: "Create Account",
                    icon: "person.badge.plus",
                    action: {
                        showSignUpSheet = true
                    },
                    style: .secondary
                )

                Button(action: {
                    dismiss()
                }) {
                    Text("Maybe Later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, Constants.Layout.paddingLarge)
            .padding(.bottom, Constants.Layout.paddingLarge)
        }
        .background(AppColors.background.ignoresSafeArea())
        .sheet(isPresented: $showLoginSheet) {
            LoginView()
                .environmentObject(authService)
        }
        .sheet(isPresented: $showSignUpSheet) {
            SignUpView()
                .environmentObject(authService)
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            if newValue {
                // User just signed in, dismiss the auth prompt
                dismiss()
            }
        }
    }
}

#Preview {
    AuthPromptView()
        .environmentObject(AuthenticationService.shared)
}
