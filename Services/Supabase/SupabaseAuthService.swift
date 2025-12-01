//
//  SupabaseAuthService.swift
//  simpleApp
//
//  Supabase implementation of AuthenticationServiceProtocol
//

import Foundation
import Combine
import Supabase

@MainActor
class SupabaseAuthService: AuthenticationServiceProtocol {
    static let shared = SupabaseAuthService()

    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isNewUser = false
    @Published var isRestoringSession = true

    private let client: SupabaseClient

    private init() {
        print("🔵 SupabaseAuthService: Initializing...")

        self.client = SupabaseConfig.shared.client

        // Restore session if exists (don't clear on init - let user stay logged in)
        Task {
            await restoreSession()
        }
    }

    // MARK: - Session Management

    private func restoreSession() async {
        print("🔵 SupabaseAuthService: Attempting to restore session...")
        isRestoringSession = true

        do {
            let session = try await client.auth.session
            let user = session.user
            print("✅ SupabaseAuthService: Session restored for user: \(user.id)")
            self.currentUser = AuthUser(
                id: user.id.uuidString,
                email: user.email ?? "",
                displayName: user.userMetadata["name"]?.stringValue,
                photoURL: user.userMetadata["avatar_url"]?.stringValue
            )
            self.isAuthenticated = true
        } catch {
            print("⚠️ SupabaseAuthService: No active session to restore")
        }

        isRestoringSession = false
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String) async throws -> AuthUser {
        print("🔵 SupabaseAuthService.signUp: Starting sign up for email: \(email)")

        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name)]
            )

            let user = response.user
            print("✅ SupabaseAuthService.signUp: Sign up successful")
            print("🔍 SupabaseAuthService.signUp: User ID = \(user.id)")

            // Check if session is in the response
            if let session = response.session {
                print("✅ SupabaseAuthService.signUp: Session available in response - User ID: \(session.user.id)")
                // The session should be automatically stored by the SDK
            } else {
                print("⚠️ SupabaseAuthService.signUp: Session NOT in response")
                print("⚠️ This might mean email confirmation is required")

                // Try to get session separately as a fallback
                do {
                    let session = try await client.auth.session
                    print("✅ SupabaseAuthService.signUp: Session fetched separately - User ID: \(session.user.id)")
                } catch {
                    print("⚠️ SupabaseAuthService.signUp: Session fetch failed - \(error.localizedDescription)")
                    print("⚠️ User created but session not established - check Supabase email confirmation settings")
                }
            }

            let authUser = AuthUser(
                id: user.id.uuidString,
                email: user.email ?? email,
                displayName: name,
                photoURL: nil
            )

            self.currentUser = authUser
            self.isAuthenticated = true
            self.isNewUser = true

            return authUser
        } catch let error as AuthError {
            throw error
        } catch {
            print("❌ SupabaseAuthService.signUp: Error - \(error.localizedDescription)")
            throw mapSupabaseAuthError(error)
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async throws -> AuthUser {
        print("🔵 SupabaseAuthService.signIn: Starting sign in for email: \(email)")

        do {
            let session = try await client.auth.signIn(
                email: email,
                password: password
            )

            let user = session.user
            print("✅ SupabaseAuthService.signIn: Sign in successful")

            let authUser = AuthUser(
                id: user.id.uuidString,
                email: user.email ?? email,
                displayName: user.userMetadata["name"]?.stringValue,
                photoURL: user.userMetadata["avatar_url"]?.stringValue
            )

            self.currentUser = authUser
            self.isAuthenticated = true
            self.isNewUser = false

            return authUser
        } catch {
            print("❌ SupabaseAuthService.signIn: Error - \(error.localizedDescription)")
            throw mapSupabaseAuthError(error)
        }
    }

    // MARK: - Sign Out

    func signOut() throws {
        print("🔵 SupabaseAuthService.signOut: Signing out user")

        Task {
            do {
                try await client.auth.signOut()
                print("✅ SupabaseAuthService.signOut: Sign out successful")

                await MainActor.run {
                    self.currentUser = nil
                    self.isAuthenticated = false
                    self.isNewUser = false
                }
            } catch {
                print("❌ SupabaseAuthService.signOut: Error - \(error.localizedDescription)")
                throw AuthError.unknown
            }
        }
    }

    // MARK: - Password Reset

    func resetPassword(email: String) async throws {
        print("🔵 SupabaseAuthService.resetPassword: Sending reset email to: \(email)")

        do {
            try await client.auth.resetPasswordForEmail(email)
            print("✅ SupabaseAuthService.resetPassword: Reset email sent")
        } catch {
            print("❌ SupabaseAuthService.resetPassword: Error - \(error.localizedDescription)")
            throw mapSupabaseAuthError(error)
        }
    }

    // MARK: - Error Mapping

    private func mapSupabaseAuthError(_ error: Error) -> AuthError {
        // Map Supabase errors to our AuthError enum
        let errorDescription = error.localizedDescription.lowercased()

        if errorDescription.contains("invalid email") {
            return .invalidEmail
        } else if errorDescription.contains("weak password") || errorDescription.contains("password") {
            return .weakPassword
        } else if errorDescription.contains("already registered") || errorDescription.contains("already exists") {
            return .emailAlreadyInUse
        } else if errorDescription.contains("not found") {
            return .userNotFound
        } else if errorDescription.contains("invalid login") || errorDescription.contains("wrong password") {
            return .wrongPassword
        } else if errorDescription.contains("network") {
            return .networkError
        } else {
            return .unknown
        }
    }
}
