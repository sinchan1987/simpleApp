//
//  FirebaseDatabaseService.swift
//  simpleApp
//
//  Firebase implementation of DatabaseServiceProtocol
//

import Foundation
import FirebaseFirestore

@MainActor
class FirebaseDatabaseService: DatabaseServiceProtocol {
    static let shared = FirebaseDatabaseService()
    private let db = Firestore.firestore()
    private let profilesCollection = "userProfiles"
    private let entriesCollection = "entries"

    private init() {
        print("🔥 FirebaseDatabaseService: Initialized")
    }

    // MARK: - User Profile Management

    func saveProfile(_ profile: UserProfile) async throws {
        guard let userId = profile.userId else {
            print("❌ FirebaseDatabaseService: Cannot save profile without userId")
            throw DatabaseError.missingUserId
        }

        print("🔥 FirebaseDatabaseService.saveProfile: Saving profile for user: \(userId)")

        let profileData = profile.toDictionary()

        do {
            try await db.collection(profilesCollection).document(userId).setData(profileData)
            print("✅ FirebaseDatabaseService.saveProfile: Profile saved successfully")
        } catch {
            print("❌ FirebaseDatabaseService.saveProfile: Failed to save profile: \(error.localizedDescription)")
            throw DatabaseError.saveFailed(error.localizedDescription)
        }
    }

    func loadProfile(userId: String) async throws -> UserProfile? {
        print("🔥 FirebaseDatabaseService.loadProfile: Loading profile for user: \(userId)")

        do {
            let document = try await db.collection(profilesCollection).document(userId).getDocument()

            guard document.exists, let data = document.data() else {
                print("🔥 FirebaseDatabaseService.loadProfile: No profile found for user: \(userId)")
                return nil
            }

            print("✅ FirebaseDatabaseService.loadProfile: Profile data retrieved")

            // Parse the profile data
            let profile = try parseProfile(from: data, userId: userId)
            print("✅ FirebaseDatabaseService.loadProfile: Profile loaded successfully - Name: \(profile.name)")

            return profile
        } catch {
            print("❌ FirebaseDatabaseService.loadProfile: Failed to load profile: \(error.localizedDescription)")
            throw DatabaseError.loadFailed(error.localizedDescription)
        }
    }

    // MARK: - Week Entries Management

    func saveEntry(_ entry: WeekEntry) async throws {
        print("🔥 FirebaseDatabaseService.saveEntry: Starting write for entry ID: \(entry.id.uuidString)")
        print("  Collection: \(entriesCollection)")
        print("  Week: \(entry.weekNumber), Year: \(entry.weekYear)")
        print("  Title: \(entry.title)")

        do {
            let data = entry.toDictionary()
            print("  📦 Data to write: \(data)")

            try await db.collection(entriesCollection)
                .document(entry.id.uuidString)
                .setData(data)

            print("✅ FirebaseDatabaseService.saveEntry: Write completed successfully")
        } catch {
            print("❌ FirebaseDatabaseService.saveEntry: Write failed with error: \(error.localizedDescription)")
            print("  Error details: \(error)")
            throw DatabaseError.saveFailed(error.localizedDescription)
        }
    }

    func updateEntry(_ entry: WeekEntry) async throws {
        print("🔥 FirebaseDatabaseService.updateEntry: Updating entry ID: \(entry.id.uuidString)")

        var updatedEntry = entry
        updatedEntry.updatedAt = Date()

        do {
            try await db.collection(entriesCollection)
                .document(entry.id.uuidString)
                .setData(updatedEntry.toDictionary(), merge: true)

            print("✅ FirebaseDatabaseService.updateEntry: Entry updated successfully")
        } catch {
            print("❌ FirebaseDatabaseService.updateEntry: Failed to update entry: \(error.localizedDescription)")
            throw DatabaseError.updateFailed(error.localizedDescription)
        }
    }

    func deleteEntry(_ entry: WeekEntry) async throws {
        print("🔥 FirebaseDatabaseService.deleteEntry: Starting Firestore deletion")
        print("  Document ID: \(entry.id.uuidString)")
        print("  Collection: \(entriesCollection)")

        do {
            try await db.collection(entriesCollection)
                .document(entry.id.uuidString)
                .delete()
            print("✅ FirebaseDatabaseService.deleteEntry: Document deleted successfully from Firestore")
        } catch {
            print("❌ FirebaseDatabaseService.deleteEntry: Failed to delete document")
            print("  Error: \(error.localizedDescription)")
            print("  Error details: \(error)")
            throw DatabaseError.deleteFailed(error.localizedDescription)
        }
    }

    func loadEntries(userId: String) async throws -> [WeekEntry] {
        print("🔥 FirebaseDatabaseService.loadEntries: Fetching entries for user: \(userId)")

        do {
            let snapshot = try await db.collection(entriesCollection)
                .whereField("userId", isEqualTo: userId)
                .getDocuments()

            let entries = snapshot.documents.compactMap { doc in
                WeekEntry.fromDictionary(doc.data())
            }

            print("✅ FirebaseDatabaseService.loadEntries: Loaded \(entries.count) entries")
            return entries
        } catch {
            print("❌ FirebaseDatabaseService.loadEntries: Failed to load entries: \(error.localizedDescription)")
            throw DatabaseError.loadFailed(error.localizedDescription)
        }
    }

    // MARK: - Real-time Listeners

