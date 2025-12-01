//
//  SupabaseDatabaseService.swift
//  simpleApp
//
//  Supabase implementation of DatabaseServiceProtocol
//

import Foundation
import Supabase
import PostgREST

@MainActor
class SupabaseDatabaseService: DatabaseServiceProtocol {
    static let shared = SupabaseDatabaseService()

    private let client: SupabaseClient
    private let profilesTable = "user_profiles"
    private let entriesTable = "week_entries"

    private init() {
        print("🔵 SupabaseDatabaseService: Initialized")
        self.client = SupabaseConfig.shared.client
    }

    // MARK: - User Profile Management

    func saveProfile(_ profile: UserProfile) async throws {
        guard let userId = profile.userId else {
            print("❌ SupabaseDatabaseService: Cannot save profile without userId")
            throw DatabaseError.missingUserId
        }

        print("🔵 SupabaseDatabaseService.saveProfile: Saving profile for user: \(userId)")

        // Retry mechanism to wait for session to be established
        var lastError: Error?
        for attempt in 1...5 {
            do {
                // Try to get the authenticated session
                let session = try await client.auth.session
                let authenticatedUserId = session.user.id.uuidString
                print("🔍 SupabaseDatabaseService.saveProfile: Authenticated user ID = \(authenticatedUserId)")
                print("🔍 SupabaseDatabaseService.saveProfile: Profile user ID = \(userId)")

                if authenticatedUserId != userId {
                    print("⚠️ SupabaseDatabaseService.saveProfile: WARNING - User IDs don't match!")
                    print("⚠️ Using authenticated user ID instead: \(authenticatedUserId)")
                }

                // Encode children and pets to JSON
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let childrenJSON = (try? encoder.encode(profile.children)).flatMap { String(data: $0, encoding: .utf8) }
                let petsJSON = (try? encoder.encode(profile.pets)).flatMap { String(data: $0, encoding: .utf8) }

                let profileData = UserProfileDTO(
                    id: authenticatedUserId, // Use authenticated user ID as primary key
                    user_id: authenticatedUserId, // Use authenticated user ID
                    email: profile.email,
                    is_anonymous: profile.isAnonymous,
                    name: profile.name,
                    date_of_birth: ISO8601DateFormatter().string(from: profile.dateOfBirth),
                    degree: profile.degree.isEmpty ? nil : profile.degree,
                    school_name: profile.schoolName.isEmpty ? nil : profile.schoolName,
                    graduation_year: profile.graduationYear,
                    industry: profile.industry,
                    job_role: profile.jobRole,
                    years_worked: profile.yearsWorked,
                    relationship_status: profile.relationshipStatus.rawValue,
                    spouse_name: profile.spouseName.isEmpty ? nil : profile.spouseName,
                    spouse_date_of_birth: profile.spouseDateOfBirth.map { ISO8601DateFormatter().string(from: $0) },
                    marriage_date: profile.marriageDate.map { ISO8601DateFormatter().string(from: $0) },
                    children: childrenJSON,
                    pets: petsJSON,
                    number_of_kids: profile.numberOfKids,
                    number_of_pets: profile.numberOfPets
                )

                try await client
                    .from(profilesTable)
                    .upsert(profileData)
                    .execute()

                print("✅ SupabaseDatabaseService.saveProfile: Profile saved successfully")
                return // Success - exit the function
            } catch let error as DatabaseError {
                throw error // Don't retry on database errors
            } catch {
                lastError = error
                print("⚠️ SupabaseDatabaseService.saveProfile: Attempt \(attempt)/5 failed - \(error.localizedDescription)")

                // If session is missing, wait a bit and retry
                if error.localizedDescription.contains("Auth session missing") && attempt < 5 {
                    print("⏳ Waiting 500ms before retry...")
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    continue
                } else {
                    // Other error or final attempt - throw
                    throw DatabaseError.saveFailed(error.localizedDescription)
                }
            }
        }

        // If we get here, all retries failed
        print("❌ SupabaseDatabaseService.saveProfile: All retries failed")
        throw DatabaseError.saveFailed(lastError?.localizedDescription ?? "Unknown error after retries")
    }

