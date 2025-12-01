//
//  PieChartView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI
import Charts

struct PieChartView: View {
    let workLifeData: WorkLifeData
    @State private var selectedSegment: ChartSegment?
    @State private var animateChart = false

    var chartData: [ChartSegment] {
        [
            ChartSegment(
                category: "Work & Commute",
                value: workLifeData.workPercentage,
                color: AppColors.workColor,
                icon: "briefcase.fill"
            ),
            ChartSegment(
                category: "Family Time",
                value: workLifeData.familyTimePercentage,
                color: AppColors.familyColor,
                icon: "heart.fill"
            ),
            ChartSegment(
                category: "Personal Time",
                value: workLifeData.personalTimePercentage,
                color: AppColors.personalColor,
                icon: "sparkles"
            ),
            ChartSegment(
                category: "Sleep",
                value: workLifeData.sleepPercentage,
                color: AppColors.sleepColor,
                icon: "moon.fill"
            )
        ]
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Your Life Journey")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            // Pie Chart
            Chart(chartData) { segment in
                SectorMark(
                    angle: .value("Percentage", animateChart ? segment.value : 0),
                    innerRadius: .ratio(0.5),
                    angularInset: 2
                )
                .foregroundStyle(segment.color)
                .opacity(selectedSegment == nil || selectedSegment?.id == segment.id ? 1.0 : 0.5)
            }
            .frame(height: 250)

            // Legend
            VStack(spacing: 12) {
                ForEach(chartData) { segment in
                    LegendRow(
                        segment: segment,
                        isSelected: selectedSegment?.id == segment.id
                    ) {
                        withAnimation(Constants.Animation.bouncy) {
                            selectedSegment = selectedSegment?.id == segment.id ? nil : segment
                            Constants.Haptics.light.impactOccurred()
                        }
                    }
                }
            }

            // Selected detail
            if let selected = selectedSegment {
                selectedDetailView(for: selected)
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
            withAnimation(.easeOut(duration: 1.0)) {
                animateChart = true
            }
        }
    }

    @ViewBuilder
    private func selectedDetailView(for segment: ChartSegment) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: segment.icon)
                    .foregroundColor(segment.color)
                Text(segment.category)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
            }

            Text("\(String(format: "%.1f", segment.value))% of your week")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            Text("≈ \(hoursForSegment(segment)) hours per week")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(segment.color)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(segment.color.opacity(0.1))
        )
    }

    private func hoursForSegment(_ segment: ChartSegment) -> String {
        let hours = (segment.value / 100.0) * 168.0
        return String(format: "%.1f", hours)
    }
}

struct ChartSegment: Identifiable, Equatable {
    let id = UUID()
    let category: String
    let value: Double
    let color: Color
    let icon: String

    static func == (lhs: ChartSegment, rhs: ChartSegment) -> Bool {
        lhs.id == rhs.id
    }
}

struct LegendRow: View {
    let segment: ChartSegment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                // Color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(segment.color)
                    .frame(width: 8, height: 32)

                // Icon
                Image(systemName: segment.icon)
                    .font(.system(size: 16))
                    .foregroundColor(segment.color)
                    .frame(width: 24)

                // Label
                Text(segment.category)
                    .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                // Percentage
                Text("\(String(format: "%.1f", segment.value))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(segment.color)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? segment.color.opacity(0.1) : Color.gray.opacity(0.05))
            )
        }
    }
}

#Preview {
    let sampleData = WorkLifeData(
        averageWorkHoursPerDay: 8.0,
        averageWorkDaysPerWeek: 5.0,
        averageCommuteHoursPerDay: 1.0,
        averageOvertimeHoursPerWeek: 5.0,
        totalHoursWorked: 20000,
        totalDaysWorked: 2500,
        totalWeeksWorked: 500,
        totalMonthsWorked: 115,
        totalYearsWorked: 10,
        currentAge: 35,
        lifeExpectancy: 78.5,
        yearsRemaining: 43.5,
        workPercentage: 30.0,
        familyTimePercentage: 15.0,
        personalTimePercentage: 20.0,
        sleepPercentage: 33.0,
        otherPercentage: 2.0,
        industryAverageHours: 40,
        countryAverageHours: 38,
        comparisonToAverage: 2,
        projectedRetirementAge: 65,
        projectedTotalWorkHours: 65000,
        projectedWorkYearsRemaining: 30
    )

    return PieChartView(workLifeData: sampleData)
        .padding()
        .background(AppColors.background)
}
