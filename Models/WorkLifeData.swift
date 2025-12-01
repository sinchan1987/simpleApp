//
//  WorkLifeData.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation

struct WorkLifeData {
    // Work-related statistics
    let averageWorkHoursPerDay: Double
    let averageWorkDaysPerWeek: Double
    let averageCommuteHoursPerDay: Double
    let averageOvertimeHoursPerWeek: Double

    // Calculated work totals
    let totalHoursWorked: Double
    let totalDaysWorked: Double
    let totalWeeksWorked: Double
    let totalMonthsWorked: Double
    let totalYearsWorked: Double

    // Life statistics
    let currentAge: Int
    let lifeExpectancy: Double
    let yearsRemaining: Double

    // Breakdown percentages
    let workPercentage: Double
    let familyTimePercentage: Double
    let personalTimePercentage: Double
    let sleepPercentage: Double
    let otherPercentage: Double

    // Comparative data
    let industryAverageHours: Double
    let countryAverageHours: Double
    let comparisonToAverage: Double // Positive means working more than average

    // Projections
    let projectedRetirementAge: Int
    let projectedTotalWorkHours: Double
    let projectedWorkYearsRemaining: Double

    // Time breakdowns in different units
    var workHoursFormatted: String {
        return formatLargeNumber(totalHoursWorked)
    }

    var workDaysFormatted: String {
        return formatLargeNumber(totalDaysWorked)
    }

    // Helper function to format large numbers with commas
    private func formatLargeNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "\(Int(number))"
    }

    // Calculate percentage of life spent at work
    var lifeSpentAtWork: Double {
        let totalLifeHours = Double(currentAge) * 365.25 * 24
        return (totalHoursWorked / totalLifeHours) * 100
    }

    // Weekly breakdown
    var weeklyBreakdown: WeeklyBreakdown {
        WeeklyBreakdown(
            workHours: averageWorkHoursPerDay * averageWorkDaysPerWeek,
            commuteHours: averageCommuteHoursPerDay * averageWorkDaysPerWeek,
            familyHours: calculateFamilyHours(),
            personalHours: calculatePersonalHours(),
            sleepHours: 7 * 7 // Average 7 hours per night
        )
    }

    private func calculateFamilyHours() -> Double {
        // Estimate based on relationship status and kids
        // This is a placeholder - will be enhanced with more data
        return 20.0
    }

    private func calculatePersonalHours() -> Double {
        // Calculate remaining hours after work, commute, family, and sleep
        let totalWeekHours = 168.0
        let accountedHours = weeklyBreakdown.workHours +
                            weeklyBreakdown.commuteHours +
                            weeklyBreakdown.familyHours +
                            weeklyBreakdown.sleepHours
        return max(0, totalWeekHours - accountedHours)
    }
}

struct WeeklyBreakdown {
    let workHours: Double
    let commuteHours: Double
    let familyHours: Double
    let personalHours: Double
    let sleepHours: Double

    var totalHours: Double {
        return workHours + commuteHours + familyHours + personalHours + sleepHours
    }

    // Percentage calculations
    var workPercentage: Double {
        return (workHours / 168.0) * 100
    }

    var commutePercentage: Double {
        return (commuteHours / 168.0) * 100
    }

    var familyPercentage: Double {
        return (familyHours / 168.0) * 100
    }

    var personalPercentage: Double {
        return (personalHours / 168.0) * 100
    }

    var sleepPercentage: Double {
        return (sleepHours / 168.0) * 100
    }
}

// Life milestones for timeline visualization
struct LifeMilestone: Identifiable {
    let id = UUID()
    let age: Int
    let title: String
    let type: MilestoneType
    let date: Date

    enum MilestoneType {
        case birth
        case school
        case graduation
        case firstJob
        case career
        case family
        case current
        case retirement
    }
}
