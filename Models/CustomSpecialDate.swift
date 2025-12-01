//
//  CustomSpecialDate.swift
//  simpleApp
//
//  User-defined special dates with associated recurring goals
//

import Foundation
import SwiftUI

// MARK: - Custom Special Date
/// Represents a user-created special date that can have associated recurring goals
struct CustomSpecialDate: Codable, Identifiable, Equatable {
    var id: UUID
    var userId: String
    var name: String
    var date: Date
    var category: SpecialDateCategory
    var isRecurring: Bool
    var notes: String?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        userId: String,
        name: String,
        date: Date,
        category: SpecialDateCategory,
        isRecurring: Bool = true,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.name = name
        self.date = date
        self.category = category
        self.isRecurring = isRecurring
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Dictionary Conversion
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "userId": userId,
            "name": name,
            "date": date,
            "category": category.rawValue,
            "isRecurring": isRecurring,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]

        if let notes = notes {
            dict["notes"] = notes
        }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> CustomSpecialDate? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let userId = dict["userId"] as? String,
              let name = dict["name"] as? String,
              let categoryString = dict["category"] as? String,
              let category = SpecialDateCategory(rawValue: categoryString) else {
            print("❌ CustomSpecialDate.fromDictionary: Failed to parse required fields")
            return nil
        }

        // Parse date
        var date = Date()
        if let timestamp = dict["date"] as? Date {
            date = timestamp
        }

        // Parse created/updated dates
        var createdAt = Date()
        var updatedAt = Date()
        if let timestamp = dict["createdAt"] as? Date {
            createdAt = timestamp
        }
        if let timestamp = dict["updatedAt"] as? Date {
            updatedAt = timestamp
        }

        return CustomSpecialDate(
            id: id,
            userId: userId,
            name: name,
            date: date,
            category: category,
            isRecurring: dict["isRecurring"] as? Bool ?? true,
            notes: dict["notes"] as? String,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - Computed Properties

    /// Get the month and day for recurring date matching
    var monthDay: (month: Int, day: Int) {
        let calendar = Calendar.current
        return (
            calendar.component(.month, from: date),
            calendar.component(.day, from: date)
        )
    }

    /// Get the year of the original date
    var year: Int {
        Calendar.current.component(.year, from: date)
    }

    /// Check if this special date occurs on a given date
    func occursOn(_ checkDate: Date) -> Bool {
        let calendar = Calendar.current
        let checkMonth = calendar.component(.month, from: checkDate)
        let checkDay = calendar.component(.day, from: checkDate)
        let checkYear = calendar.component(.year, from: checkDate)

        // Must be on or after the original year
        guard checkYear >= year else { return false }

        if isRecurring {
            // Match month and day for recurring dates
            return checkMonth == monthDay.month && checkDay == monthDay.day
        } else {
            // Match exact date for one-time dates
            return calendar.isDate(date, inSameDayAs: checkDate)
        }
    }
}

// MARK: - Special Date Category
/// Categories for special dates with associated icons and colors
enum SpecialDateCategory: String, Codable, CaseIterable {
    // Personal
    case birthday = "birthday"
    case anniversary = "anniversary"
    case memorial = "memorial"

    // Family
    case familyBirthday = "family_birthday"
    case familyAnniversary = "family_anniversary"

    // Professional
    case workAnniversary = "work_anniversary"
    case achievement = "achievement"

    // Religious/Cultural
    case religious = "religious"
    case cultural = "cultural"

    // Health
    case health = "health"

    // Travel
    case travel = "travel"

    // Custom
    case custom = "custom"

