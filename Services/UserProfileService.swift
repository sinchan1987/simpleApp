//
//  UserProfileService.swift
//  simpleApp
//
//  Compatibility wrapper - delegates to DatabaseServiceProtocol
//

import Foundation

@MainActor
class UserProfileService {
    static let shared = UserProfileService()

    // Delegate to BackendContainer's database service
    private var databaseService: DatabaseServiceProtocol {
        BackendContainer.shared.database
    }

    private init() {
        print("📊 UserProfileService: Initialized (delegating to BackendContainer)")
    }

    // MARK: - Save Profile
    func saveProfile(_ profile: UserProfile) async throws {
        try await databaseService.saveProfile(profile)
    }

    // MARK: - Load Profile
    func loadProfile(userId: String) async throws -> UserProfile? {
        return try await databaseService.loadProfile(userId: userId)
    }

    // MARK: - Delete Profile (not in protocol yet, handled separately)
    func deleteProfile(userId: String) async throws {
        // Note: Delete profile is not in the DatabaseServiceProtocol
        // For now, we'll handle this through the FirebaseDatabaseService directly
        // This can be added to the protocol later if needed
        throw ProfileError.deleteFailed("Delete profile not yet implemented in protocol")
    }
}

// MARK: - Profile Errors (kept for backward compatibility)
enum ProfileError: LocalizedError {
    case missingUserId
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "Cannot save profile without a user ID"
        case .saveFailed(let message):
            return "Failed to save profile: \(message)"
        case .loadFailed(let message):
            return "Failed to load profile: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete profile: \(message)"
        case .invalidData:
            return "Profile data is invalid or corrupted"
        }
    }
}