    func loadProfile(userId: String) async throws -> UserProfile? {
        print("🔵 SupabaseDatabaseService.loadProfile: Loading profile for user: \(userId)")

        do {
            let profileDTO: UserProfileDTO = try await client
                .from(profilesTable)
                .select()
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            let profile = profileDTO.toUserProfile()
            print("✅ SupabaseDatabaseService.loadProfile: Profile loaded - Name: \(profile.name)")
            return profile
        } catch {
            print("❌ SupabaseDatabaseService.loadProfile: Failed - \(error.localizedDescription)")

            // If no rows found, return nil instead of throwing
            if error.localizedDescription.contains("no rows") || error.localizedDescription.contains("not found") {
                print("🔵 SupabaseDatabaseService.loadProfile: No profile found")
                return nil
            }

            throw DatabaseError.loadFailed(error.localizedDescription)
        }

    }

    // MARK: - Week Entries Management

    func saveEntry(_ entry: WeekEntry) async throws {
        print("🔵 SupabaseDatabaseService.saveEntry: Saving entry ID: \(entry.id.uuidString)")

        do {
            // Get authenticated user ID to ensure RLS passes
            let session = try await client.auth.session
            let authenticatedUserId = session.user.id.uuidString

            let entryData = WeekEntryDTO(
                id: entry.id.uuidString,
                user_id: authenticatedUserId, // Use authenticated user ID
                week_number: entry.weekNumber,
                week_year: entry.weekYear,
                title: entry.title,
                description: entry.description ?? "",
                entry_type: entry.entryType.rawValue,
                photo_urls: entry.photoURLs,
                audio_urls: entry.audioURL != nil ? [entry.audioURL!] : [],
                day_of_week: entry.dayOfWeek,
                created_at: ISO8601DateFormatter().string(from: entry.createdAt),
                updated_at: ISO8601DateFormatter().string(from: entry.updatedAt),
                reminder_date: entry.reminderDate != nil ? ISO8601DateFormatter().string(from: entry.reminderDate!) : nil,
                reminder_enabled: entry.reminderEnabled,
                notification_id: entry.notificationId,
                location_name: entry.locationName,
                location_latitude: entry.locationLatitude,
                location_longitude: entry.locationLongitude
            )

            try await client
                .from(entriesTable)
                .insert(entryData)
                .execute()

            print("✅ SupabaseDatabaseService.saveEntry: Entry saved successfully")
        } catch {
            print("❌ SupabaseDatabaseService.saveEntry: Failed - \(error.localizedDescription)")
            throw DatabaseError.saveFailed(error.localizedDescription)
        }

    }

    func updateEntry(_ entry: WeekEntry) async throws {
        print("🔵 SupabaseDatabaseService.updateEntry: Updating entry ID: \(entry.id.uuidString)")

        do {
            var updatedEntry = entry
            updatedEntry.updatedAt = Date()

            let entryData = WeekEntryDTO(
                id: updatedEntry.id.uuidString,
                user_id: updatedEntry.userId,
                week_number: updatedEntry.weekNumber,
                week_year: updatedEntry.weekYear,
                title: updatedEntry.title,
                description: updatedEntry.description ?? "",
                entry_type: updatedEntry.entryType.rawValue,
                photo_urls: updatedEntry.photoURLs,
                audio_urls: updatedEntry.audioURL != nil ? [updatedEntry.audioURL!] : [],
                day_of_week: updatedEntry.dayOfWeek,
                created_at: ISO8601DateFormatter().string(from: updatedEntry.createdAt),
                updated_at: ISO8601DateFormatter().string(from: updatedEntry.updatedAt),
                reminder_date: updatedEntry.reminderDate != nil ? ISO8601DateFormatter().string(from: updatedEntry.reminderDate!) : nil,
                reminder_enabled: updatedEntry.reminderEnabled,
                notification_id: updatedEntry.notificationId,
                location_name: updatedEntry.locationName,
                location_latitude: updatedEntry.locationLatitude,
                location_longitude: updatedEntry.locationLongitude
            )

            try await client
                .from(entriesTable)
                .update(entryData)
                .eq("id", value: entry.id.uuidString)
                .execute()

            print("✅ SupabaseDatabaseService.updateEntry: Entry updated successfully")
        } catch {
            print("❌ SupabaseDatabaseService.updateEntry: Failed - \(error.localizedDescription)")
            throw DatabaseError.updateFailed(error.localizedDescription)
        }

    }

