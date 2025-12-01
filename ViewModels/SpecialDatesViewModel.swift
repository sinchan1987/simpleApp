//
//  SpecialDatesViewModel.swift
//  simpleApp
//
//  ViewModel for managing special dates and their associated goals
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SpecialDatesViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var customDates: [CustomSpecialDate] = []
    @Published var specialDateGoals: [SpecialDateGoal] = []
    @Published var isLoading = false
    @Published var error: Error?

    // MARK: - Dependencies
    private let databaseService = BackendContainer.shared.database

    // MARK: - Computed Properties

    /// Get all special dates (system + custom) combined
    func getAllSpecialDates(userProfile: UserProfile) -> [CombinedSpecialDate] {
        var combined: [CombinedSpecialDate] = []

        // Add system special dates from UserProfile
        let systemDates = userProfile.getSpecialDates()
        for systemDate in systemDates {
            combined.append(CombinedSpecialDate.fromSystem(
                date: systemDate.date,
                type: systemDate.type,
                label: systemDate.label
            ))
        }

        // Add custom special dates
        for customDate in customDates {
            combined.append(CombinedSpecialDate.fromCustom(customDate))
        }

        // Sort by next occurrence
        return combined.sorted { $0.daysUntilNext < $1.daysUntilNext }
    }

    /// Get special dates grouped by category
    func getSpecialDatesGrouped(userProfile: UserProfile) -> [(String, [CombinedSpecialDate])] {
        let allDates = getAllSpecialDates(userProfile: userProfile)
        var grouped: [SpecialDateCategory: [CombinedSpecialDate]] = [:]

        for date in allDates {
            if grouped[date.category] == nil {
                grouped[date.category] = []
            }
            grouped[date.category]?.append(date)
        }

        // Sort and return as array of tuples
        return grouped.map { (key, value) in
            (key.displayName, value.sorted { $0.daysUntilNext < $1.daysUntilNext })
        }.sorted { $0.0 < $1.0 }
    }

    /// Get upcoming special dates (next 30 days)
    func getUpcomingDates(userProfile: UserProfile) -> [CombinedSpecialDate] {
        return getAllSpecialDates(userProfile: userProfile).filter { $0.daysUntilNext <= 30 }
    }

    /// Get goals for a specific special date
    func getGoals(for specialDateId: UUID) -> [SpecialDateGoal] {
        return specialDateGoals.filter { $0.specialDateId == specialDateId && $0.isActive }
    }

    // MARK: - Data Loading

    /// Load all custom special dates for a user
    func loadCustomDates(forUser userId: String) async {
        isLoading = true
        print("📅 SpecialDatesViewModel: Loading custom dates for user: \(userId)")

        do {
            customDates = try await databaseService.loadCustomSpecialDates(userId: userId)
            print("✅ SpecialDatesViewModel: Loaded \(customDates.count) custom dates")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to load custom dates - \(error.localizedDescription)")
            self.error = error
        }

        isLoading = false
    }

    /// Load all special date goals for a user
    func loadGoals(forUser userId: String) async {
        print("🎯 SpecialDatesViewModel: Loading goals for user: \(userId)")

        do {
            specialDateGoals = try await databaseService.loadSpecialDateGoals(userId: userId)
            print("✅ SpecialDatesViewModel: Loaded \(specialDateGoals.count) goals")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to load goals - \(error.localizedDescription)")
            self.error = error
        }
    }

    /// Load all data for a user
    func loadAllData(forUser userId: String) async {
        await loadCustomDates(forUser: userId)
        await loadGoals(forUser: userId)
    }

    // MARK: - Custom Date CRUD Operations

    /// Create a new custom special date
    func createCustomDate(_ customDate: CustomSpecialDate) async throws {
        print("📅 SpecialDatesViewModel: Creating custom date - \(customDate.name)")

        do {
            try await databaseService.saveCustomSpecialDate(customDate)
            customDates.append(customDate)
            print("✅ SpecialDatesViewModel: Custom date created successfully")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to create custom date - \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    /// Update an existing custom special date
    func updateCustomDate(_ customDate: CustomSpecialDate) async throws {
        print("📅 SpecialDatesViewModel: Updating custom date - \(customDate.name)")

        var updated = customDate
        updated.updatedAt = Date()

        do {
            try await databaseService.updateCustomSpecialDate(updated)

            if let index = customDates.firstIndex(where: { $0.id == updated.id }) {
                customDates[index] = updated
            }

            print("✅ SpecialDatesViewModel: Custom date updated successfully")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to update custom date - \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    /// Delete a custom special date and its associated goals
    func deleteCustomDate(_ customDate: CustomSpecialDate) async throws {
        print("🗑️ SpecialDatesViewModel: Deleting custom date - \(customDate.name)")

        do {
            // Delete associated goals first
            let associatedGoals = getGoals(for: customDate.id)
            for goal in associatedGoals {
                try await deleteGoal(goal)
            }

            // Delete the custom date
            try await databaseService.deleteCustomSpecialDate(customDate)
            customDates.removeAll { $0.id == customDate.id }

            print("✅ SpecialDatesViewModel: Custom date deleted successfully")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to delete custom date - \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Goal CRUD Operations

    /// Create a new goal for a special date
    func createGoal(_ goal: SpecialDateGoal) async throws {
        print("🎯 SpecialDatesViewModel: Creating goal - \(goal.goalTitle)")

        do {
            try await databaseService.saveSpecialDateGoal(goal)
            specialDateGoals.append(goal)
            print("✅ SpecialDatesViewModel: Goal created successfully")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to create goal - \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    /// Update an existing goal
    func updateGoal(_ goal: SpecialDateGoal) async throws {
        print("🎯 SpecialDatesViewModel: Updating goal - \(goal.goalTitle)")

        var updated = goal
        updated.updatedAt = Date()

        do {
            try await databaseService.updateSpecialDateGoal(updated)

            if let index = specialDateGoals.firstIndex(where: { $0.id == updated.id }) {
                specialDateGoals[index] = updated
            }

            print("✅ SpecialDatesViewModel: Goal updated successfully")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to update goal - \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    /// Delete a goal
    func deleteGoal(_ goal: SpecialDateGoal) async throws {
        print("🗑️ SpecialDatesViewModel: Deleting goal - \(goal.goalTitle)")

        do {
            try await databaseService.deleteSpecialDateGoal(goal)
            specialDateGoals.removeAll { $0.id == goal.id }
            print("✅ SpecialDatesViewModel: Goal deleted successfully")
        } catch {
            print("❌ SpecialDatesViewModel: Failed to delete goal - \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    // MARK: - Goal Generation

    /// Generate WeekEntry goals for a special date based on its associated goals
    func generateWeekEntries(
        for specialDate: CombinedSpecialDate,
        goal: SpecialDateGoal,
        userProfile: UserProfile,
        memoryViewModel: MemoryViewModel
    ) async throws {
        print("🔄 SpecialDatesViewModel: Generating entries for \(specialDate.name) - \(goal.goalTitle)")

        let calendar = Calendar.current
        let dateCalculator = DateCalculator()
        let today = Date()

        // Determine how many occurrences to generate (next 5 years for yearly)
        let maxYears = 5
        let currentYear = calendar.component(.year, from: today)

        for yearOffset in 0..<maxYears {
            let targetYear = currentYear + yearOffset

            // Create date for this occurrence
            var components = DateComponents()
            components.year = targetYear
            components.month = specialDate.monthDay.month
            components.day = specialDate.monthDay.day

            guard let occurrenceDate = calendar.date(from: components),
                  occurrenceDate > today else {
                continue // Skip past dates
            }

            // Calculate week coordinates
            let coordinates = dateCalculator.dateToWeekCoordinates(
                date: occurrenceDate,
                userBirthDate: userProfile.dateOfBirth
            )

            // Check if goal already exists for this date
            let existingGoals = memoryViewModel.getEntries(
                week: coordinates.weekNumber,
                year: coordinates.weekYear,
                dayOfWeek: coordinates.dayOfWeek
            )

            let alreadyExists = existingGoals.contains { entry in
                entry.entryType == .goal && entry.title == goal.goalTitle
            }

            if alreadyExists {
                print("  ⏭️ Goal already exists for week \(coordinates.weekNumber) year \(coordinates.weekYear)")
                continue
            }

            // Create the WeekEntry goal
            let entry = WeekEntry(
                id: UUID(),
                userId: userProfile.userId ?? "",
                weekYear: coordinates.weekYear,
                weekNumber: coordinates.weekNumber,
                entryType: .goal,
                dayOfWeek: coordinates.dayOfWeek,
                title: goal.goalTitle,
                description: goal.goalDescription,
                textContent: "Generated from special date: \(specialDate.name)",
                photoURLs: [],
                audioURL: nil,
                createdAt: Date(),
                updatedAt: Date(),
                tags: [specialDate.category.displayName],
                isFavorite: false,
                reminderDate: goal.reminderEnabled ? calculateReminderDate(
                    for: occurrenceDate,
                    leadTime: goal.reminderLeadTime,
                    unit: goal.reminderLeadTimeUnit
                ) : nil,
                reminderEnabled: goal.reminderEnabled,
                notificationId: nil,
                isRecurring: false,
                recurringFrequency: nil,
                recurringEndDate: nil,
                notificationLeadTime: goal.reminderLeadTime,
                notificationLeadTimeUnit: goal.reminderLeadTimeUnit,
                parentMemoryId: nil,
                isCompleted: false,
                completedAt: nil,
                convertToMemoryWhenPassed: true
            )

            do {
                try await memoryViewModel.createEntry(entry)
                print("  ✅ Created goal for week \(coordinates.weekNumber) year \(coordinates.weekYear)")
            } catch {
                print("  ❌ Failed to create goal: \(error.localizedDescription)")
            }
        }

        print("✅ SpecialDatesViewModel: Finished generating entries")
    }

    /// Calculate reminder date based on lead time
    private func calculateReminderDate(for date: Date, leadTime: Int?, unit: LeadTimeUnit?) -> Date? {
        guard let leadTime = leadTime, let unit = unit else { return nil }

        let calendar = Calendar.current
        var dateComponent = DateComponents()

        switch unit {
        case .days:
            dateComponent.day = -leadTime
        case .weeks:
            dateComponent.weekOfYear = -leadTime
        case .months:
            dateComponent.month = -leadTime
        }

        return calendar.date(byAdding: dateComponent, to: date)
    }

    // MARK: - Calendar Integration

    /// Check if a date has a custom special date
    func hasCustomSpecialDate(on date: Date) -> Bool {
        return customDates.contains { $0.occursOn(date) }
    }

    /// Get custom special dates for a specific date
    func getCustomSpecialDates(for date: Date) -> [CustomSpecialDate] {
        return customDates.filter { $0.occursOn(date) }
    }

    /// Get the category for a custom special date on a given date
    func getCustomDateCategory(for date: Date) -> SpecialDateCategory? {
        return getCustomSpecialDates(for: date).first?.category
    }
}
