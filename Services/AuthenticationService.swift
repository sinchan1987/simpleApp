//
//  AuthenticationService.swift
//  simpleApp
//
//  Compatibility wrapper - delegates to BackendContainer for dynamic backend selection
//

import Foundation
import Combine

@MainActor
class AuthenticationService: ObservableObject {
    static let shared = AuthenticationService()

    // Published properties that delegate to backend
    @Published var currentUser: AuthUser?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isNewUser = false
    @Published var isRestoringSession = true

    private var cancellables = Set<AnyCancellable>()

    private init() {
        print("🔧 AuthenticationService: Initialized as wrapper for BackendContainer")

        // Start observing the backend auth service
        observeBackendChanges()
    }

    // MARK: - Backend Observation

    private func observeBackendChanges() {
        // Poll for changes from the backend auth service
        // This is a workaround since we can't directly observe protocol properties
        Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                let auth = BackendContainer.shared.auth

                if self.currentUser?.id != auth.currentUser?.id {
                    self.currentUser = auth.currentUser
                }
                if self.isAuthenticated != auth.isAuthenticated {
                    self.isAuthenticated = auth.isAuthenticated
                }
                if self.isLoading != auth.isLoading {
                    self.isLoading = auth.isLoading
                }
                if self.errorMessage != auth.errorMessage {
                    self.errorMessage = auth.errorMessage
                }
                if self.isNewUser != auth.isNewUser {
                    self.isNewUser = auth.isNewUser
                }
                if self.isRestoringSession != auth.isRestoringSession {
                    self.isRestoringSession = auth.isRestoringSession
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Backend Switching

    /// Switch backend based on email before authentication
    /// - Parameter email: Email to check against whitelist
    private func prepareBackend(forEmail email: String) {
        print("🔧 AuthenticationService.prepareBackend: Checking email: \(email)")
        let targetBackend = BackendContainer.shared.getBackendType(forEmail: email)
        print("🔧 AuthenticationService.prepareBackend: Target backend = \(targetBackend)")
        BackendContainer.shared.switchBackend(to: targetBackend)
        print("🔧 AuthenticationService.prepareBackend: Current backend = \(BackendContainer.shared.currentBackend)")
    }

    // MARK: - Authentication Methods (Delegate to Backend)

    func signUp(email: String, password: String, name: String) async throws -> AuthUser {
        print("🔧 AuthenticationService.signUp: Email = \(email)")

        // Switch to appropriate backend before sign up
        prepareBackend(forEmail: email)

        print("🔧 AuthenticationService.signUp: Backend = \(BackendContainer.shared.currentBackend)")

        // Delegate to backend's auth service
        let user = try await BackendContainer.shared.auth.signUp(email: email, password: password, name: name)

        print("🔧 AuthenticationService.signUp: Returned user ID = \(user.id)")
        print("🔧 AuthenticationService.signUp: Backend currentUser ID = \(BackendContainer.shared.auth.currentUser?.id ?? "nil")")

        // Update local state immediately
        self.currentUser = user
        self.isAuthenticated = true
        self.isNewUser = true

        print("🔧 AuthenticationService.signUp: Local currentUser ID set to = \(self.currentUser?.id ?? "nil")")

        return user
    }

    func signIn(email: String, password: String) async throws -> AuthUser {
        print("🔧 AuthenticationService.signIn: Email = \(email)")

        // Switch to appropriate backend before sign in
        prepareBackend(forEmail: email)

        print("🔧 AuthenticationService.signIn: Backend = \(BackendContainer.shared.currentBackend)")

        // Delegate to backend's auth service
        let user = try await BackendContainer.shared.auth.signIn(email: email, password: password)

        // Update local state
        self.currentUser = user
        self.isAuthenticated = true
        self.isNewUser = false

        return user
    }

    func signOut() throws {
        try BackendContainer.shared.auth.signOut()

        // Update local state
        self.currentUser = nil
        self.isAuthenticated = false
        self.isNewUser = false
    }

    func resetPassword(email: String) async throws {
        // Use current backend for password reset
        try await BackendContainer.shared.auth.resetPassword(email: email)
    }

    func signInWithApple() async throws -> AuthUser {
        // Apple sign in only supported by Firebase
        guard let firebaseAuth = BackendContainer.shared.auth as? FirebaseAuthService else {
            throw AuthError.configurationError
        }

        let user = try await firebaseAuth.signInWithApple()

        // Update local state
        self.currentUser = user
        self.isAuthenticated = true

        return user
    }

    func reauthenticate(password: String) async throws {
        // Reauthentication only supported by Firebase
        guard let firebaseAuth = BackendContainer.shared.auth as? FirebaseAuthService else {
            throw AuthError.configurationError
        }

        try await firebaseAuth.reauthenticate(password: password)
    }

    func deleteAccount() async throws {
        // Delete account only supported by Firebase
        guard let firebaseAuth = BackendContainer.shared.auth as? FirebaseAuthService else {
            throw AuthError.configurationError
        }

        try await firebaseAuth.deleteAccount()

        // Update local state
        self.currentUser = nil
        self.isAuthenticated = false
        self.isNewUser = false
    }

    // MARK: - Validation Helpers

    func validateEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }

    func validatePassword(_ password: String) -> (isValid: Bool, message: String?) {
        if password.count < 8 {
            return (false, "Password must be at least 8 characters")
        }

        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasNumber = password.range(of: "[0-9]", options: .regularExpression) != nil

        if !hasUppercase || !hasLowercase || !hasNumber {
            return (false, "Password must contain uppercase, lowercase, and number")
        }

        return (true, nil)
    }
}