    func deleteEntry(_ entry: WeekEntry) async throws {
        print("🔵 SupabaseDatabaseService.deleteEntry: Deleting entry ID: \(entry.id.uuidString)")

        do {
            try await client
                .from(entriesTable)
                .delete()
                .eq("id", value: entry.id.uuidString)
                .execute()

            print("✅ SupabaseDatabaseService.deleteEntry: Entry deleted successfully")
        } catch {
            print("❌ SupabaseDatabaseService.deleteEntry: Failed - \(error.localizedDescription)")
            throw DatabaseError.deleteFailed(error.localizedDescription)
        }

    }

    func loadEntries(userId: String) async throws -> [WeekEntry] {
        print("🔵 SupabaseDatabaseService.loadEntries: Loading entries for user: \(userId)")

        do {
            let response: [WeekEntryDTO] = try await client
                .from(entriesTable)
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            let entries = response.map { $0.toWeekEntry() }
            print("✅ SupabaseDatabaseService.loadEntries: Loaded \(entries.count) entries")
            return entries
        } catch {
            print("❌ SupabaseDatabaseService.loadEntries: Failed - \(error.localizedDescription)")
            throw DatabaseError.loadFailed(error.localizedDescription)
        }

    }

    // MARK: - Real-time Listeners

    func observeEntries(userId: String, onChange: @escaping ([WeekEntry]) -> Void) -> Any {
        print("🔵 SupabaseDatabaseService.observeEntries: Setting up listener for user: \(userId)")

        // For now, return a placeholder - realtime listeners can be enhanced later
        // The app will still work without realtime updates
        print("⚠️ SupabaseDatabaseService: Realtime listeners not yet fully implemented")

        return NSObject() // Placeholder listener object
    }

    func removeListener(_ listener: Any) {
        print("🔵 SupabaseDatabaseService.removeListener: Removing listener")
        // Placeholder for now - will be implemented when realtime is fully set up
        print("✅ SupabaseDatabaseService: Listener removed (placeholder)")
    }

    // MARK: - Custom Special Dates

    private let customDatesTable = "custom_special_dates"
    private let specialDateGoalsTable = "special_date_goals"

    func saveCustomSpecialDate(_ date: CustomSpecialDate) async throws {
        print("🔵 SupabaseDatabaseService.saveCustomSpecialDate: Saving date - \(date.name)")

        do {
            let session = try await client.auth.session
            let authenticatedUserId = session.user.id.uuidString

            let dateDTO = CustomSpecialDateDTO(
                id: date.id.uuidString,
                user_id: authenticatedUserId,
                name: date.name,
                date: ISO8601DateFormatter().string(from: date.date),
                category: date.category.rawValue,
                is_recurring: date.isRecurring,
                notes: date.notes,
                created_at: ISO8601DateFormatter().string(from: date.createdAt),
                updated_at: ISO8601DateFormatter().string(from: date.updatedAt)
            )

            try await client
                .from(customDatesTable)
                .insert(dateDTO)
                .execute()

            print("✅ SupabaseDatabaseService.saveCustomSpecialDate: Date saved successfully")
        } catch {
            print("❌ SupabaseDatabaseService.saveCustomSpecialDate: Failed - \(error.localizedDescription)")
            throw DatabaseError.saveFailed(error.localizedDescription)
        }
    }