    var displayName: String {
        switch self {
        case .birthday: return "Birthday"
        case .anniversary: return "Anniversary"
        case .memorial: return "Memorial"
        case .familyBirthday: return "Family Birthday"
        case .familyAnniversary: return "Family Anniversary"
        case .workAnniversary: return "Work Anniversary"
        case .achievement: return "Achievement"
        case .religious: return "Religious"
        case .cultural: return "Cultural"
        case .health: return "Health"
        case .travel: return "Travel"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .birthday: return "gift.fill"
        case .anniversary: return "heart.fill"
        case .memorial: return "flame.fill"
        case .familyBirthday: return "figure.2.and.child.holdinghands"
        case .familyAnniversary: return "house.fill"
        case .workAnniversary: return "briefcase.fill"
        case .achievement: return "trophy.fill"
        case .religious: return "hands.and.sparkles.fill"
        case .cultural: return "globe"
        case .health: return "heart.text.square.fill"
        case .travel: return "airplane"
        case .custom: return "star.fill"
        }
    }

    var color: Color {
        switch self {
        case .birthday: return Color.yellow
        case .anniversary: return Color.pink
        case .memorial: return Color.purple
        case .familyBirthday: return Color.blue.opacity(0.7)
        case .familyAnniversary: return Color.orange.opacity(0.7)
        case .workAnniversary: return Color.brown
        case .achievement: return Color.orange
        case .religious: return Color.indigo
        case .cultural: return Color.teal
        case .health: return Color.red.opacity(0.7)
        case .travel: return Color.cyan
        case .custom: return Color.gray
        }
    }

    /// Group categories for UI display
    static var grouped: [(String, [SpecialDateCategory])] {
        return [
            ("Personal", [.birthday, .anniversary, .memorial]),
            ("Family", [.familyBirthday, .familyAnniversary]),
            ("Professional", [.workAnniversary, .achievement]),
            ("Lifestyle", [.religious, .cultural, .health, .travel]),
            ("Other", [.custom])
        ]
    }
}

