//
//  IndustryData.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation

// Model for API responses
struct IndustryDataResponse: Codable {
    let industry: String
    let jobRole: String?
    let averageHoursPerWeek: Double
    let averageCommuteMinutes: Double
    let country: String
    let source: String
    let year: Int
}

// Comprehensive industry data model
struct IndustryData {
    let industry: String
    let jobRole: String
    let averageWeeklyHours: Double
    let averageCommuteMinutes: Double
    let averageOvertimeHours: Double
    let retirementAge: Int
    let country: String

    // Convert to work hours per day
    var averageHoursPerDay: Double {
        return averageWeeklyHours / 5.0 // Assuming 5-day work week
    }

    var averageCommuteHoursPerDay: Double {
        return (averageCommuteMinutes * 2) / 60.0 // Round trip in hours
    }
}

// Fallback data for common industries when API fails
struct IndustryFallbackData {
    static let data: [String: IndustryData] = [
        "Technology": IndustryData(
            industry: "Technology",
            jobRole: "Software Engineer",
            averageWeeklyHours: 42.0,
            averageCommuteMinutes: 28.0,
            averageOvertimeHours: 5.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Healthcare": IndustryData(
            industry: "Healthcare",
            jobRole: "Nurse",
            averageWeeklyHours: 40.0,
            averageCommuteMinutes: 25.0,
            averageOvertimeHours: 8.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Finance": IndustryData(
            industry: "Finance",
            jobRole: "Financial Analyst",
            averageWeeklyHours: 45.0,
            averageCommuteMinutes: 32.0,
            averageOvertimeHours: 10.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Education": IndustryData(
            industry: "Education",
            jobRole: "Teacher",
            averageWeeklyHours: 44.0,
            averageCommuteMinutes: 22.0,
            averageOvertimeHours: 7.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Retail": IndustryData(
            industry: "Retail",
            jobRole: "Retail Manager",
            averageWeeklyHours: 40.0,
            averageCommuteMinutes: 20.0,
            averageOvertimeHours: 5.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Manufacturing": IndustryData(
            industry: "Manufacturing",
            jobRole: "Production Worker",
            averageWeeklyHours: 40.0,
            averageCommuteMinutes: 26.0,
            averageOvertimeHours: 6.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Hospitality": IndustryData(
            industry: "Hospitality",
            jobRole: "Hotel Manager",
            averageWeeklyHours: 45.0,
            averageCommuteMinutes: 24.0,
            averageOvertimeHours: 8.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Construction": IndustryData(
            industry: "Construction",
            jobRole: "Construction Worker",
            averageWeeklyHours: 42.0,
            averageCommuteMinutes: 30.0,
            averageOvertimeHours: 6.0,
            retirementAge: 62,
            country: "Global Average"
        ),
        "Marketing": IndustryData(
            industry: "Marketing",
            jobRole: "Marketing Manager",
            averageWeeklyHours: 43.0,
            averageCommuteMinutes: 27.0,
            averageOvertimeHours: 7.0,
            retirementAge: 65,
            country: "Global Average"
        ),
        "Legal": IndustryData(
            industry: "Legal",
            jobRole: "Lawyer",
            averageWeeklyHours: 50.0,
            averageCommuteMinutes: 30.0,
            averageOvertimeHours: 15.0,
            retirementAge: 67,
            country: "Global Average"
        ),
        "Transportation": IndustryData(
            industry: "Transportation",
            jobRole: "Truck Driver",
            averageWeeklyHours: 48.0,
            averageCommuteMinutes: 15.0,
            averageOvertimeHours: 8.0,
            retirementAge: 62,
            country: "Global Average"
        ),
        "Sales": IndustryData(
            industry: "Sales",
            jobRole: "Sales Representative",
            averageWeeklyHours: 41.0,
            averageCommuteMinutes: 28.0,
            averageOvertimeHours: 6.0,
            retirementAge: 65,
            country: "Global Average"
        )
    ]

    static func getData(for industry: String) -> IndustryData? {
        return data[industry]
    }

    static var allIndustries: [String] {
        return Array(data.keys).sorted()
    }
}
