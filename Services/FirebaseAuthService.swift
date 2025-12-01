//
//  FirebaseAuthService.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class FirebaseAuthService: AuthenticationServiceProtocol {
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isNewUser = false  // Track if this is a new sign-up
    @Published var isRestoringSession = true  // Track if we're restoring a saved session

    static let shared = FirebaseAuthService()

    private init() {
        print("🟦 AuthService: Initializing...")
        isRestoringSession = true
        // Check for stored session
        loadStoredSession()
        isRestoringSession = false
        print("🟦 AuthService: Initialization complete, isAuthenticated = \(isAuthenticated)")
    }

    // MARK: - Sign Up
    func signUp(email: String, password: String, name: String) async throws -> AuthUser {
        print("🟦 AuthService: Starting sign up for email: \(email)")
        isLoading = true
        errorMessage = nil

        do {
            print("🟦 AuthService: Calling Firebase createUser...")
            let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
            print("🟦 AuthService: Firebase user created with UID: \(authResult.user.uid)")

            // Set display name
            print("🟦 AuthService: Updating display name to: \(name)")
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            print("🟦 AuthService: Display name updated successfully")

            let user = AuthUser(
                id: authResult.user.uid,
                email: email,
                displayName: name,
                photoURL: nil
            )

            currentUser = user
            isAuthenticated = true
            isNewUser = true  // Mark as new user for onboarding
            isLoading = false

            // Store session
            saveSession(user)
            print("✅ AuthService: Sign up completed successfully! isNewUser = true")

            return user
        } catch {
            print("❌ AuthService: Firebase error caught: \(error)")
            print("❌ AuthService: Error type: \(type(of: error))")
            print("❌ AuthService: NSError code: \((error as NSError).code)")
            print("❌ AuthService: NSError domain: \((error as NSError).domain)")
            isLoading = false
            errorMessage = error.localizedDescription
            let mappedError = mapFirebaseError(error)
            print("❌ AuthService: Mapped to AuthError: \(mappedError)")
            throw mappedError
        }
    }

    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> AuthUser {
        print("🟦 AuthService: signIn() called for email: \(email)")
        isLoading = true
        errorMessage = nil

        do {
            print("🟦 AuthService: Calling Firebase signIn()...")
            let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
            print("🟦 AuthService: Firebase signIn succeeded, UID: \(authResult.user.uid)")

            let user = AuthUser(
                id: authResult.user.uid,
                email: authResult.user.email ?? "",
                displayName: authResult.user.displayName,
                photoURL: authResult.user.photoURL?.absoluteString
            )

            print("🟦 AuthService: Setting currentUser...")
            currentUser = user
            print("🟦 AuthService: Setting isAuthenticated = true...")
            isAuthenticated = true
            isNewUser = false  // Existing user signing in
            print("🟦 AuthService: isAuthenticated is now \(isAuthenticated), isNewUser = false")
            isLoading = false

            // Store session
            saveSession(user)
            print("🟦 AuthService: Session saved, returning user")

            return user
        } catch {
            print("🔴 AuthService: signIn failed with error: \(error)")
            isLoading = false
            errorMessage = error.localizedDescription
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Sign In with Apple
    // TODO: Implement Sign in with Apple
    func signInWithApple() async throws -> AuthUser {
        isLoading = true
        errorMessage = nil

        try await Task.sleep(nanoseconds: 1_000_000_000)

        let user = AuthUser(id: UUID().uuidString, email: "apple@example.com", displayName: "Apple User")

        currentUser = user
        isAuthenticated = true
        isLoading = false

        saveSession(user)

        return user
    }

    // MARK: - Sign Out
    func signOut() throws {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            isNewUser = false
            clearSession()
        } catch {
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Password Reset
    func resetPassword(email: String) async throws {
        isLoading = true
        errorMessage = nil

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Delete Account
    func deleteAccount() async throws {
        guard let firebaseUser = Auth.auth().currentUser else {
            throw AuthError.notAuthenticated
        }

        isLoading = true

        do {
            try await firebaseUser.delete()
            currentUser = nil
            isAuthenticated = false
            isNewUser = false
            clearSession()
            isLoading = false
        } catch {
            isLoading = false

            // Check if re-authentication is required
            let nsError = error as NSError
            if nsError.domain == "FIRAuthErrorDomain" && nsError.code == 17014 {
                // ERROR_REQUIRES_RECENT_LOGIN - need to re-authenticate
                throw AuthError.requiresRecentLogin
            }

            throw mapFirebaseError(error)
        }
    }

    // MARK: - Re-authenticate (for sensitive operations)
    func reauthenticate(password: String) async throws {
        guard let firebaseUser = Auth.auth().currentUser,
              let email = firebaseUser.email else {
            throw AuthError.notAuthenticated
        }

        isLoading = true

        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await firebaseUser.reauthenticate(with: credential)
            isLoading = false
        } catch {
            isLoading = false
            throw mapFirebaseError(error)
        }
    }

    // MARK: - Error Mapping
    private func mapFirebaseError(_ error: Error) -> AuthError {
        let nsError = error as NSError

        print("🔵 Firebase Error Code: \(nsError.code)")
        print("🔵 Firebase Error Domain: \(nsError.domain)")
        print("🔵 Firebase Error Description: \(nsError.localizedDescription)")
        print("🔵 Firebase Error UserInfo: \(nsError.userInfo)")

        // Check error description for common patterns
        let errorDescription = nsError.localizedDescription.lowercased()
        if errorDescription.contains("user") && (errorDescription.contains("not found") || errorDescription.contains("no user")) {
            print("✅ Detected user not found from description")
            return .userNotFound
        }
        if errorDescription.contains("password") && errorDescription.contains("wrong") || errorDescription.contains("incorrect") {
            print("✅ Detected wrong password from description")
            return .wrongPassword
        }

        // Check for specific error codes by their numeric values
        // This is more reliable than trying to convert to AuthErrorCode
        if nsError.domain == "FIRAuthErrorDomain" {
            switch nsError.code {
            case 17005: // ERROR_INVALID_EMAIL
                print("✅ Mapped to: .invalidEmail")
                return .invalidEmail
            case 17026: // ERROR_WEAK_PASSWORD
                print("✅ Mapped to: .weakPassword")
                return .weakPassword
            case 17007: // ERROR_EMAIL_ALREADY_IN_USE
                print("✅ Mapped to: .emailAlreadyInUse")
                return .emailAlreadyInUse
            case 17011: // ERROR_USER_NOT_FOUND
                print("✅ Mapped to: .userNotFound")
                return .userNotFound
            case 17009: // ERROR_WRONG_PASSWORD
                print("✅ Mapped to: .wrongPassword")
                return .wrongPassword
            case 17020: // ERROR_NETWORK_REQUEST_FAILED
                print("✅ Mapped to: .networkError")
                return .networkError
            case 17999: // ERROR_INTERNAL_ERROR
                let errorDescription = nsError.userInfo.description
                if errorDescription.contains("CONFIGURATION_NOT_FOUND") {
                    print("❌ CONFIGURATION_NOT_FOUND detected!")
                    return .configurationError
                }
                print("❌ Internal error, returning .unknown")
                return .unknown
            default:
                print("❌ Unhandled error code \(nsError.code), returning .unknown")
                return .unknown
            }
        }

        // Fallback to AuthErrorCode if not FIRAuthErrorDomain
        guard let errorCode = AuthErrorCode(_bridgedNSError: nsError) else {
            print("❌ Could not convert to AuthErrorCode, returning .unknown")
            return .unknown
        }

        print("🔵 AuthErrorCode: \(errorCode.code.rawValue)")

        switch errorCode.code {
        case .invalidEmail:
            print("✅ Mapped to: .invalidEmail")
            return .invalidEmail
        case .weakPassword:
            print("✅ Mapped to: .weakPassword")
            return .weakPassword
        case .emailAlreadyInUse:
            print("✅ Mapped to: .emailAlreadyInUse")
            return .emailAlreadyInUse
        case .userNotFound:
            print("✅ Mapped to: .userNotFound")
            return .userNotFound
        case .wrongPassword:
            print("✅ Mapped to: .wrongPassword")
            return .wrongPassword
        case .networkError:
            print("✅ Mapped to: .networkError")
            return .networkError
        default:
            print("❌ No specific mapping found, returning .unknown")
            return .unknown
        }
    }

    // MARK: - Session Management
    private func saveSession(_ user: AuthUser) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "currentUser")
        }
    }

    private func loadStoredSession() {
        if let data = UserDefaults.standard.data(forKey: "currentUser"),
           let user = try? JSONDecoder().decode(AuthUser.self, from: data) {
            print("🟦 AuthService: Found stored session for user: \(user.email)")
            currentUser = user
            isAuthenticated = true
        } else {
            print("🟦 AuthService: No stored session found")
        }
    }

    private func clearSession() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    // MARK: - Validation
    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func validatePassword(_ password: String) -> (isValid: Bool, message: String) {
        if password.count < 8 {
            return (false, "Password must be at least 8 characters")
        }
        if !password.contains(where: { $0.isNumber }) {
            return (false, "Password must contain at least one number")
        }
        if !password.contains(where: { $0.isUppercase }) {
            return (false, "Password must contain at least one uppercase letter")
        }
        return (true, "")
    }
}
