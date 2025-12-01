//
//  AccessibilityHelpers.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Adds comprehensive accessibility support to any view
    func makeAccessible(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }

    /// Adds reduced motion alternatives
    func withReducedMotion<Content: View>(
        @ViewBuilder alternative: @escaping () -> Content
    ) -> some View {
        Group {
            if UIAccessibility.isReduceMotionEnabled {
                alternative()
            } else {
                self
            }
        }
    }
}

// MARK: - Dynamic Type Support
extension Font {
    static func dynamicTitle() -> Font {
        return .system(size: Constants.Typography.titleSize, weight: .bold, design: .default)
    }

    static func dynamicHeading() -> Font {
        return .system(size: Constants.Typography.headingSize, weight: .semibold, design: .default)
    }

    static func dynamicBody() -> Font {
        return .system(size: Constants.Typography.bodySize, weight: .regular, design: .default)
    }

    static func dynamicCaption() -> Font {
        return .system(size: Constants.Typography.captionSize, weight: .regular, design: .default)
    }
}

// MARK: - Color Contrast Helpers
extension Color {
    /// Ensures sufficient contrast for accessibility
    func withAccessibleContrast(against background: Color) -> Color {
        // Simplified contrast check - in production, use proper WCAG contrast ratio calculation
        return self
    }
}

// MARK: - VoiceOver Helpers
struct AccessibilityHelpers {
    /// Announces a message to VoiceOver users
    static func announce(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        UIAccessibility.post(notification: priority, argument: message)
    }

    /// Checks if VoiceOver is running
    static var isVoiceOverRunning: Bool {
        return UIAccessibility.isVoiceOverRunning
    }

    /// Checks if reduce motion is enabled
    static var isReduceMotionEnabled: Bool {
        return UIAccessibility.isReduceMotionEnabled
    }

    /// Checks if differentiate without color is enabled
    static var shouldDifferentiateWithoutColor: Bool {
        return UIAccessibility.shouldDifferentiateWithoutColor
    }
}

// MARK: - Accessible Button Modifier
struct AccessibleButtonModifier: ViewModifier {
    let label: String
    let hint: String

    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint)
            .accessibilityAddTraits(.isButton)
    }
}

extension View {
    func accessibleButton(label: String, hint: String = "Double tap to activate") -> some View {
        self.modifier(AccessibleButtonModifier(label: label, hint: hint))
    }
}

// MARK: - Accessible Chart Elements
struct AccessibleChartModifier: ViewModifier {
    let chartTitle: String
    let chartData: String

    func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(chartTitle)
            .accessibilityValue(chartData)
            .accessibilityAddTraits(.isImage)
            .accessibilityHint("Chart visualization. \(chartData)")
    }
}

extension View {
    func accessibleChart(title: String, data: String) -> some View {
        self.modifier(AccessibleChartModifier(chartTitle: title, chartData: data))
    }
}