    func updateCustomSpecialDate(_ date: CustomSpecialDate) async throws {
        print("🔵 SupabaseDatabaseService.updateCustomSpecialDate: Updating date - \(date.name)")

        do {
            let dateDTO = CustomSpecialDateDTO(
                id: date.id.uuidString,
                user_id: date.userId,
                name: date.name,
                date: ISO8601DateFormatter().string(from: date.date),
                category: date.category.rawValue,
                is_recurring: date.isRecurring,
                notes: date.notes,
                created_at: ISO8601DateFormatter().string(from: date.createdAt),
                updated_at: ISO8601DateFormatter().string(from: date.updatedAt)
            )

            try await client
                .from(customDatesTable)
                .update(dateDTO)
                .eq("id", value: date.id.uuidString)
                .execute()

            print("✅ SupabaseDatabaseService.updateCustomSpecialDate: Date updated successfully")
        } catch {
            print("❌ SupabaseDatabaseService.updateCustomSpecialDate: Failed - \(error.localizedDescription)")
            throw DatabaseError.updateFailed(error.localizedDescription)
        }
    }

    func deleteCustomSpecialDate(_ date: CustomSpecialDate) async throws {
        print("🔵 SupabaseDatabaseService.deleteCustomSpecialDate: Deleting date - \(date.name)")

        do {
            try await client
                .from(customDatesTable)
                .delete()
                .eq("id", value: date.id.uuidString)
                .execute()

            print("✅ SupabaseDatabaseService.deleteCustomSpecialDate: Date deleted successfully")
        } catch {
            print("❌ SupabaseDatabaseService.deleteCustomSpecialDate: Failed - \(error.localizedDescription)")
            throw DatabaseError.deleteFailed(error.localizedDescription)
        }
    }

    func loadCustomSpecialDates(userId: String) async throws -> [CustomSpecialDate] {
        print("🔵 SupabaseDatabaseService.loadCustomSpecialDates: Loading dates for user: \(userId)")

        do {
            let response: [CustomSpecialDateDTO] = try await client
                .from(customDatesTable)
                .select()
                .eq("user_id", value: userId)
                .order("date", ascending: true)
                .execute()
                .value

            let dates = response.map { $0.toCustomSpecialDate() }
            print("✅ SupabaseDatabaseService.loadCustomSpecialDates: Loaded \(dates.count) dates")
            return dates
        } catch {
            print("❌ SupabaseDatabaseService.loadCustomSpecialDates: Failed - \(error.localizedDescription)")
            throw DatabaseError.loadFailed(error.localizedDescription)
        }
    }

    // MARK: - Special Date Goals

    func saveSpecialDateGoal(_ goal: SpecialDateGoal) async throws {
        print("🔵 SupabaseDatabaseService.saveSpecialDateGoal: Saving goal - \(goal.goalTitle)")

        do {
            let session = try await client.auth.session
            let authenticatedUserId = session.user.id.uuidString

            let goalDTO = SpecialDateGoalDTO(
                id: goal.id.uuidString,
                special_date_id: goal.specialDateId.uuidString,
                user_id: authenticatedUserId,
                goal_title: goal.goalTitle,
                goal_description: goal.goalDescription,
                frequency: goal.frequency.rawValue,
                reminder_enabled: goal.reminderEnabled,
                reminder_lead_time: goal.reminderLeadTime,
                reminder_lead_time_unit: goal.reminderLeadTimeUnit?.rawValue,
                is_active: goal.isActive,
                created_at: ISO8601DateFormatter().string(from: goal.createdAt),
                updated_at: ISO8601DateFormatter().string(from: goal.updatedAt)
            )

            try await client
                .from(specialDateGoalsTable)
                .insert(goalDTO)
                .execute()

            print("✅ SupabaseDatabaseService.saveSpecialDateGoal: Goal saved successfully")
        } catch {
            print("❌ SupabaseDatabaseService.saveSpecialDateGoal: Failed - \(error.localizedDescription)")
            throw DatabaseError.saveFailed(error.localizedDescription)
        }
    }