    func observeEntries(userId: String, onChange: @escaping ([WeekEntry]) -> Void) -> Any {
        print("🎧 FirebaseDatabaseService.observeEntries: Setting up listener for userId: \(userId)")

        let listener = db.collection(entriesCollection)
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("❌ FirebaseDatabaseService.observeEntries: Error in snapshot listener: \(error.localizedDescription)")
                    print("  Error details: \(error)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("⚠️ FirebaseDatabaseService.observeEntries: No documents in snapshot")
                    return
                }

                print("📄 FirebaseDatabaseService.observeEntries: Received \(documents.count) documents")
                let entries = documents.compactMap { WeekEntry.fromDictionary($0.data()) }
                print("✅ FirebaseDatabaseService.observeEntries: Parsed \(entries.count) entries successfully")
                onChange(entries)
            }

        return listener
    }

    func removeListener(_ listener: Any) {
        if let listenerRegistration = listener as? ListenerRegistration {
            listenerRegistration.remove()
            print("🔥 FirebaseDatabaseService.removeListener: Listener removed")
        }
    }

    // MARK: - Custom Special Dates (Not implemented for Firebase - using Supabase only)

    func saveCustomSpecialDate(_ date: CustomSpecialDate) async throws {
        print("⚠️ FirebaseDatabaseService: Custom special dates not implemented for Firebase")
        throw DatabaseError.saveFailed("Custom special dates are only available with Supabase backend")
    }

    func updateCustomSpecialDate(_ date: CustomSpecialDate) async throws {
        print("⚠️ FirebaseDatabaseService: Custom special dates not implemented for Firebase")
        throw DatabaseError.updateFailed("Custom special dates are only available with Supabase backend")
    }

    func deleteCustomSpecialDate(_ date: CustomSpecialDate) async throws {
        print("⚠️ FirebaseDatabaseService: Custom special dates not implemented for Firebase")
        throw DatabaseError.deleteFailed("Custom special dates are only available with Supabase backend")
    }

    func loadCustomSpecialDates(userId: String) async throws -> [CustomSpecialDate] {
        print("⚠️ FirebaseDatabaseService: Custom special dates not implemented for Firebase")
        return []
    }

    // MARK: - Special Date Goals (Not implemented for Firebase - using Supabase only)

    func saveSpecialDateGoal(_ goal: SpecialDateGoal) async throws {
        print("⚠️ FirebaseDatabaseService: Special date goals not implemented for Firebase")
        throw DatabaseError.saveFailed("Special date goals are only available with Supabase backend")
    }

    func updateSpecialDateGoal(_ goal: SpecialDateGoal) async throws {
        print("⚠️ FirebaseDatabaseService: Special date goals not implemented for Firebase")
        throw DatabaseError.updateFailed("Special date goals are only available with Supabase backend")
    }

    func deleteSpecialDateGoal(_ goal: SpecialDateGoal) async throws {
        print("⚠️ FirebaseDatabaseService: Special date goals not implemented for Firebase")
        throw DatabaseError.deleteFailed("Special date goals are only available with Supabase backend")
    }

    func loadSpecialDateGoals(userId: String) async throws -> [SpecialDateGoal] {
        print("⚠️ FirebaseDatabaseService: Special date goals not implemented for Firebase")
        return []
    }

    // MARK: - Helper Methods

    private func parseProfile(from data: [String: Any], userId: String) throws -> UserProfile {
        guard let name = data["name"] as? String,
              let dateOfBirth = (data["dateOfBirth"] as? Timestamp)?.dateValue(),
              let industry = data["industry"] as? String,
              let jobRole = data["jobRole"] as? String,
              let yearsWorked = data["yearsWorked"] as? Double else {
            throw DatabaseError.invalidData
        }

        let email = data["email"] as? String
        let isAnonymous = data["isAnonymous"] as? Bool ?? false

        // Education
        let degree = data["degree"] as? String ?? ""
        let schoolName = data["schoolName"] as? String ?? ""
        let graduationYear = data["graduationYear"] as? Int ?? Calendar.current.component(.year, from: Date())

        // Family
        let relationshipStatusRaw = data["relationshipStatus"] as? String ?? RelationshipStatus.single.rawValue
        let relationshipStatus = RelationshipStatus(rawValue: relationshipStatusRaw) ?? .single
        let spouseName = data["spouseName"] as? String ?? ""
        let spouseDateOfBirth = (data["spouseDateOfBirth"] as? Timestamp)?.dateValue()
        let marriageDate = (data["marriageDate"] as? Timestamp)?.dateValue()

        // Parse children
        var children: [Child] = []
        if let childrenArray = data["children"] as? [[String: Any]] {
            children = childrenArray.compactMap { Child.fromDictionary($0) }
        }

        // Parse pets
        var pets: [Pet] = []
        if let petsArray = data["pets"] as? [[String: Any]] {
            pets = petsArray.compactMap { Pet.fromDictionary($0) }
        }

        return UserProfile(
            userId: userId,
            email: email,
            isAnonymous: isAnonymous,
            name: name,
            dateOfBirth: dateOfBirth,
            degree: degree,
            schoolName: schoolName,
            graduationYear: graduationYear,
            industry: industry,
            jobRole: jobRole,
            yearsWorked: yearsWorked,
            relationshipStatus: relationshipStatus,
            spouseName: spouseName,
            spouseDateOfBirth: spouseDateOfBirth,
            marriageDate: marriageDate,
            children: children,
            pets: pets
        )
    }
}

// MARK: - Database Errors
enum DatabaseError: LocalizedError {
    case missingUserId
    case documentNotFound
    case invalidData
    case saveFailed(String)
    case loadFailed(String)
    case updateFailed(String)
    case deleteFailed(String)

    var errorDescription: String? {
        switch self {
        case .missingUserId:
            return "User ID is required"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .saveFailed(let message):
            return "Failed to save: \(message)"
        case .loadFailed(let message):
            return "Failed to load: \(message)"
        case .updateFailed(let message):
            return "Failed to update: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        }
    }
}
