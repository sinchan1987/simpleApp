//
//  NostalgiaThemeEngine.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI
import Combine

class NostalgiaThemeEngine: ObservableObject {
    @Published var currentScheme: NostalgicColorScheme
    @Published var currentEra: NostalgiaEra

    init(birthYear: Int = 1990) {
        let era = NostalgiaThemeEngine.determineEra(from: birthYear)
        self.currentEra = era
        self.currentScheme = NostalgiaColors.getScheme(for: era)
    }

    static func determineEra(from birthYear: Int) -> NostalgiaEra {
        switch birthYear {
        case 1975...1985:
            return .eighties
        case 1986...1995:
            return .nineties
        case 1996...2005:
            return .earlyTwoThousands
        case 2006...2015:
            return .twentyTens
        default:
            return .modern
        }
    }

    func updateTheme(for profile: UserProfile) {
        currentEra = profile.nostalgiaEra
        withAnimation(.easeInOut(duration: 0.5)) {
            currentScheme = NostalgiaColors.getScheme(for: currentEra)
        }
    }

    // Get era-specific messages and content
    func getWelcomeMessage() -> String {
        switch currentEra {
        case .eighties:
            return "Like a cassette tape rewinding through time..."
        case .nineties:
            return "Loading your life's story... Please wait..."
        case .earlyTwoThousands:
            return "Syncing your memories to the cloud..."
        case .twentyTens:
            return "Scrolling through your timeline..."
        case .modern:
            return "Analyzing your life's journey..."
        }
    }

    func getTransitionAnimation() -> Animation {
        switch currentEra {
        case .eighties:
            return .easeInOut(duration: 0.3) // Quick, arcade-style
        case .nineties:
            return .linear(duration: 0.4) // Chunky, Windows-style
        case .earlyTwoThousands:
            return .spring(response: 0.5, dampingFraction: 0.75) // Smooth, iOS-style
        case .twentyTens:
            return .spring(response: 0.4, dampingFraction: 0.7) // Bouncy, modern app
        case .modern:
            return .spring(response: 0.6, dampingFraction: 0.8) // Gentle, contemporary
        }
    }

    // Get era-specific sound effects (placeholders for future implementation)
    func getInteractionSound() -> String {
        switch currentEra {
        case .eighties:
            return "arcade_beep"
        case .nineties:
            return "windows_click"
        case .earlyTwoThousands:
            return "ipod_click"
        case .twentyTens:
            return "notification_ping"
        case .modern:
            return "haptic_tap"
        }
    }

    // Era-specific fonts (using system fonts with different weights)
    func getTitleFont() -> Font {
        switch currentEra {
        case .eighties:
            return .system(size: Constants.Typography.titleSize, weight: .black, design: .rounded)
        case .nineties:
            return .system(size: Constants.Typography.titleSize, weight: .bold, design: .monospaced)
        case .earlyTwoThousands:
            return .system(size: Constants.Typography.titleSize, weight: .semibold, design: .default)
        case .twentyTens:
            return .system(size: Constants.Typography.titleSize, weight: .medium, design: .default)
        case .modern:
            return .system(size: Constants.Typography.titleSize, weight: .semibold, design: .rounded)
        }
    }

    func getBodyFont() -> Font {
        switch currentEra {
        case .eighties:
            return .system(size: Constants.Typography.bodySize, weight: .bold, design: .rounded)
        case .nineties:
            return .system(size: Constants.Typography.bodySize, weight: .regular, design: .monospaced)
        case .earlyTwoThousands:
            return .system(size: Constants.Typography.bodySize, weight: .regular, design: .default)
        case .twentyTens:
            return .system(size: Constants.Typography.bodySize, weight: .regular, design: .default)
        case .modern:
            return .system(size: Constants.Typography.bodySize, weight: .regular, design: .rounded)
        }
    }

    // Era-specific emoji/icons
    func getEraIcon() -> String {
        switch currentEra {
        case .eighties:
            return "music.note.tv.fill"
        case .nineties:
            return "desktopcomputer"
        case .earlyTwoThousands:
            return "ipodtouch"
        case .twentyTens:
            return "iphone"
        case .modern:
            return "sparkles"
        }
    }

    // Get nostalgic taglines
    func getTagline() -> String {
        switch currentEra {
        case .eighties:
            return "Rewind • Play • Your Life"
        case .nineties:
            return "You've Got: Your Life Story"
        case .earlyTwoThousands:
            return "10,000 Moments in Your Pocket"
        case .twentyTens:
            return "Double Tap to See Your Life"
        case .modern:
            return "Your Life, Visualized"
        }
    }
}

// Environment key for theme engine
struct ThemeEngineKey: EnvironmentKey {
    static let defaultValue = NostalgiaThemeEngine()
}

extension EnvironmentValues {
    var themeEngine: NostalgiaThemeEngine {
        get { self[ThemeEngineKey.self] }
        set { self[ThemeEngineKey.self] = newValue }
    }
}
