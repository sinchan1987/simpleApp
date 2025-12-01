//
//  WeekEntry.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation
import FirebaseFirestore

struct WeekEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var userId: String
    var weekYear: Int  // Which year of life (0-90)
    var weekNumber: Int  // Week in year (0-51)
    var entryType: EntryType
    var dayOfWeek: Int?  // 1-7 (Sun-Sat), optional

    // Content
    var title: String
    var description: String?
    var textContent: String?

    // Media
    var photoURLs: [String] = []
    var audioURL: String?

    // Location
    var locationName: String?
    var locationLatitude: Double?
    var locationLongitude: Double?

    // Metadata
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var tags: [String] = []
    var isFavorite: Bool = false

    // Reminder
    var reminderDate: Date?
    var reminderEnabled: Bool = false
    var notificationId: String?  // Store the notification identifier for cancellation

    // Recurring Reminder (for memories that generate future goals)
    var isRecurring: Bool = false
    var recurringFrequency: RecurringFrequency?
    var recurringEndDate: Date?
    var notificationLeadTime: Int?  // How many days/weeks/months before
    var notificationLeadTimeUnit: LeadTimeUnit?
    var parentMemoryId: UUID?  // For goals created from recurring memories, reference to original memory

    // Goal Completion
    var isCompleted: Bool = false
    var completedAt: Date?
    var convertToMemoryWhenPassed: Bool = false  // If true, convert goal to memory after goal date passes

    // Computed properties
    var isPast: Bool {
        // Calculate if this week is in the past based on weekYear
        // This would need the user's current age to determine
        return true // Placeholder - will be calculated in ViewModel
    }

    var displayDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
    }

    // Convert to Firestore dictionary
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "userId": userId,
            "weekYear": weekYear,
            "weekNumber": weekNumber,
            "entryType": entryType.rawValue,
            "dayOfWeek": dayOfWeek ?? NSNull(),
            "title": title,
            "description": description ?? "",
            "textContent": textContent ?? "",
            "photoURLs": photoURLs,
            "audioURL": audioURL ?? "",
            "createdAt": createdAt,
            "updatedAt": updatedAt,
            "tags": tags,
            "isFavorite": isFavorite,
            "reminderEnabled": reminderEnabled
        ]

        // Location fields
        if let locationName = locationName {
            dict["locationName"] = locationName
        }
        if let locationLatitude = locationLatitude {
            dict["locationLatitude"] = locationLatitude
        }
        if let locationLongitude = locationLongitude {
            dict["locationLongitude"] = locationLongitude
        }

        if let reminderDate = reminderDate {
            dict["reminderDate"] = reminderDate
        }
        if let notificationId = notificationId {
            dict["notificationId"] = notificationId
        }

        // Recurring reminder fields
        dict["isRecurring"] = isRecurring
        if let frequency = recurringFrequency {
            dict["recurringFrequency"] = frequency.rawValue
        }
        if let endDate = recurringEndDate {
            dict["recurringEndDate"] = endDate
        }
        if let leadTime = notificationLeadTime {
            dict["notificationLeadTime"] = leadTime
        }
        if let leadTimeUnit = notificationLeadTimeUnit {
            dict["notificationLeadTimeUnit"] = leadTimeUnit.rawValue
        }
        if let parentId = parentMemoryId {
            dict["parentMemoryId"] = parentId.uuidString
        }

        // Goal completion fields
        dict["isCompleted"] = isCompleted
        dict["convertToMemoryWhenPassed"] = convertToMemoryWhenPassed
        if let completedAt = completedAt {
            dict["completedAt"] = completedAt
        }

        return dict
    }

    // Initialize from Firestore dictionary
    static func fromDictionary(_ dict: [String: Any]) -> WeekEntry? {
        print("🔍 WeekEntry.fromDictionary: Attempting to parse entry")
        print("  Raw data: \(dict)")

        guard
            let idString = dict["id"] as? String,
            let id = UUID(uuidString: idString),
            let userId = dict["userId"] as? String,
            let weekYear = dict["weekYear"] as? Int,
            let weekNumber = dict["weekNumber"] as? Int,
            let entryTypeRaw = dict["entryType"] as? String,
            let entryType = EntryType(rawValue: entryTypeRaw),
            let title = dict["title"] as? String
        else {
            print("❌ WeekEntry.fromDictionary: Failed to parse required fields")
            if dict["id"] == nil { print("  Missing: id") }
            if dict["userId"] == nil { print("  Missing: userId") }
            if dict["weekYear"] == nil { print("  Missing: weekYear") }
            if dict["weekNumber"] == nil { print("  Missing: weekNumber") }
            if dict["entryType"] == nil { print("  Missing: entryType") }
            if dict["title"] == nil { print("  Missing: title") }
            return nil
        }

        // Handle Firestore Timestamp objects
        let createdAt: Date
        let updatedAt: Date

        if let timestamp = dict["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue()
        } else if let date = dict["createdAt"] as? Date {
            createdAt = date
        } else {
            print("⚠️ WeekEntry.fromDictionary: No valid createdAt, using current date")
            createdAt = Date()
        }

        if let timestamp = dict["updatedAt"] as? Timestamp {
            updatedAt = timestamp.dateValue()
        } else if let date = dict["updatedAt"] as? Date {
            updatedAt = date
        } else {
            print("⚠️ WeekEntry.fromDictionary: No valid updatedAt, using current date")
            updatedAt = Date()
        }

        // Parse reminder date
        let reminderDate: Date?
        if let timestamp = dict["reminderDate"] as? Timestamp {
            reminderDate = timestamp.dateValue()
        } else if let date = dict["reminderDate"] as? Date {
            reminderDate = date
        } else {
            reminderDate = nil
        }

        // Parse recurring end date
        let recurringEndDate: Date?
        if let timestamp = dict["recurringEndDate"] as? Timestamp {
            recurringEndDate = timestamp.dateValue()
        } else if let date = dict["recurringEndDate"] as? Date {
            recurringEndDate = date
        } else {
            recurringEndDate = nil
        }

        // Parse recurring frequency
        let recurringFrequency: RecurringFrequency?
        if let freqRaw = dict["recurringFrequency"] as? String {
            recurringFrequency = RecurringFrequency(rawValue: freqRaw)
        } else {
            recurringFrequency = nil
        }

        // Parse lead time unit
        let leadTimeUnit: LeadTimeUnit?
        if let unitRaw = dict["notificationLeadTimeUnit"] as? String {
            leadTimeUnit = LeadTimeUnit(rawValue: unitRaw)
        } else {
            leadTimeUnit = nil
        }

        // Parse parent memory ID
        let parentMemoryId: UUID?
        if let parentIdString = dict["parentMemoryId"] as? String {
            parentMemoryId = UUID(uuidString: parentIdString)
        } else {
            parentMemoryId = nil
        }

        // Parse completed at date
        let completedAt: Date?
        if let timestamp = dict["completedAt"] as? Timestamp {
            completedAt = timestamp.dateValue()
        } else if let date = dict["completedAt"] as? Date {
            completedAt = date
        } else {
            completedAt = nil
        }

        print("✅ WeekEntry.fromDictionary: Successfully parsed entry - week=\(weekNumber), year=\(weekYear), title=\(title)")

        return WeekEntry(
            id: id,
            userId: userId,
            weekYear: weekYear,
            weekNumber: weekNumber,
            entryType: entryType,
            dayOfWeek: dict["dayOfWeek"] as? Int,
            title: title,
            description: dict["description"] as? String,
            textContent: dict["textContent"] as? String,
            photoURLs: dict["photoURLs"] as? [String] ?? [],
            audioURL: dict["audioURL"] as? String,
            locationName: dict["locationName"] as? String,
            locationLatitude: dict["locationLatitude"] as? Double,
            locationLongitude: dict["locationLongitude"] as? Double,
            createdAt: createdAt,
            updatedAt: updatedAt,
            tags: dict["tags"] as? [String] ?? [],
            isFavorite: dict["isFavorite"] as? Bool ?? false,
            reminderDate: reminderDate,
            reminderEnabled: dict["reminderEnabled"] as? Bool ?? false,
            notificationId: dict["notificationId"] as? String,
            isRecurring: dict["isRecurring"] as? Bool ?? false,
            recurringFrequency: recurringFrequency,
            recurringEndDate: recurringEndDate,
            notificationLeadTime: dict["notificationLeadTime"] as? Int,
            notificationLeadTimeUnit: leadTimeUnit,
            parentMemoryId: parentMemoryId,
            isCompleted: dict["isCompleted"] as? Bool ?? false,
            completedAt: completedAt,
            convertToMemoryWhenPassed: dict["convertToMemoryWhenPassed"] as? Bool ?? false
        )
    }
}

