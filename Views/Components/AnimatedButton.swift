//
//  AnimatedButton.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct AnimatedButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: ButtonStyle = .primary
    var isDisabled: Bool = false
    var isLoading: Bool = false

    @State private var isPressed = false

    enum ButtonStyle {
        case primary
        case secondary
        case ghost

        var backgroundColor: Color {
            switch self {
            case .primary:
                return AppColors.primary
            case .secondary:
                return AppColors.secondary
            case .ghost:
                return Color.clear
            }
        }

        var foregroundColor: Color {
            switch self {
            case .primary:
                return .white
            case .secondary:
                return AppColors.textPrimary
            case .ghost:
                return AppColors.primary
            }
        }
    }

    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }

            // Haptic feedback
            Constants.Haptics.medium.impactOccurred()

            // Button press animation
            withAnimation(Constants.Animation.bouncy) {
                isPressed = true
            }

            // Execute action after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(Constants.Animation.bouncy) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .semibold))
                    }

                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                }
            }
            .foregroundColor(isDisabled ? .gray : style.foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                    .fill(isDisabled ? Color.gray.opacity(0.3) : style.backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                    .stroke(style == .ghost ? AppColors.primary : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled || isLoading)
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedButton(
            title: "Continue",
            icon: "arrow.right",
            action: {},
            style: .primary
        )

        AnimatedButton(
            title: "Skip",
            icon: nil,
            action: {},
            style: .secondary
        )

        AnimatedButton(
            title: "Learn More",
            icon: "info.circle",
            action: {},
            style: .ghost
        )

        AnimatedButton(
            title: "Disabled",
            icon: nil,
            action: {},
            isDisabled: true
        )

        AnimatedButton(
            title: "Loading",
            icon: nil,
            action: {},
            isLoading: true
        )
    }
    .padding()
}
