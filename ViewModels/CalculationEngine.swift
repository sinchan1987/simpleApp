//
//  CalculationEngine.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation

class CalculationEngine {
    static let shared = CalculationEngine()

    private init() {}

    // MARK: - Main Calculation Function
    func calculateWorkLifeData(profile: UserProfile, industryData: IndustryData) -> WorkLifeData {
        let age = profile.age
        let yearsWorked = profile.yearsWorked

        // Get life expectancy
        let lifeExpectancy = APIService.shared.getLifeExpectancy(birthYear: profile.birthYear)

        // Calculate work statistics
        let avgHoursPerDay = industryData.averageHoursPerDay
        let avgDaysPerWeek = 5.0 // Standard work week
        let avgCommuteHoursPerDay = industryData.averageCommuteHoursPerDay
        let avgOvertimePerWeek = industryData.averageOvertimeHours

        // Total hours calculations
        let weeksPerYear = 52.0
        let totalWeeksWorked = yearsWorked * weeksPerYear
        let totalDaysWorked = totalWeeksWorked * avgDaysPerWeek
        let totalHoursWorked = (avgHoursPerDay * avgDaysPerWeek * totalWeeksWorked) + (avgOvertimePerWeek * yearsWorked * weeksPerYear)

        // Life calculations
        let yearsRemaining = max(0, lifeExpectancy - Double(age))
        let projectedRetirementAge = industryData.retirementAge
        let projectedWorkYearsRemaining = max(0, Double(projectedRetirementAge - age))

        // Projected total work
        let projectedTotalWorkHours = totalHoursWorked + (avgHoursPerDay * avgDaysPerWeek * projectedWorkYearsRemaining * weeksPerYear)

        // Time breakdown percentages (weekly basis for accuracy)
        let weeklyWorkHours = avgHoursPerDay * avgDaysPerWeek
        let weeklyCommuteHours = avgCommuteHoursPerDay * avgDaysPerWeek
        let weeklySleepHours = Constants.Defaults.defaultSleepHoursPerDay * 7
        let weeklyFamilyHours = calculateFamilyTime(profile: profile)
        let weeklyPersonalHours = max(0, 168 - weeklyWorkHours - weeklyCommuteHours - weeklySleepHours - weeklyFamilyHours)

        let totalWeeklyHours = 168.0

        let workPercentage = ((weeklyWorkHours + weeklyCommuteHours) / totalWeeklyHours) * 100
        let familyTimePercentage = (weeklyFamilyHours / totalWeeklyHours) * 100
        let personalTimePercentage = (weeklyPersonalHours / totalWeeklyHours) * 100
        let sleepPercentage = (weeklySleepHours / totalWeeklyHours) * 100
        let otherPercentage = max(0, 100 - workPercentage - familyTimePercentage - personalTimePercentage - sleepPercentage)

        // Comparative data
        let countryAverage = APIService.shared.getCountryAverageHours()
        let comparison = (avgHoursPerDay * avgDaysPerWeek) - countryAverage

        return WorkLifeData(
            averageWorkHoursPerDay: avgHoursPerDay,
            averageWorkDaysPerWeek: avgDaysPerWeek,
            averageCommuteHoursPerDay: avgCommuteHoursPerDay,
            averageOvertimeHoursPerWeek: avgOvertimePerWeek,
            totalHoursWorked: totalHoursWorked,
            totalDaysWorked: totalDaysWorked,
            totalWeeksWorked: totalWeeksWorked,
            totalMonthsWorked: totalWeeksWorked / 4.33,
            totalYearsWorked: yearsWorked,
            currentAge: age,
            lifeExpectancy: lifeExpectancy,
            yearsRemaining: yearsRemaining,
            workPercentage: workPercentage,
            familyTimePercentage: familyTimePercentage,
            personalTimePercentage: personalTimePercentage,
            sleepPercentage: sleepPercentage,
            otherPercentage: otherPercentage,
            industryAverageHours: avgHoursPerDay * avgDaysPerWeek,
            countryAverageHours: countryAverage,
            comparisonToAverage: comparison,
            projectedRetirementAge: projectedRetirementAge,
            projectedTotalWorkHours: projectedTotalWorkHours,
            projectedWorkYearsRemaining: projectedWorkYearsRemaining
        )
    }

