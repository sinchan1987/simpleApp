//
//  TimelineView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct TimelineView: View {
    let userProfile: UserProfile
    let milestones: [LifeMilestone]
    @State private var selectedMilestone: LifeMilestone?
    @State private var animateTimeline = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your Life Journey")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(milestones.enumerated()), id: \.element.id) { index, milestone in
                        TimelineNode(
                            milestone: milestone,
                            isSelected: selectedMilestone?.id == milestone.id,
                            isLast: index == milestones.count - 1,
                            animationDelay: Double(index) * 0.1
                        ) {
                            withAnimation(Constants.Animation.bouncy) {
                                selectedMilestone = milestone
                                Constants.Haptics.light.impactOccurred()
                            }
                        }
                        .opacity(animateTimeline ? 1 : 0)
                        .offset(y: animateTimeline ? 0 : 20)
                        .animation(
                            Constants.Animation.smooth.delay(Double(index) * 0.1),
                            value: animateTimeline
                        )
                    }
                }
                .padding(.vertical, 20)
            }

            if let selected = selectedMilestone {
                MilestoneDetailCard(milestone: selected)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(Constants.Layout.paddingLarge)
        .background(
            RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusLarge)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        )
        .onAppear {
            animateTimeline = true
        }
    }
}

struct TimelineNode: View {
    let milestone: LifeMilestone
    let isSelected: Bool
    let isLast: Bool
    let animationDelay: Double
    let action: () -> Void

    @State private var pulseAnimation = false

    var nodeColor: Color {
        switch milestone.type {
        case .birth:
            return AppColors.accent
        case .school, .graduation:
            return AppColors.secondary
        case .firstJob, .career:
            return AppColors.workColor
        case .family:
            return AppColors.familyColor
        case .current:
            return AppColors.primary
        case .retirement:
            return AppColors.personalColor
        }
    }

    var nodeIcon: String {
        switch milestone.type {
        case .birth:
            return "star.fill"
        case .school:
            return "book.fill"
        case .graduation:
            return "graduationcap.fill"
        case .firstJob:
            return "briefcase.fill"
        case .career:
            return "chart.line.uptrend.xyaxis"
        case .family:
            return "heart.fill"
        case .current:
            return "mappin.and.ellipse"
        case .retirement:
            return "beach.umbrella.fill"
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 8) {
                // Node circle
                Button(action: action) {
                    ZStack {
                        Circle()
                            .fill(nodeColor.opacity(0.2))
                            .frame(width: 60, height: 60)
                            .scaleEffect(milestone.type == .current && pulseAnimation ? 1.2 : 1.0)

                        Circle()
                            .fill(nodeColor)
                            .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)

                        Image(systemName: nodeIcon)
                            .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: nodeColor.opacity(0.4), radius: isSelected ? 8 : 4, y: 2)

                // Age label
                VStack(spacing: 4) {
                    Text("Age \(milestone.age)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                    Text(milestone.title)
                        .font(.system(size: 11))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(width: 80)
            }

            // Connecting line
            if !isLast {
                Rectangle()
                    .fill(AppColors.textSecondary.opacity(0.3))
                    .frame(width: 60, height: 2)
            }
        }
        .onAppear {
            if milestone.type == .current {
                withAnimation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(animationDelay)
                ) {
                    pulseAnimation = true
                }
            }
        }
    }
}

struct MilestoneDetailCard: View {
    let milestone: LifeMilestone

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(milestone.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Age \(milestone.age)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Text(milestone.date, style: .date)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.primary)
            }

            Divider()

            Text(getMilestoneDescription())
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Constants.Layout.paddingMedium)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppColors.primary.opacity(0.05))
        )
    }

    private func getMilestoneDescription() -> String {
        switch milestone.type {
        case .birth:
            return "The beginning of your journey"
        case .school:
            return "Your educational journey began"
        case .graduation:
            return "Completed formal education"
        case .firstJob:
            return "Started your professional career"
        case .career:
            return "Career milestone achieved"
        case .family:
            return "Important family moment"
        case .current:
            return "Where you are today on your life's journey"
        case .retirement:
            return "Looking forward to this milestone"
        }
    }
}

#Preview {
    let sampleMilestones = [
        LifeMilestone(age: 0, title: "Born", type: .birth, date: Calendar.current.date(byAdding: .year, value: -35, to: Date())!),
        LifeMilestone(age: 5, title: "Started School", type: .school, date: Calendar.current.date(byAdding: .year, value: -30, to: Date())!),
        LifeMilestone(age: 18, title: "Graduation", type: .graduation, date: Calendar.current.date(byAdding: .year, value: -17, to: Date())!),
        LifeMilestone(age: 22, title: "First Job", type: .firstJob, date: Calendar.current.date(byAdding: .year, value: -13, to: Date())!),
        LifeMilestone(age: 35, title: "Today", type: .current, date: Date())
    ]

    let sampleProfile = UserProfile(
        name: "Alex",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
        industry: "Technology",
        jobRole: "Software Engineer",
        yearsWorked: 13
    )

    return TimelineView(userProfile: sampleProfile, milestones: sampleMilestones)
        .padding()
        .background(AppColors.background)
}
