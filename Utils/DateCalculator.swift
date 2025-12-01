//
//  DateCalculator.swift
//  simpleApp
//
//  Centralized date/week calculation utility
//  All date-to-week and week-to-date conversions must use this utility
//

import Foundation

/// Centralized utility for consistent date and week calculations
/// This ensures all parts of the app use the same formula
struct DateCalculator {
    private let calendar = Calendar.current

    /// Converts a calendar date to week coordinates
    /// - Parameters:
    ///   - date: The calendar date
    ///   - userBirthDate: The user's birth date
    /// - Returns: (weekYear: age, weekNumber: 0-51, dayOfWeek: 1-7)
    func dateToWeekCoordinates(date: Date, userBirthDate: Date) -> (weekYear: Int, weekNumber: Int, dayOfWeek: Int) {
        // Calculate age (which year of life)
        let birthYear = calendar.component(.year, from: userBirthDate)
        let dateYear = calendar.component(.year, from: date)
        let age = dateYear - birthYear

        // Get January 1st of the date's year
        guard let yearStart = calendar.date(from: DateComponents(year: dateYear, month: 1, day: 1)) else {
            return (age, 0, 1)
        }

        // Calculate days since January 1st (0-indexed)
        let daysSinceYearStart = calendar.dateComponents([.day], from: yearStart, to: date).day ?? 0

        // Week number is simply daysSinceYearStart / 7 (integer division)
        let weekNumber = daysSinceYearStart / 7

        // Day of week is the remainder + 1 (to make it 1-indexed)
        // This represents the position within our calculated week (1-7)
        let dayOfWeek = (daysSinceYearStart % 7) + 1

        return (weekYear: age, weekNumber: weekNumber, dayOfWeek: dayOfWeek)
    }

    /// Converts week coordinates to a calendar date
    /// - Parameters:
    ///   - weekYear: Age (year of life)
    ///   - weekNumber: Week number within the year (0-51)
    ///   - dayOfWeek: Day position within the week (1-7)
    ///   - userBirthDate: The user's birth date
    /// - Returns: The calendar date
    func weekCoordinatesToDate(weekYear: Int, weekNumber: Int, dayOfWeek: Int, userBirthDate: Date) -> Date? {
        // Calculate the calendar year
        let birthYear = calendar.component(.year, from: userBirthDate)
        let calendarYear = birthYear + weekYear

        // Get January 1st of that year
        guard let yearStart = calendar.date(from: DateComponents(year: calendarYear, month: 1, day: 1)) else {
            return nil
        }

        // Calculate total days from year start
        // Formula: weekNumber * 7 + (dayOfWeek - 1)
        let totalDays = (weekNumber * 7) + (dayOfWeek - 1)

        // Add those days to January 1st
        return calendar.date(byAdding: .day, value: totalDays, to: yearStart)
    }

    /// Get the calendar year for a given week year (age)
    func calendarYear(forWeekYear weekYear: Int, userBirthDate: Date) -> Int {
        let birthYear = calendar.component(.year, from: userBirthDate)
        return birthYear + weekYear
    }
}
