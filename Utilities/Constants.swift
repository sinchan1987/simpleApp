//
//  Constants.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct Constants {
    // MARK: - App Version
    struct AppVersion {
        static let current = "1.1.0"  // Goal completion feature
        static let build = 2

        // Version history for rollback reference
        // 1.0.0 (build 1) - Initial release with basic features
        // 1.1.0 (build 2) - Added goal completion feature
    }

    // MARK: - Animation Durations
    struct Animation {
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let verySlow: Double = 0.8

        // Spring animation presets
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.7)
        static let smooth = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let gentle = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.9)
    }

    // MARK: - Spacing & Sizing
    struct Layout {
        static let paddingSmall: CGFloat = 8
        static let paddingMedium: CGFloat = 16
        static let paddingLarge: CGFloat = 24
        static let paddingXLarge: CGFloat = 32

        static let cornerRadiusSmall: CGFloat = 8
        static let cornerRadiusMedium: CGFloat = 12
        static let cornerRadiusLarge: CGFloat = 16
        static let cornerRadiusXLarge: CGFloat = 24

        static let iconSizeSmall: CGFloat = 20
        static let iconSizeMedium: CGFloat = 24
        static let iconSizeLarge: CGFloat = 32
        static let iconSizeXLarge: CGFloat = 48

        static let buttonHeight: CGFloat = 56
        static let cardHeight: CGFloat = 120
    }

    // MARK: - Typography
    struct Typography {
        static let titleSize: CGFloat = 32
        static let headingSize: CGFloat = 24
        static let subheadingSize: CGFloat = 20
        static let bodySize: CGFloat = 16
        static let captionSize: CGFloat = 14
        static let smallSize: CGFloat = 12
    }

    // MARK: - API Endpoints
    struct API {
        // Bureau of Labor Statistics API
        static let blsBaseURL = "https://api.bls.gov/publicAPI/v2"

        // OECD Data API
        static let oecdBaseURL = "https://stats.oecd.org/restsdmx/sdmx.ashx/GetData"

        // Fallback: We'll use local data if APIs are unavailable
        static let useLocalFallback = true
    }

    // MARK: - Default Values
    struct Defaults {
        static let defaultRetirementAge = 65
        static let defaultLifeExpectancy = 78.5
        static let defaultWorkHoursPerWeek = 40.0
        static let defaultWorkDaysPerWeek = 5.0
        static let defaultSleepHoursPerDay = 7.0
        static let defaultCommuteMinutes = 25.0
    }

    // MARK: - Industry List
    static let industries = [
        "Technology",
        "Healthcare",
        "Finance",
        "Education",
        "Retail",
        "Manufacturing",
        "Hospitality",
        "Construction",
        "Marketing",
        "Legal",
        "Transportation",
        "Sales",
        "Engineering",
        "Media & Entertainment",
        "Real Estate",
        "Consulting",
        "Agriculture",
        "Arts & Design",
        "Government",
        "Non-Profit"
    ]

    // MARK: - Haptic Feedback
    struct Haptics {
        static let light = UIImpactFeedbackGenerator(style: .light)
        static let medium = UIImpactFeedbackGenerator(style: .medium)
        static let heavy = UIImpactFeedbackGenerator(style: .heavy)
        static let selection = UISelectionFeedbackGenerator()
        static let notification = UINotificationFeedbackGenerator()
    }

    // MARK: - Onboarding Steps
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case name = 1
        case dateOfBirth = 2
        case education = 3
        case work = 4
        case family = 5

        var title: String {
            switch self {
            case .welcome:
                return "Welcome"
            case .name:
                return "What's your name?"
            case .dateOfBirth:
                return "When were you born?"
            case .education:
                return "Tell us about your education"
            case .work:
                return "Tell us about your work"
            case .family:
                return "Tell us about your family"
            }
        }

        var subtitle: String {
            switch self {
            case .welcome:
                return "Discover how you're spending your one precious life"
            case .name:
                return "Let's make this personal"
            case .dateOfBirth:
                return "We'll use this to personalize your experience"
            case .education:
                return "Your educational background"
            case .work:
                return "This helps us estimate your work patterns"
            case .family:
                return "This helps us understand your life journey"
            }
        }

        var progress: Double {
            return Double(self.rawValue) / Double(OnboardingStep.allCases.count - 1)
        }
    }

    // MARK: - Degree Options
    static let degrees = [
        "High School",
        "Associate's Degree",
        "Bachelor's Degree",
        "Master's Degree",
        "Doctorate (PhD)",
        "Professional Degree (MD, JD, etc.)",
        "Trade/Vocational Certificate",
        "Some College",
        "Other"
    ]
}

// MARK: - String Extensions
extension String {
    var capitalizingFirstLetter: String {
        return prefix(1).capitalized + dropFirst()
    }
}

// MARK: - Date Extensions
extension Date {
    var ageString: String {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: self, to: Date())
        return "\(ageComponents.year ?? 0)"
    }
}