    func updateSpecialDateGoal(_ goal: SpecialDateGoal) async throws {
        print("🔵 SupabaseDatabaseService.updateSpecialDateGoal: Updating goal - \(goal.goalTitle)")

        do {
            let goalDTO = SpecialDateGoalDTO(
                id: goal.id.uuidString,
                special_date_id: goal.specialDateId.uuidString,
                user_id: goal.userId,
                goal_title: goal.goalTitle,
                goal_description: goal.goalDescription,
                frequency: goal.frequency.rawValue,
                reminder_enabled: goal.reminderEnabled,
                reminder_lead_time: goal.reminderLeadTime,
                reminder_lead_time_unit: goal.reminderLeadTimeUnit?.rawValue,
                is_active: goal.isActive,
                created_at: ISO8601DateFormatter().string(from: goal.createdAt),
                updated_at: ISO8601DateFormatter().string(from: goal.updatedAt)
            )

            try await client
                .from(specialDateGoalsTable)
                .update(goalDTO)
                .eq("id", value: goal.id.uuidString)
                .execute()

            print("✅ SupabaseDatabaseService.updateSpecialDateGoal: Goal updated successfully")
        } catch {
            print("❌ SupabaseDatabaseService.updateSpecialDateGoal: Failed - \(error.localizedDescription)")
            throw DatabaseError.updateFailed(error.localizedDescription)
        }
    }

    func deleteSpecialDateGoal(_ goal: SpecialDateGoal) async throws {
        print("🔵 SupabaseDatabaseService.deleteSpecialDateGoal: Deleting goal - \(goal.goalTitle)")

        do {
            try await client
                .from(specialDateGoalsTable)
                .delete()
                .eq("id", value: goal.id.uuidString)
                .execute()

            print("✅ SupabaseDatabaseService.deleteSpecialDateGoal: Goal deleted successfully")
        } catch {
            print("❌ SupabaseDatabaseService.deleteSpecialDateGoal: Failed - \(error.localizedDescription)")
            throw DatabaseError.deleteFailed(error.localizedDescription)
        }
    }

    func loadSpecialDateGoals(userId: String) async throws -> [SpecialDateGoal] {
        print("🔵 SupabaseDatabaseService.loadSpecialDateGoals: Loading goals for user: \(userId)")

        do {
            let response: [SpecialDateGoalDTO] = try await client
                .from(specialDateGoalsTable)
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            let goals = response.map { $0.toSpecialDateGoal() }
            print("✅ SupabaseDatabaseService.loadSpecialDateGoals: Loaded \(goals.count) goals")
            return goals
        } catch {
            print("❌ SupabaseDatabaseService.loadSpecialDateGoals: Failed - \(error.localizedDescription)")
            throw DatabaseError.loadFailed(error.localizedDescription)
        }
    }
}

// MARK: - Data Transfer Objects (DTOs)

struct UserProfileDTO: Codable {
    let id: String
    let user_id: String
    let email: String?
    let is_anonymous: Bool
    let name: String
    let date_of_birth: String

    // Education
    let degree: String?
    let school_name: String?
    let graduation_year: Int?

    // Work
    let industry: String
    let job_role: String
    let years_worked: Double

    // Family
    let relationship_status: String
    let spouse_name: String?
    let spouse_date_of_birth: String?
    let marriage_date: String?
    let children: String? // JSON encoded array
    let pets: String? // JSON encoded array

    // Legacy fields
    let number_of_kids: Int
    let number_of_pets: Int

    func toUserProfile() -> UserProfile {
        let dateFormatter = ISO8601DateFormatter()
        let dob = dateFormatter.date(from: date_of_birth) ?? Date()
        let status = RelationshipStatus(rawValue: relationship_status) ?? .single

        // Parse spouse date of birth
        var spouseDOB: Date? = nil
        if let spouseDOBString = spouse_date_of_birth {
            spouseDOB = dateFormatter.date(from: spouseDOBString)
        }

        // Parse marriage date
        var marriage: Date? = nil
        if let marriageDateString = marriage_date {
            marriage = dateFormatter.date(from: marriageDateString)
        }

        // Parse children JSON
        var childrenArray: [Child] = []
        if let childrenJSON = children,
           let childrenData = childrenJSON.data(using: .utf8) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            childrenArray = (try? decoder.decode([Child].self, from: childrenData)) ?? []
        }

