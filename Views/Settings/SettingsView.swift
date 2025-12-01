//
//  SettingsView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/6/25.
//

import SwiftUI

struct SettingsView: View {
    let userProfile: UserProfile

    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var showSignOutConfirmation = false
    @State private var showDeleteAccountConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isDeleting = false
    @State private var showPasswordPrompt = false
    @State private var passwordForDeletion = ""

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Section
                        profileSection

                        // Account Section
                        accountSection

                        // App Info Section
                        //appInfoSection
                    }
                    .padding(Constants.Layout.paddingLarge)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .alert("Sign Out", isPresented: $showSignOutConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Sign Out", role: .destructive) {
                    handleSignOut()
                }
            } message: {
                Text("Are you sure you want to sign out? You can sign back in anytime.")
            }
            .alert("Delete Profile", isPresented: $showDeleteAccountConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    handleDeleteAccount()
                }
            } message: {
                Text("Are you sure you want to permanently delete your profile? This action cannot be undone. All your data, including memories and goals, will be permanently deleted.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Confirm Password", isPresented: $showPasswordPrompt) {
                SecureField("Password", text: $passwordForDeletion)
                Button("Cancel", role: .cancel) {
                    passwordForDeletion = ""
                }
                Button("Delete Account", role: .destructive) {
                    handleDeleteWithPassword()
                }
            } message: {
                Text("For security, please enter your password to delete your account")
            }
            .overlay {
                if isDeleting {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.white)
                            Text("Deleting your profile...")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.black.opacity(0.8))
                        )
                    }
                }
            }
        }
    }

    private var profileSection: some View {
        VStack(spacing: 16) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 80, height: 80)

                Text(userProfile.name.prefix(1).uppercased())
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }

            // User Info
            VStack(spacing: 4) {
                Text(userProfile.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                if let email = authService.currentUser?.email {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Profile Details
            VStack(spacing: 12) {
                ProfileDetailRow(icon: "briefcase.fill", label: "Industry", value: userProfile.industry)
                ProfileDetailRow(icon: "person.fill", label: "Role", value: userProfile.jobRole)
                ProfileDetailRow(icon: "calendar", label: "Age", value: "\(userProfile.age) years")
                ProfileDetailRow(icon: "clock.fill", label: "Experience", value: "\(Int(userProfile.yearsWorked)) years")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
        }
    }

    private var accountSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "Account")

            VStack(spacing: 0) {
                SettingsButton(
                    icon: "arrow.right.square.fill",
                    title: "Sign Out",
                    iconColor: .red,
                    action: {
                        showSignOutConfirmation = true
                    }
                )

                Divider().padding(.leading, 52)

                SettingsButton(
                    icon: "trash.fill",
                    title: "Delete Profile",
                    iconColor: .red,
                    action: {
                        showDeleteAccountConfirmation = true
                    }
                )
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
        }
    }

   /* private var appInfoSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "About")

            VStack(spacing: 0) {
                SettingsRow(icon: "info.circle.fill", title: "Version", value: "1.0.0")
                Divider().padding(.leading, 52)
                SettingsRow(icon: "heart.fill", title: "Made with", value: "Claude Code")
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
        }
    }*/

    private func handleSignOut() {
        do {
            try authService.signOut()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func handleDeleteAccount() {
        // Show password prompt for re-authentication
        showPasswordPrompt = true
    }

    private func handleDeleteWithPassword() {
        guard !passwordForDeletion.isEmpty else {
            errorMessage = "Please enter your password"
            showError = true
            return
        }

        isDeleting = true

        Task {
            do {
                // Re-authenticate user first
                print("🔐 SettingsView: Re-authenticating user before deletion")
                try await authService.reauthenticate(password: passwordForDeletion)
                print("✅ SettingsView: Re-authentication successful")

                // Delete user data from Firestore
                if let userId = authService.currentUser?.id {
                    print("🗑️ SettingsView: Deleting user profile from Firestore for userId: \(userId)")

                    // Delete user profile document
                    try await UserProfileService.shared.deleteProfile(userId: userId)
                    print("✅ SettingsView: Profile deleted from Firestore")

                    // TODO: Delete all memories and goals when those features are implemented
                    // TODO: Delete any uploaded media files when that feature is implemented
                }

                // Delete the Firebase Auth account
                print("🗑️ SettingsView: Deleting Firebase Auth account")
                try await authService.deleteAccount()
                print("✅ SettingsView: Auth account deleted successfully")

                isDeleting = false
                passwordForDeletion = ""

                // Dismiss settings and return to welcome screen
                dismiss()
            } catch let error as AuthError {
                print("❌ SettingsView: Failed to delete account: \(error.localizedDescription)")
                isDeleting = false
                passwordForDeletion = ""

                if error == .requiresRecentLogin {
                    // This shouldn't happen since we just re-authenticated, but handle it anyway
                    errorMessage = "Re-authentication failed. Please try again."
                } else {
                    errorMessage = error.localizedDescription
                }
                showError = true
            } catch {
                print("❌ SettingsView: Failed to delete account: \(error.localizedDescription)")
                isDeleting = false
                passwordForDeletion = ""
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppColors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
            .padding(.bottom, 8)
    }
}

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primary)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    var iconColor: Color = AppColors.primary

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
                .frame(width: 28)

            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            Text(value)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding()
    }
}

struct SettingsButton: View {
    let icon: String
    let title: String
    var iconColor: Color = AppColors.primary
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
                    .frame(width: 28)

                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            .padding()
        }
    }
}

#Preview {
    let sampleProfile = UserProfile(
        name: "Alex",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
        industry: "Technology",
        jobRole: "Software Engineer",
        yearsWorked: 13
    )

    return SettingsView(userProfile: sampleProfile)
        .environmentObject(AuthenticationService.shared)
}
