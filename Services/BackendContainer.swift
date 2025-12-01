//
//  BackendContainer.swift
//  simpleApp
//
//  Central service container for backend abstraction
//  Allows switching between Firebase and Supabase implementations
//

import Foundation

@MainActor
class BackendContainer {
    // Singleton instance
    static let shared = BackendContainer()

    // Backend type enum
    enum BackendType: String {
        case firebase
        case supabase
    }

    // Current backend type
    private(set) var currentBackend: BackendType

    // Service instances
    private(set) var auth: any AuthenticationServiceProtocol
    private(set) var database: DatabaseServiceProtocol
    private(set) var storage: StorageServiceProtocol

    // Test account whitelist for Supabase testing
    private let supabaseTestEmails: Set<String> = [
        // Add test email addresses here when ready to test Supabase
        // Example: "test@example.com"
        "sinchan.roy@gmail.com"
    ]

    private init() {
        // Default to Supabase (migrated from Firebase)
        self.currentBackend = .supabase
        self.auth = SupabaseAuthService.shared
        self.database = SupabaseDatabaseService.shared
        self.storage = SupabaseStorageService.shared

        print("🔧 BackendContainer: Initialized with Supabase backend")
    }

    // MARK: - Backend Switching

    /// Switch to a different backend implementation
    /// - Parameter backend: The backend type to switch to
    /// - Note: This should only be called during app initialization or for testing
    func switchBackend(to backend: BackendType) {
        guard backend != currentBackend else {
            print("⚠️ BackendContainer: Already using \(backend.rawValue) backend")
            return
        }

        print("🔄 BackendContainer: Switching from \(currentBackend.rawValue) to \(backend.rawValue)")

        switch backend {
        case .firebase:
            self.auth = FirebaseAuthService.shared
            self.database = FirebaseDatabaseService.shared
            self.storage = FirebaseStorageService.shared

        case .supabase:
            // Switch to Supabase services
            self.auth = SupabaseAuthService.shared
            self.database = SupabaseDatabaseService.shared
            self.storage = SupabaseStorageService.shared
        }

        self.currentBackend = backend
        print("✅ BackendContainer: Successfully switched to \(backend.rawValue)")
    }

    /// Check if an email should use Supabase for testing
    /// - Parameter email: The email to check
    /// - Returns: True if the email is in the test whitelist
    func shouldUseSupabase(forEmail email: String) -> Bool {
        return supabaseTestEmails.contains(email.lowercased())
    }

    /// Get the appropriate backend for a user email
    /// - Parameter email: Optional email address
    /// - Returns: The backend type to use
    func getBackendType(forEmail email: String?) -> BackendType {
        // Always use Supabase after migration
        return .supabase
    }
}

// MARK: - Convenience Extensions

extension BackendContainer {
    /// Convenience method to get typed auth service
    /// Note: Returns FirebaseAuthService if using Firebase, will return SupabaseAuthService when implemented
    var typedAuth: FirebaseAuthService? {
        return auth as? FirebaseAuthService
    }

    /// Convenience method to get typed database service
    var typedDatabase: FirebaseDatabaseService? {
        return database as? FirebaseDatabaseService
    }

    /// Convenience method to get typed storage service
    var typedStorage: FirebaseStorageService? {
        return storage as? FirebaseStorageService
    }
}