        // Parse pets JSON
        var petsArray: [Pet] = []
        if let petsJSON = pets,
           let petsData = petsJSON.data(using: .utf8) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            petsArray = (try? decoder.decode([Pet].self, from: petsData)) ?? []
        }

        return UserProfile(
            userId: user_id,
            email: email,
            isAnonymous: is_anonymous,
            name: name,
            dateOfBirth: dob,
            degree: degree ?? "",
            schoolName: school_name ?? "",
            graduationYear: graduation_year ?? Calendar.current.component(.year, from: Date()),
            industry: industry,
            jobRole: job_role,
            yearsWorked: years_worked,
            relationshipStatus: status,
            spouseName: spouse_name ?? "",
            spouseDateOfBirth: spouseDOB,
            marriageDate: marriage,
            children: childrenArray,
            pets: petsArray
        )
    }
}

struct WeekEntryDTO: Codable {
    let id: String
    let user_id: String
    let week_number: Int
    let week_year: Int
    let title: String
    let description: String
    let entry_type: String
    let photo_urls: [String]
    let audio_urls: [String]
    let day_of_week: Int?
    let created_at: String
    let updated_at: String
    let reminder_date: String?
    let reminder_enabled: Bool?
    let notification_id: String?
    let location_name: String?
    let location_latitude: Double?
    let location_longitude: Double?

    func toWeekEntry() -> WeekEntry {
        let dateFormatter = ISO8601DateFormatter()
        let created = dateFormatter.date(from: created_at) ?? Date()
        let updated = dateFormatter.date(from: updated_at) ?? Date()
        let type = EntryType(rawValue: entry_type) ?? .memory
        let reminderDate = reminder_date != nil ? dateFormatter.date(from: reminder_date!) : nil

        return WeekEntry(
            id: UUID(uuidString: id) ?? UUID(),
            userId: user_id,
            weekYear: week_year,
            weekNumber: week_number,
            entryType: type,
            dayOfWeek: day_of_week,
            title: title,
            description: description,
            photoURLs: photo_urls,
            audioURL: audio_urls.first,
            locationName: location_name,
            locationLatitude: location_latitude,
            locationLongitude: location_longitude,
            createdAt: created,
            updatedAt: updated,
            reminderDate: reminderDate,
            reminderEnabled: reminder_enabled ?? false,
            notificationId: notification_id
        )
    }
}

// MARK: - Custom Special Date DTO
struct CustomSpecialDateDTO: Codable {
    let id: String
    let user_id: String
    let name: String
    let date: String
    let category: String
    let is_recurring: Bool
    let notes: String?
    let created_at: String
    let updated_at: String

    func toCustomSpecialDate() -> CustomSpecialDate {
        let dateFormatter = ISO8601DateFormatter()
        let parsedDate = dateFormatter.date(from: date) ?? Date()
        let createdAt = dateFormatter.date(from: created_at) ?? Date()
        let updatedAt = dateFormatter.date(from: updated_at) ?? Date()
        let parsedCategory = SpecialDateCategory(rawValue: category) ?? .custom

        return CustomSpecialDate(
            id: UUID(uuidString: id) ?? UUID(),
            userId: user_id,
            name: name,
            date: parsedDate,
            category: parsedCategory,
            isRecurring: is_recurring,
            notes: notes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Special Date Goal DTO
struct SpecialDateGoalDTO: Codable {
    let id: String
    let special_date_id: String
    let user_id: String
    let goal_title: String
    let goal_description: String?
    let frequency: String
    let reminder_enabled: Bool
    let reminder_lead_time: Int?
    let reminder_lead_time_unit: String?
    let is_active: Bool
    let created_at: String
    let updated_at: String

    func toSpecialDateGoal() -> SpecialDateGoal {
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: created_at) ?? Date()
        let updatedAt = dateFormatter.date(from: updated_at) ?? Date()
        let parsedFrequency = RecurringFrequency(rawValue: frequency) ?? .yearly
        let parsedLeadTimeUnit = reminder_lead_time_unit.flatMap { LeadTimeUnit(rawValue: $0) }

        return SpecialDateGoal(
            id: UUID(uuidString: id) ?? UUID(),
            specialDateId: UUID(uuidString: special_date_id) ?? UUID(),
            userId: user_id,
            goalTitle: goal_title,
            goalDescription: goal_description,
            frequency: parsedFrequency,
            reminderEnabled: reminder_enabled,
            reminderLeadTime: reminder_lead_time,
            reminderLeadTimeUnit: parsedLeadTimeUnit,
            isActive: is_active,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
