//
//  ColorSchemes.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct AppColors {
    // Primary warm, inviting color palette
    static let primary = Color(red: 1.0, green: 0.42, blue: 0.42) // Soft coral #FF6B6B
    static let secondary = Color(red: 0.58, green: 0.88, blue: 0.70) // Sage green #95E1B3
    static let accent = Color(red: 1.0, green: 0.85, blue: 0.24) // Warm gold #FFD93D
    static let background = Color(red: 0.98, green: 0.98, blue: 0.96) // Cream #FAF9F6

    // Semantic colors
    static let workColor = Color(red: 0.96, green: 0.49, blue: 0.38) // Terracotta for work
    static let familyColor = Color(red: 0.67, green: 0.85, blue: 0.90) // Soft blue for family
    static let personalColor = Color(red: 0.85, green: 0.71, blue: 0.85) // Lavender for personal time
    static let sleepColor = Color(red: 0.45, green: 0.51, blue: 0.73) // Muted indigo for sleep
    static let commuteColor = Color(red: 0.95, green: 0.77, blue: 0.62) // Peach for commute

    // Text colors
    static let textPrimary = Color(red: 0.2, green: 0.2, blue: 0.2)
    static let textSecondary = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let textLight = Color.white

    // Dark mode variations
    static let darkBackground = Color(red: 0.11, green: 0.13, blue: 0.18) // Deep navy
    static let darkCard = Color(red: 0.16, green: 0.19, blue: 0.24)
}

// Nostalgia-themed color schemes based on era
struct NostalgiaColors {
    // 1980s - Neon and bright colors
    static let eighties = NostalgicColorScheme(
        primary: Color(red: 1.0, green: 0.2, blue: 0.6), // Hot pink
        secondary: Color(red: 0.0, green: 0.95, blue: 0.95), // Cyan
        accent: Color(red: 1.0, green: 1.0, blue: 0.0), // Bright yellow
        background: Color(red: 0.1, green: 0.1, blue: 0.15), // Dark with neon contrast
        gradient: LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.2, blue: 0.6),
                Color(red: 0.5, green: 0.0, blue: 0.8),
                Color(red: 0.0, green: 0.5, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    // 1990s - Windows 95 / early internet
    static let nineties = NostalgicColorScheme(
        primary: Color(red: 0.0, green: 0.5, blue: 0.5), // Teal
        secondary: Color(red: 0.75, green: 0.75, blue: 0.75), // Windows grey
        accent: Color(red: 1.0, green: 0.65, blue: 0.0), // Orange
        background: Color(red: 0.0, green: 0.5, blue: 0.5).opacity(0.1),
        gradient: LinearGradient(
            colors: [
                Color(red: 0.0, green: 0.5, blue: 0.5),
                Color(red: 0.0, green: 0.3, blue: 0.6)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    )

    // 2000s - iPod / iTunes era
    static let earlyTwoThousands = NostalgicColorScheme(
        primary: Color(red: 0.2, green: 0.6, blue: 1.0), // iTunes blue
        secondary: Color(red: 0.9, green: 0.9, blue: 0.9), // iPod white
        accent: Color(red: 0.0, green: 0.8, blue: 0.4), // Bright green
        background: Color(red: 0.95, green: 0.95, blue: 0.95),
        gradient: LinearGradient(
            colors: [
                Color(red: 0.9, green: 0.9, blue: 0.95),
                Color(red: 0.7, green: 0.8, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    // 2010s - Instagram / early smartphone
    static let twentyTens = NostalgicColorScheme(
        primary: Color(red: 0.95, green: 0.38, blue: 0.51), // Instagram pink
        secondary: Color(red: 1.0, green: 0.76, blue: 0.33), // Instagram orange
        accent: Color(red: 0.51, green: 0.38, blue: 0.95), // Instagram purple
        background: Color(red: 0.98, green: 0.98, blue: 0.99),
        gradient: LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.38, blue: 0.51),
                Color(red: 1.0, green: 0.76, blue: 0.33),
                Color(red: 0.51, green: 0.38, blue: 0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    // Modern - Clean and minimal
    static let modern = NostalgicColorScheme(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        accent: AppColors.accent,
        background: AppColors.background,
        gradient: LinearGradient(
            colors: [
                AppColors.primary.opacity(0.3),
                AppColors.secondary.opacity(0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )

    static func getScheme(for era: NostalgiaEra) -> NostalgicColorScheme {
        switch era {
        case .eighties:
            return eighties
        case .nineties:
            return nineties
        case .earlyTwoThousands:
            return earlyTwoThousands
        case .twentyTens:
            return twentyTens
        case .modern:
            return modern
        }
    }
}

struct NostalgicColorScheme {
    let primary: Color
    let secondary: Color
    let accent: Color
    let background: Color
    let gradient: LinearGradient
}

// Extension for creating gradients easily
extension Color {
    static func gradient(_ colors: [Color], startPoint: UnitPoint = .top, endPoint: UnitPoint = .bottom) -> LinearGradient {
        LinearGradient(colors: colors, startPoint: startPoint, endPoint: endPoint)
    }
}