// MARK: - Special Date Goal
/// Represents a recurring goal associated with a special date
struct SpecialDateGoal: Codable, Identifiable, Equatable {
    var id: UUID
    var specialDateId: UUID
    var userId: String
    var goalTitle: String
    var goalDescription: String?
    var frequency: RecurringFrequency
    var reminderEnabled: Bool
    var reminderLeadTime: Int?
    var reminderLeadTimeUnit: LeadTimeUnit?
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        specialDateId: UUID,
        userId: String,
        goalTitle: String,
        goalDescription: String? = nil,
        frequency: RecurringFrequency = .yearly,
        reminderEnabled: Bool = false,
        reminderLeadTime: Int? = nil,
        reminderLeadTimeUnit: LeadTimeUnit? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.specialDateId = specialDateId
        self.userId = userId
        self.goalTitle = goalTitle
        self.goalDescription = goalDescription
        self.frequency = frequency
        self.reminderEnabled = reminderEnabled
        self.reminderLeadTime = reminderLeadTime
        self.reminderLeadTimeUnit = reminderLeadTimeUnit
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Dictionary Conversion
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "specialDateId": specialDateId.uuidString,
            "userId": userId,
            "goalTitle": goalTitle,
            "frequency": frequency.rawValue,
            "reminderEnabled": reminderEnabled,
            "isActive": isActive,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]

        if let description = goalDescription {
            dict["goalDescription"] = description
        }
        if let leadTime = reminderLeadTime {
            dict["reminderLeadTime"] = leadTime
        }
        if let leadTimeUnit = reminderLeadTimeUnit {
            dict["reminderLeadTimeUnit"] = leadTimeUnit.rawValue
        }

        return dict
    }

    static func fromDictionary(_ dict: [String: Any]) -> SpecialDateGoal? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let specialDateIdString = dict["specialDateId"] as? String,
              let specialDateId = UUID(uuidString: specialDateIdString),
              let userId = dict["userId"] as? String,
              let goalTitle = dict["goalTitle"] as? String,
              let frequencyString = dict["frequency"] as? String,
              let frequency = RecurringFrequency(rawValue: frequencyString) else {
            print("❌ SpecialDateGoal.fromDictionary: Failed to parse required fields")
            return nil
        }

        // Parse lead time unit
        var leadTimeUnit: LeadTimeUnit? = nil
        if let unitString = dict["reminderLeadTimeUnit"] as? String {
            leadTimeUnit = LeadTimeUnit(rawValue: unitString)
        }

        // Parse dates
        var createdAt = Date()
        var updatedAt = Date()
        if let timestamp = dict["createdAt"] as? Date {
            createdAt = timestamp
        }
        if let timestamp = dict["updatedAt"] as? Date {
            updatedAt = timestamp
        }

        return SpecialDateGoal(
            id: id,
            specialDateId: specialDateId,
            userId: userId,
            goalTitle: goalTitle,
            goalDescription: dict["goalDescription"] as? String,
            frequency: frequency,
            reminderEnabled: dict["reminderEnabled"] as? Bool ?? false,
            reminderLeadTime: dict["reminderLeadTime"] as? Int,
            reminderLeadTimeUnit: leadTimeUnit,
            isActive: dict["isActive"] as? Bool ?? true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Combined Special Date
/// A unified representation of both system-derived and custom special dates
struct CombinedSpecialDate: Identifiable, Equatable {
    let id: UUID
    let name: String
    let date: Date
    let category: SpecialDateCategory
    let isCustom: Bool
    let isRecurring: Bool
    let notes: String?
    let sourceType: SourceType

    enum SourceType: Equatable {
        case system(SpecialDateType)
        case custom(CustomSpecialDate)
    }

    /// Convert system SpecialDateType to SpecialDateCategory
    static func categoryFrom(type: SpecialDateType) -> SpecialDateCategory {
        switch type {
        case .birthday: return .birthday
        case .anniversary: return .anniversary
        case .spouseBirthday: return .familyBirthday
        case .childBirthday: return .familyBirthday
        case .petBirthday: return .familyBirthday
        case .graduation: return .achievement
        }
    }

    /// Create from system special date
    static func fromSystem(date: Date, type: SpecialDateType, label: String) -> CombinedSpecialDate {
        return CombinedSpecialDate(
            id: UUID(),
            name: label,
            date: date,
            category: categoryFrom(type: type),
            isCustom: false,
            isRecurring: type != .graduation,
            notes: nil,
            sourceType: .system(type)
        )
    }

    /// Create from custom special date
    static func fromCustom(_ customDate: CustomSpecialDate) -> CombinedSpecialDate {
        return CombinedSpecialDate(
            id: customDate.id,
            name: customDate.name,
            date: customDate.date,
            category: customDate.category,
            isCustom: true,
            isRecurring: customDate.isRecurring,
            notes: customDate.notes,
            sourceType: .custom(customDate)
        )
    }

    // MARK: - Computed Properties

    var icon: String {
        category.icon
    }

    var color: Color {
        category.color
    }

    var monthDay: (month: Int, day: Int) {
        let calendar = Calendar.current
        return (
            calendar.component(.month, from: date),
            calendar.component(.day, from: date)
        )
    }

    /// Days until next occurrence
    var daysUntilNext: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Get this year's occurrence
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = calendar.component(.year, from: today)

        guard let thisYearDate = calendar.date(from: components) else { return 0 }

        let targetDate: Date
        if thisYearDate >= today {
            targetDate = thisYearDate
        } else {
            // Next year
            components.year = (components.year ?? 0) + 1
            targetDate = calendar.date(from: components) ?? thisYearDate
        }

        return calendar.dateComponents([.day], from: today, to: targetDate).day ?? 0
    }

    /// Formatted string for next occurrence
    var nextOccurrenceText: String {
        let days = daysUntilNext
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Tomorrow"
        } else if days < 7 {
            return "In \(days) days"
        } else if days < 30 {
            let weeks = days / 7
            return "In \(weeks) week\(weeks == 1 ? "" : "s")"
        } else {
            let months = days / 30
            return "In \(months) month\(months == 1 ? "" : "s")"
        }
    }
}
