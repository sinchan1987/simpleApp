//
//  MemoryViewModel.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class MemoryViewModel: ObservableObject {
    @Published var entriesByWeek: [String: [WeekEntry]] = [:]  // Changed to array of entries
    @Published var isLoading = false
    @Published var error: Error?
    @Published var uploadProgress: Double = 0

    private let databaseService = BackendContainer.shared.database
    private let storageService = BackendContainer.shared.storage
    private var listenerRegistration: Any?

    // MARK: - Load Entries
    func loadEntries(forUser userId: String) async {
        isLoading = true

        do {
            let entries = try await databaseService.loadEntries(userId: userId)
            // Group entries by week, supporting multiple entries per week
            var groupedEntries: [String: [WeekEntry]] = [:]
            for entry in entries {
                let key = weekKey(entry.weekYear, entry.weekNumber)
                if groupedEntries[key] == nil {
                    groupedEntries[key] = []
                }
                groupedEntries[key]?.append(entry)
            }
            entriesByWeek = groupedEntries
            isLoading = false
        } catch {
            self.error = error
            isLoading = false
        }
    }

    // MARK: - Real-time Listener
    func startListening(forUser userId: String) {
        print("🎧 MemoryViewModel: Starting database listener for user: \(userId)")
        listenerRegistration = databaseService.observeEntries(userId: userId) { [weak self] entries in
            guard let self = self else { return }
            print("🔥 MemoryViewModel: Received \(entries.count) entries from Firestore")
            for entry in entries {
                print("  📝 Entry: week=\(entry.weekNumber), year=\(entry.weekYear), day=\(entry.dayOfWeek ?? 0), type=\(entry.entryType.rawValue), title=\(entry.title)")
            }

            // Group entries by week, supporting multiple entries per week
            var groupedEntries: [String: [WeekEntry]] = [:]
            for entry in entries {
                let key = self.weekKey(entry.weekYear, entry.weekNumber)
                if groupedEntries[key] == nil {
                    groupedEntries[key] = []
                }
                groupedEntries[key]?.append(entry)
            }
            self.entriesByWeek = groupedEntries

            let totalEntries = groupedEntries.values.reduce(0) { $0 + $1.count }
            print("📊 MemoryViewModel: entriesByWeek now has \(groupedEntries.count) weeks with \(totalEntries) total entries")
            print("📊 Keys in dictionary: \(Array(self.entriesByWeek.keys).sorted())")
        }
    }

    func stopListening() {
        if let listener = listenerRegistration {
            databaseService.removeListener(listener)
        }
        listenerRegistration = nil
    }

    // MARK: - Entry Queries
    func hasEntry(week: Int, year: Int, dayOfWeek: Int? = nil) -> Bool {
        guard let entries = entriesByWeek[weekKey(year, week)] else {
            return false
        }

        if let day = dayOfWeek {
            return entries.contains { $0.dayOfWeek == day }
        }
        return !entries.isEmpty
    }

    func getEntries(week: Int, year: Int, dayOfWeek: Int? = nil) -> [WeekEntry] {
        let key = weekKey(year, week)
        guard let entries = entriesByWeek[key] else {
            print("🔍 MemoryViewModel.getEntries: No entries for key '\(key)'")
            print("  Available keys: \(Array(entriesByWeek.keys).sorted())")
            return []
        }

        if let day = dayOfWeek {
            let filtered = entries.filter { $0.dayOfWeek == day }
            print("🔍 MemoryViewModel.getEntries: Found \(filtered.count) entries for key '\(key)' day \(day)")
            return filtered
        }

        print("🔍 MemoryViewModel.getEntries: Found \(entries.count) entries for key '\(key)'")
        return entries
    }

    // Legacy method for backward compatibility
    func getEntry(week: Int, year: Int) -> WeekEntry? {
        return getEntries(week: week, year: year).first
    }

    func getEntryType(week: Int, year: Int, dayOfWeek: Int? = nil) -> EntryType? {
        return getEntries(week: week, year: year, dayOfWeek: dayOfWeek).first?.entryType
    }

    // MARK: - CRUD Operations
    func createEntry(_ entry: WeekEntry) async throws {
        do {
            print("📝 MemoryViewModel.createEntry: Saving entry - week=\(entry.weekNumber), year=\(entry.weekYear), day=\(entry.dayOfWeek ?? 0)")
            try await databaseService.saveEntry(entry)
            let key = weekKey(entry.weekYear, entry.weekNumber)

            // Add to local cache - reassign the array to trigger @Published update
            var entries = entriesByWeek[key] ?? []
            entries.append(entry)
            entriesByWeek[key] = entries

            let totalEntries = entriesByWeek.values.reduce(0) { $0 + $1.count }
            print("✅ MemoryViewModel.createEntry: Saved successfully, added to local cache with key '\(key)'")
            print("  📊 Cache now has \(entriesByWeek.count) weeks with \(totalEntries) total entries")
        } catch {
            print("❌ MemoryViewModel.createEntry: Failed - \(error.localizedDescription)")
            self.error = error
            throw error
        }
    }

    func updateEntry(_ entry: WeekEntry) async throws {
        do {
            try await databaseService.updateEntry(entry)

            // Update in local cache
            let key = weekKey(entry.weekYear, entry.weekNumber)
            if var entries = entriesByWeek[key] {
                if let index = entries.firstIndex(where: { $0.id == entry.id }) {
                    entries[index] = entry
                    entriesByWeek[key] = entries
                }
            }
        } catch {
            self.error = error
            throw error
        }
    }

    func deleteEntry(_ entry: WeekEntry) async throws {
        print("🗑️ MemoryViewModel.deleteEntry: Starting deletion process")
        print("  Entry ID: \(entry.id.uuidString)")
        print("  Title: \(entry.title)")
        print("  Week: \(entry.weekNumber), Year: \(entry.weekYear)")
        print("  Type: \(entry.entryType.rawValue)")
        print("  Is recurring: \(entry.isRecurring)")
        print("  Photo URLs count: \(entry.photoURLs.count)")
        print("  Has audio: \(entry.audioURL != nil)")

        do {
            // If this is a recurring memory, delete all associated goals first
            if entry.isRecurring && entry.entryType == .memory {
                print("🔄 MemoryViewModel.deleteEntry: This is a recurring memory, finding associated goals")
                let associatedGoals = getAllEntries().filter { goal in
                    goal.entryType == .goal && goal.parentMemoryId == entry.id
                }
                print("  Found \(associatedGoals.count) associated goals to delete")

                // Delete from database first (all at once)
                for goal in associatedGoals {
                    print("  Deleting goal from database: \(goal.title) (week \(goal.weekNumber), year \(goal.weekYear))")
                    try await databaseService.deleteEntry(goal)
                }

                // Then update local cache in a single operation to avoid race conditions
                var updatedEntriesByWeek = entriesByWeek
                for goal in associatedGoals {
                    let goalKey = weekKey(goal.weekYear, goal.weekNumber)
                    if var entries = updatedEntriesByWeek[goalKey] {
                        entries.removeAll { $0.id == goal.id }
                        if entries.isEmpty {
                            updatedEntriesByWeek.removeValue(forKey: goalKey)
                        } else {
                            updatedEntriesByWeek[goalKey] = entries
                        }
                    }
                }
                // Update the published property once
                entriesByWeek = updatedEntriesByWeek

                print("✅ MemoryViewModel.deleteEntry: Deleted \(associatedGoals.count) associated goals")
            }

            // Delete media files - only if URLs are valid
            print("🖼️ MemoryViewModel.deleteEntry: Checking photos for deletion")
            for (index, photoURL) in entry.photoURLs.enumerated() {
                print("  Photo \(index): '\(photoURL)'")
                if photoURL.isEmpty {
                    print("    ⚠️ Photo URL is empty, skipping")
                } else if !isValidStorageURL(photoURL) {
                    print("    ⚠️ Photo URL is invalid, skipping")
                } else {
                    print("    ✅ Photo URL is valid, attempting deletion")
                    try? await storageService.deleteFile(at: photoURL)
                    print("    ✅ Photo deleted successfully")
                }
            }

            if let audioURL = entry.audioURL {
                print("🎵 MemoryViewModel.deleteEntry: Checking audio for deletion")
                print("  Audio URL: '\(audioURL)'")
                if audioURL.isEmpty {
                    print("    ⚠️ Audio URL is empty, skipping")
                } else if !isValidStorageURL(audioURL) {
                    print("    ⚠️ Audio URL is invalid, skipping")
                } else {
                    print("    ✅ Audio URL is valid, attempting deletion")
                    try? await storageService.deleteFile(at: audioURL)
                    print("    ✅ Audio deleted successfully")
                }
            }

            // Delete entry from database
            print("🔥 MemoryViewModel.deleteEntry: Deleting entry from database")
            try await databaseService.deleteEntry(entry)
            print("✅ MemoryViewModel.deleteEntry: Entry deleted from database")

            // Remove from local cache
            let key = weekKey(entry.weekYear, entry.weekNumber)
            print("📊 MemoryViewModel.deleteEntry: Updating local cache")
            print("  Cache key: '\(key)'")
            print("  Entries before deletion: \(entriesByWeek[key]?.count ?? 0)")

            if var entries = entriesByWeek[key] {
                entries.removeAll { $0.id == entry.id }
                print("  Entries after removal: \(entries.count)")

                if entries.isEmpty {
                    print("  No more entries for this week, removing key from cache")
                    entriesByWeek.removeValue(forKey: key)
                } else {
                    print("  Still have \(entries.count) entries for this week, updating cache")
                    entriesByWeek[key] = entries
                }
            } else {
                print("  ⚠️ No entries found in cache for key '\(key)'")
            }

            let totalEntries = entriesByWeek.values.reduce(0) { $0 + $1.count }
            print("✅ MemoryViewModel.deleteEntry: Deletion completed successfully")
            print("  Total entries remaining in cache: \(totalEntries)")
            print("  Total weeks in cache: \(entriesByWeek.count)")
        } catch {
            print("❌ MemoryViewModel.deleteEntry: Failed with error: \(error.localizedDescription)")
            print("  Error details: \(error)")
            self.error = error
            throw error
        }
    }

    // MARK: - Media Operations
    func uploadPhoto(_ image: UIImage, userId: String) async throws -> String {
        // Compress image
        guard let compressedImage = storageService.compressImage(image, maxSizeKB: 800) else {
            throw StorageError.invalidImage
        }

        return try await storageService.uploadPhoto(compressedImage, userId: userId) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
    }

    func uploadAudio(_ audioURL: URL, userId: String) async throws -> String {
        return try await storageService.uploadAudio(audioURL, userId: userId) { [weak self] progress in
            Task { @MainActor in
                self?.uploadProgress = progress
            }
        }
    }

    func downloadImage(from urlString: String) async throws -> UIImage {
        return try await storageService.downloadImage(from: urlString)
    }

    // MARK: - Helper Methods
    private func weekKey(_ year: Int, _ week: Int) -> String {
        return "\(year)-\(week)"
    }

    // Validate Firebase Storage URL
    private func isValidStorageURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme?.lowercased() else {
            return false
        }
        // Firebase Storage accepts gs://, http://, or https:// schemes
        return scheme == "gs" || scheme == "http" || scheme == "https"
    }

    // Get all entries sorted by date
    func getAllEntries() -> [WeekEntry] {
        return entriesByWeek.values.flatMap { $0 }.sorted { $0.createdAt > $1.createdAt }
    }

    // Get entries by type
    func getEntriesByType(_ type: EntryType) -> [WeekEntry] {
        return entriesByWeek.values.flatMap { $0 }
            .filter { $0.entryType == type }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // Get favorite entries
    func getFavoriteEntries() -> [WeekEntry] {
        return entriesByWeek.values.flatMap { $0 }
            .filter { $0.isFavorite }
            .sorted { $0.createdAt > $1.createdAt }
    }

    // Search entries
    func searchEntries(query: String) -> [WeekEntry] {
        let lowercasedQuery = query.lowercased()
        return entriesByWeek.values.flatMap { $0 }.filter { entry in
            entry.title.lowercased().contains(lowercasedQuery) ||
            (entry.description?.lowercased().contains(lowercasedQuery) ?? false) ||
            (entry.textContent?.lowercased().contains(lowercasedQuery) ?? false) ||
            entry.tags.contains { $0.lowercased().contains(lowercasedQuery) }
        }.sorted { $0.createdAt > $1.createdAt }
    }

    // MARK: - Goal Completion Conversion

    /// Check and convert completed goals to memories when their date has passed
    /// This should be called on app launch or when entries are loaded
    func convertCompletedGoalsToMemories(userBirthDate: Date) async {
        print("🔄 MemoryViewModel: Checking for completed goals to convert to memories")

        let calendar = Calendar.current
        let today = Date()
        let dateCalculator = DateCalculator()

        // Find all completed goals that should be converted
        let goalsToConvert = getAllEntries().filter { entry in
            guard entry.entryType == .goal,
                  entry.isCompleted,
                  entry.convertToMemoryWhenPassed else {
                return false
            }

            // Calculate the actual date of this goal
            guard let goalDate = dateCalculator.weekCoordinatesToDate(
                weekYear: entry.weekYear,
                weekNumber: entry.weekNumber,
                dayOfWeek: entry.dayOfWeek ?? 1,
                userBirthDate: userBirthDate
            ) else {
                return false
            }

            // Check if the goal date has passed
            return goalDate < today
        }

        print("  Found \(goalsToConvert.count) goals to convert to memories")

        for goal in goalsToConvert {
            do {
                // Create a new memory from the goal
                var memory = goal
                memory.id = UUID()  // New ID for the memory
                memory.entryType = .memory
                memory.createdAt = Date()
                memory.updatedAt = Date()
                // Keep the completion status but clear the conversion flag
                memory.convertToMemoryWhenPassed = false

                // Save the new memory
                try await createEntry(memory)
                print("  ✅ Created memory from goal: \(goal.title)")

                // Delete the original goal
                try await deleteEntry(goal)
                print("  ✅ Deleted original goal: \(goal.title)")

            } catch {
                print("  ❌ Failed to convert goal '\(goal.title)': \(error.localizedDescription)")
            }
        }

        if goalsToConvert.isEmpty {
            print("  No goals need to be converted")
        } else {
            print("✅ MemoryViewModel: Completed converting \(goalsToConvert.count) goals to memories")
        }
    }

    deinit {
        if let listener = listenerRegistration {
            databaseService.removeListener(listener)
        }
    }
}