enum EntryType: String, Codable, CaseIterable {
    case memory = "memory"
    case goal = "goal"

    var displayName: String {
        switch self {
        case .memory:
            return "Memory"
        case .goal:
            return "Goal"
        }
    }

    var icon: String {
        switch self {
        case .memory:
            return "photo.on.rectangle"
        case .goal:
            return "flag.fill"
        }
    }

    var color: String {
        switch self {
        case .memory:
            return "personalColor"
        case .goal:
            return "accent"
        }
    }
}

enum RecurringFrequency: String, Codable, CaseIterable {
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"

    var displayName: String {
        switch self {
        case .weekly:
            return "Weekly"
        case .biweekly:
            return "Bi-weekly"
        case .monthly:
            return "Monthly"
        case .yearly:
            return "Yearly"
        }
    }

    var interval: DateComponents {
        switch self {
        case .weekly:
            return DateComponents(weekOfYear: 1)
        case .biweekly:
            return DateComponents(weekOfYear: 2)
        case .monthly:
            return DateComponents(month: 1)
        case .yearly:
            return DateComponents(year: 1)
        }
    }
}

enum LeadTimeUnit: String, Codable, CaseIterable {
    case days = "days"
    case weeks = "weeks"
    case months = "months"

    var displayName: String {
        switch self {
        case .days:
            return "Days"
        case .weeks:
            return "Weeks"
        case .months:
            return "Months"
        }
    }

    var maxValue: Int {
        switch self {
        case .days:
            return 30
        case .weeks:
            return 52
        case .months:
            return 11
        }
    }
}
