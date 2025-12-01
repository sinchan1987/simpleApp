//
//  BackendServiceProtocols.swift
//  simpleApp
//
//  Created by Claude on 11/11/25.
//

import Foundation
import UIKit

// MARK: - Auth User Model (shared between backends)
struct AuthUser: Codable, Identifiable {
    let id: String
    let email: String
    let displayName: String?
    let photoURL: String?

    init(id: String, email: String, displayName: String?, photoURL: String? = nil) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
    }
}

// MARK: - Authentication Protocol
@MainActor
protocol AuthenticationServiceProtocol: ObservableObject {
    var isAuthenticated: Bool { get }
    var currentUser: AuthUser? { get }
    var isNewUser: Bool { get }
    var isRestoringSession: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    func signIn(email: String, password: String) async throws -> AuthUser
    func signUp(email: String, password: String, name: String) async throws -> AuthUser
    func signOut() throws
    func resetPassword(email: String) async throws
}

// MARK: - Database Protocol
protocol DatabaseServiceProtocol {
    // User Profiles
    func saveProfile(_ profile: UserProfile) async throws
    func loadProfile(userId: String) async throws -> UserProfile?

    // Entries (Memories/Goals)
    func saveEntry(_ entry: WeekEntry) async throws
    func updateEntry(_ entry: WeekEntry) async throws
    func deleteEntry(_ entry: WeekEntry) async throws
    func loadEntries(userId: String) async throws -> [WeekEntry]

    // Real-time listeners
    func observeEntries(userId: String, onChange: @escaping ([WeekEntry]) -> Void) -> Any
    func removeListener(_ listener: Any)

    // Custom Special Dates
    func saveCustomSpecialDate(_ date: CustomSpecialDate) async throws
    func updateCustomSpecialDate(_ date: CustomSpecialDate) async throws
    func deleteCustomSpecialDate(_ date: CustomSpecialDate) async throws
    func loadCustomSpecialDates(userId: String) async throws -> [CustomSpecialDate]

    // Special Date Goals
    func saveSpecialDateGoal(_ goal: SpecialDateGoal) async throws
    func updateSpecialDateGoal(_ goal: SpecialDateGoal) async throws
    func deleteSpecialDateGoal(_ goal: SpecialDateGoal) async throws
    func loadSpecialDateGoals(userId: String) async throws -> [SpecialDateGoal]
}

// MARK: - Storage Protocol
protocol StorageServiceProtocol {
    func uploadPhoto(_ image: UIImage, userId: String, progressHandler: ((Double) -> Void)?) async throws -> String
    func uploadAudio(_ audioURL: URL, userId: String, progressHandler: ((Double) -> Void)?) async throws -> String
    func downloadImage(from urlString: String) async throws -> UIImage
    func deleteFile(at urlString: String) async throws
    func compressImage(_ image: UIImage, maxSizeKB: Int) -> UIImage?
}

// MARK: - Auth Errors
enum AuthError: LocalizedError, Equatable {
    case notAuthenticated
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case configurationError
    case requiresRecentLogin
    case unknown

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 8 characters with one number and one uppercase letter"
        case .emailAlreadyInUse:
            return "This email is already registered. Please sign in instead or use a different email"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "The password you entered is incorrect. Please try again or reset your password"
        case .networkError:
            return "Unable to connect. Please check your internet connection and try again"
        case .configurationError:
            return "Authentication service configuration error. Please contact support"
        case .requiresRecentLogin:
            return "For security, please confirm your password to delete your account"
        case .unknown:
            return "Something went wrong. Please try again or contact support if the problem persists"
        }
    }
}