    // MARK: - Family Time Calculation
    private func calculateFamilyTime(profile: UserProfile) -> Double {
        var familyHours = 0.0

        // Base family time
        switch profile.relationshipStatus {
        case .single:
            familyHours = 5.0
        case .inRelationship:
            familyHours = 12.0
        case .married:
            familyHours = 15.0
        case .divorced:
            familyHours = 8.0
        case .widowed:
            familyHours = 6.0
        }

        // Add time for kids
        familyHours += Double(profile.numberOfKids) * 10.0

        // Add time for pets
        familyHours += Double(profile.numberOfPets) * 3.0

        // Cap at reasonable maximum (70 hours per week)
        return min(familyHours, 70.0)
    }

    // MARK: - Life Milestones Generation
    func generateMilestones(profile: UserProfile) -> [LifeMilestone] {
        var milestones: [LifeMilestone] = []

        let calendar = Calendar.current
        let birthDate = profile.dateOfBirth

        // Birth
        milestones.append(LifeMilestone(
            age: 0,
            title: "Born",
            type: .birth,
            date: birthDate
        ))

        // School start (age 5)
        if profile.age >= 5 {
            if let schoolDate = calendar.date(byAdding: .year, value: 5, to: birthDate) {
                milestones.append(LifeMilestone(
                    age: 5,
                    title: "Started School",
                    type: .school,
                    date: schoolDate
                ))
            }
        }

        // High school graduation (age 18)
        if profile.age >= 18 {
            if let hsGradDate = calendar.date(byAdding: .year, value: 18, to: birthDate) {
                milestones.append(LifeMilestone(
                    age: 18,
                    title: "High School Graduation",
                    type: .graduation,
                    date: hsGradDate
                ))
            }
        }

        // First job (estimated)
        let firstJobAge = profile.age - Int(profile.yearsWorked)
        if firstJobAge > 0 && firstJobAge <= profile.age {
            if let firstJobDate = calendar.date(byAdding: .year, value: firstJobAge, to: birthDate) {
                milestones.append(LifeMilestone(
                    age: firstJobAge,
                    title: "Started Career",
                    type: .firstJob,
                    date: firstJobDate
                ))
            }
        }

        // Current age
        milestones.append(LifeMilestone(
            age: profile.age,
            title: "Today",
            type: .current,
            date: Date()
        ))

        // Sort by age
        return milestones.sorted { $0.age < $1.age }
    }

    // MARK: - What-If Scenario Calculator
    func calculateWhatIf(
        currentData: WorkLifeData,
        newWeeklyHours: Double,
        newRetirementAge: Int
    ) -> WorkLifeData {
        // Recalculate with new parameters
        // This allows users to see "what if I worked less" scenarios

        let newHoursPerDay = newWeeklyHours / 5.0
        let yearsToRetirement = Double(newRetirementAge - currentData.currentAge)

        let projectedHours = newHoursPerDay * 5.0 * 52.0 * yearsToRetirement

        // Create modified data
        return WorkLifeData(
            averageWorkHoursPerDay: newHoursPerDay,
            averageWorkDaysPerWeek: 5.0,
            averageCommuteHoursPerDay: currentData.averageCommuteHoursPerDay,
            averageOvertimeHoursPerWeek: 0,
            totalHoursWorked: currentData.totalHoursWorked,
            totalDaysWorked: currentData.totalDaysWorked,
            totalWeeksWorked: currentData.totalWeeksWorked,
            totalMonthsWorked: currentData.totalMonthsWorked,
            totalYearsWorked: currentData.totalYearsWorked,
            currentAge: currentData.currentAge,
            lifeExpectancy: currentData.lifeExpectancy,
            yearsRemaining: currentData.yearsRemaining,
            workPercentage: (newWeeklyHours / 168.0) * 100,
            familyTimePercentage: currentData.familyTimePercentage,
            personalTimePercentage: currentData.personalTimePercentage,
            sleepPercentage: currentData.sleepPercentage,
            otherPercentage: currentData.otherPercentage,
            industryAverageHours: currentData.industryAverageHours,
            countryAverageHours: currentData.countryAverageHours,
            comparisonToAverage: newWeeklyHours - currentData.countryAverageHours,
            projectedRetirementAge: newRetirementAge,
            projectedTotalWorkHours: currentData.totalHoursWorked + projectedHours,
            projectedWorkYearsRemaining: yearsToRetirement
        )
    }
}
