//
//  APIService.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation

class APIService {
    static let shared = APIService()

    private init() {}

    // MARK: - Fetch Industry Data
    func fetchIndustryData(industry: String, jobRole: String) async throws -> IndustryData {
        // First try to fetch from APIs
        if let data = try? await fetchFromBLS(industry: industry) {
            return data
        }

        // Fallback to local curated data
        return getFallbackData(industry: industry, jobRole: jobRole)
    }

    // MARK: - Bureau of Labor Statistics API
    private func fetchFromBLS(industry: String) async throws -> IndustryData? {
        // BLS API implementation
        // Note: BLS API requires registration for API key
        // For MVP, we'll use fallback data

        // The actual implementation would look like this:
        /*
        let apiKey = "YOUR_BLS_API_KEY"
        let url = URL(string: "\(Constants.API.blsBaseURL)/timeseries/data/")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "seriesid": ["CES0000000001"], // Average weekly hours
            "startyear": "2023",
            "endyear": "2024",
            "registrationkey": apiKey
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        // Parse and return data
        */

        return nil
    }

    // MARK: - OECD Data API
    private func fetchFromOECD(country: String = "USA") async throws -> Double? {
        // OECD API for international labor statistics
        // Returns average annual hours worked
        // For MVP, using fallback data

        return nil
    }

    // MARK: - Fallback Data
    private func getFallbackData(industry: String, jobRole: String) -> IndustryData {
        // Try to get specific industry data
        if let data = IndustryFallbackData.getData(for: industry) {
            // Customize with job role if needed
            return IndustryData(
                industry: industry,
                jobRole: jobRole.isEmpty ? data.jobRole : jobRole,
                averageWeeklyHours: data.averageWeeklyHours,
                averageCommuteMinutes: data.averageCommuteMinutes,
                averageOvertimeHours: data.averageOvertimeHours,
                retirementAge: data.retirementAge,
                country: data.country
            )
        }

        // If no specific data found, return general average
        return IndustryData(
            industry: industry,
            jobRole: jobRole,
            averageWeeklyHours: Constants.Defaults.defaultWorkHoursPerWeek,
            averageCommuteMinutes: Constants.Defaults.defaultCommuteMinutes,
            averageOvertimeHours: 4.0,
            retirementAge: Constants.Defaults.defaultRetirementAge,
            country: "Global Average"
        )
    }

    // MARK: - Life Expectancy Data
    func getLifeExpectancy(birthYear: Int, country: String = "USA") -> Double {
        // In a real implementation, this would fetch from WHO or CDC APIs
        // For now, using estimates based on birth year

        // Life expectancy has been increasing over time
        // These are rough estimates
        switch birthYear {
        case 1940...1950:
            return 75.0
        case 1951...1960:
            return 76.0
        case 1961...1970:
            return 77.0
        case 1971...1980:
            return 78.0
        case 1981...1990:
            return 79.0
        case 1991...2000:
            return 80.0
        case 2001...2010:
            return 81.0
        case 2011...2020:
            return 82.0
        default:
            return Constants.Defaults.defaultLifeExpectancy
        }
    }

    // MARK: - Country/Region Data
    func getCountryAverageHours(country: String = "USA") -> Double {
        // Average annual hours worked by country (OECD data estimates)
        let countryHours: [String: Double] = [
            "USA": 1791,
            "Canada": 1685,
            "UK": 1538,
            "Germany": 1349,
            "France": 1490,
            "Japan": 1607,
            "South Korea": 1908,
            "Australia": 1694,
            "Mexico": 2128,
            "Global Average": 1746
        ]

        let annualHours = countryHours[country] ?? countryHours["Global Average"]!
        return annualHours / 52.0 // Convert to weekly average
    }
}
