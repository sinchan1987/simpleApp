//
//  ProgressIndicator.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct ProgressIndicator: View {
    let progress: Double
    let totalSteps: Int
    let currentStep: Int

    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 6)

                    // Foreground progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [AppColors.primary, AppColors.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(Constants.Animation.smooth, value: progress)
                }
            }
            .frame(height: 6)

            // Step indicator
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }
        }
    }
}

// Circular progress indicator for loading states
struct CircularProgressIndicator: View {
    let message: String
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .stroke(AppColors.primary.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }

            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    VStack(spacing: 50) {
        ProgressIndicator(
            progress: 0.6,
            totalSteps: 7,
            currentStep: 4
        )
        .padding()

        CircularProgressIndicator(message: "Calculating your life journey...")
    }
    .padding()
    .background(AppColors.background)
}
