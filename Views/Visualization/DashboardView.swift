//
//  DashboardView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct DashboardView: View {
    let userProfile: UserProfile
    @ObservedObject var themeEngine: NostalgiaThemeEngine

    @EnvironmentObject var authService: AuthenticationService

    @State private var workLifeData: WorkLifeData?
    @State private var milestones: [LifeMilestone] = []
    @State private var isLoading = true
    @State private var showContent = false
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Background with nostalgic gradient
            themeEngine.currentScheme.gradient
                .opacity(0.3)
                .ignoresSafeArea()

            if isLoading {
                CircularProgressIndicator(message: "Analyzing your life's journey...")
                    .transition(.opacity)
            } else if let data = workLifeData {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with greeting
                        HeaderView(userProfile: userProfile, workLifeData: data)
                            .padding(.horizontal, 20)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : -20)

                        // Hero Statistics Card - Hidden for now, can be re-enabled later
                        // HeroStatCard(workLifeData: data)
                        //     .padding(.horizontal, 20)
                        //     .opacity(showContent ? 1 : 0)
                        //     .offset(y: showContent ? 0 : 20)
                        //     .animation(Constants.Animation.smooth.delay(0.1), value: showContent)

                        // Tab selector
                        TabSelector(selectedTab: $selectedTab)
                            .padding(.horizontal, 20)
                            .opacity(showContent ? 1 : 0)
                            .animation(Constants.Animation.smooth.delay(0.2), value: showContent)

                        // Content based on selected tab
                        Group {
                            switch selectedTab {
                            case 0:
                                OverviewTab(workLifeData: data, userProfile: userProfile, milestones: milestones)
                                    .padding(.horizontal, 20)
                            case 1:
                                SpecialDatesTab(userProfile: userProfile)
                            // Hidden tabs - keep for future use
                            // case X: DetailedStatsTab(workLifeData: data, userProfile: userProfile)
                            // case X: WhatIfTab(workLifeData: data)
                            default:
                                EmptyView()
                            }
                        }
                        .opacity(showContent ? 1 : 0)
                        .animation(Constants.Animation.smooth.delay(0.3), value: showContent)

                        // Footer
                        FooterView()
                            .padding(.horizontal, 20)
                            .opacity(showContent ? 1 : 0)
                            .padding(.bottom, 40)
                    }
                    .padding(.top, Constants.Layout.paddingLarge)
                }
            }
        }
        .onAppear {
            loadData()
            requestNotificationPermissions()
        }
    }

    private func loadData() {
        Task {
            // Fetch industry data
            if let industryData = try? await APIService.shared.fetchIndustryData(
                industry: userProfile.industry,
                jobRole: userProfile.jobRole
            ) {
                // Calculate work-life data
                let calculatedData = CalculationEngine.shared.calculateWorkLifeData(
                    profile: userProfile,
                    industryData: industryData
                )

                // Generate milestones
                let generatedMilestones = CalculationEngine.shared.generateMilestones(profile: userProfile)

                // Update UI on main thread
                await MainActor.run {
                    withAnimation(Constants.Animation.smooth) {
                        self.workLifeData = calculatedData
                        self.milestones = generatedMilestones
                        self.isLoading = false
                    }

                    // Animate content in
                    withAnimation(Constants.Animation.smooth.delay(0.2)) {
                        self.showContent = true
                    }
                }
            }
        }
    }

    private func requestNotificationPermissions() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            if granted {
                print("✅ DashboardView: Notification permissions granted")
            } else {
                print("⚠️ DashboardView: Notification permissions denied")
            }
        }
    }
}

// MARK: - Header View
struct HeaderView: View {
    let userProfile: UserProfile
    let workLifeData: WorkLifeData

    @EnvironmentObject var authService: AuthenticationService
    @State private var showSettings = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning"
        case 12..<17:
            return "Good afternoon"
        default:
            return "Good evening"
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Text("\(greeting), \(userProfile.name)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Here's your life journey at age \(userProfile.age)")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Settings/Profile Button
            Button(action: {
                showSettings = true
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusLarge)
                .fill(Color.white.opacity(0.9))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
        .sheet(isPresented: $showSettings) {
            SettingsView(userProfile: userProfile)
                .environmentObject(authService)
        }
    }
}

// MARK: - Hero Stat Card
struct HeroStatCard: View {
    let workLifeData: WorkLifeData
    @State private var animateNumber = false

    var body: some View {
        VStack(spacing: 16) {
            Text("You've spent")
                .font(.system(size: 18))
                .foregroundColor(AppColors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(animateNumber ? "\(String(format: "%.1f", workLifeData.lifeSpentAtWork))" : "0")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundColor(AppColors.primary)
                    .contentTransition(.numericText())

                Text("%")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.primary)
            }

            Text("of your life at work")
                .font(.system(size: 18))
                .foregroundColor(AppColors.textSecondary)

            Divider()

            HStack(spacing: 24) {
                QuickStat(
                    value: workLifeData.workHoursFormatted,
                    label: "Hours Worked",
                    icon: "clock.fill",
                    color: AppColors.workColor
                )

                QuickStat(
                    value: workLifeData.workDaysFormatted,
                    label: "Days Worked",
                    icon: "calendar.fill",
                    color: AppColors.accent
                )
            }
        }
        .padding(Constants.Layout.paddingLarge)
        .background(
            RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusLarge)
                .fill(
                    LinearGradient(
                        colors: [Color.white, AppColors.primary.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: AppColors.primary.opacity(0.2), radius: 16, y: 8)
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                animateNumber = true
            }
        }
    }
}

struct QuickStat: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text(label)
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Tab Selector
struct TabSelector: View {
    @Binding var selectedTab: Int
    // Hidden tabs: "Details", "What If?" - can be re-enabled later
    let tabs = ["Overview", "Special Dates"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(Constants.Animation.bouncy) {
                        selectedTab = index
                        Constants.Haptics.selection.selectionChanged()
                    }
                }) {
                    Text(tabs[index])
                        .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium))
                        .foregroundColor(selectedTab == index ? AppColors.primary : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == index ? AppColors.primary.opacity(0.1) : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        )
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    let workLifeData: WorkLifeData
    let userProfile: UserProfile
    let milestones: [LifeMilestone]

    var body: some View {
        VStack(spacing: 24) {
            // PieChartView (Your Life Journey) - Hidden for now, can be re-enabled later
            // PieChartView(workLifeData: workLifeData)

            LifeCalendarView(userProfile: userProfile, workLifeData: workLifeData)
        }
    }
}

// MARK: - Detailed Stats Tab
struct DetailedStatsTab: View {
    let workLifeData: WorkLifeData
    let userProfile: UserProfile

    var body: some View {
        VStack(spacing: 16) {
            DetailStatCard(
                title: "Work Statistics",
                icon: "briefcase.fill",
                color: AppColors.workColor,
                stats: [
                    ("Avg. Hours/Day", String(format: "%.1f hrs", workLifeData.averageWorkHoursPerDay)),
                    ("Avg. Days/Week", String(format: "%.0f days", workLifeData.averageWorkDaysPerWeek)),
                    ("Total Weeks Worked", String(format: "%.0f weeks", workLifeData.totalWeeksWorked)),
                    ("Years to Retirement", String(format: "%.0f years", workLifeData.projectedWorkYearsRemaining))
                ]
            )

            DetailStatCard(
                title: "Life Projections",
                icon: "heart.fill",
                color: AppColors.familyColor,
                stats: [
                    ("Current Age", "\(workLifeData.currentAge) years"),
                    ("Life Expectancy", String(format: "%.0f years", workLifeData.lifeExpectancy)),
                    ("Years Remaining", String(format: "%.1f years", workLifeData.yearsRemaining)),
                    ("Retirement Age", "\(workLifeData.projectedRetirementAge) years")
                ]
            )

            DetailStatCard(
                title: "Comparisons",
                icon: "chart.bar.fill",
                color: AppColors.accent,
                stats: [
                    ("Your Weekly Hours", String(format: "%.0f hrs", workLifeData.industryAverageHours)),
                    ("Country Average", String(format: "%.0f hrs", workLifeData.countryAverageHours)),
                    ("Difference", String(format: "%+.0f hrs", workLifeData.comparisonToAverage)),
                    ("Status", workLifeData.comparisonToAverage > 0 ? "Above Average" : "Below Average")
                ]
            )
        }
    }
}

struct DetailStatCard: View {
    let title: String
    let icon: String
    let color: Color
    let stats: [(String, String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
            }

            VStack(spacing: 12) {
                ForEach(stats, id: \.0) { stat in
                    HStack {
                        Text(stat.0)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Text(stat.1)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(color)
                    }

                    if stat.0 != stats.last?.0 {
                        Divider()
                    }
                }
            }
        }
        .padding(Constants.Layout.paddingLarge)
        .background(
            RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusLarge)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        )
    }
}

// MARK: - What If Tab
struct WhatIfTab: View {
    let workLifeData: WorkLifeData
    @State private var weeklyHours: Double
    @State private var retirementAge: Double
    @State private var whatIfData: WorkLifeData?

    init(workLifeData: WorkLifeData) {
        self.workLifeData = workLifeData
        _weeklyHours = State(initialValue: workLifeData.averageWorkHoursPerDay * workLifeData.averageWorkDaysPerWeek)
        _retirementAge = State(initialValue: Double(workLifeData.projectedRetirementAge))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Explore Alternative Scenarios")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Weekly hours slider
            VStack(alignment: .leading, spacing: 12) {
                Label("Weekly Work Hours", systemImage: "clock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text("\(String(format: "%.0f", weeklyHours)) hours/week")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.primary)

                Slider(value: $weeklyHours, in: 20...60, step: 1)
                    .accentColor(AppColors.primary)
                    .onChange(of: weeklyHours) { oldValue, newValue in
                        updateWhatIf()
                        Constants.Haptics.selection.selectionChanged()
                    }

                HStack {
                    Text("20 hrs")
                    Spacer()
                    Text("60 hrs")
                }
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)

            // Retirement age slider
            VStack(alignment: .leading, spacing: 12) {
                Label("Retirement Age", systemImage: "figure.walk")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                Text("\(Int(retirementAge)) years old")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.accent)

                Slider(value: $retirementAge, in: 55...75, step: 1)
                    .accentColor(AppColors.accent)
                    .onChange(of: retirementAge) { oldValue, newValue in
                        updateWhatIf()
                        Constants.Haptics.selection.selectionChanged()
                    }

                HStack {
                    Text("55")
                    Spacer()
                    Text("75")
                }
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)

            // Comparison
            if let whatIf = whatIfData {
                ComparisonCard(original: workLifeData, whatIf: whatIf)
            }
        }
        .onAppear {
            updateWhatIf()
        }
    }

    private func updateWhatIf() {
        whatIfData = CalculationEngine.shared.calculateWhatIf(
            currentData: workLifeData,
            newWeeklyHours: weeklyHours,
            newRetirementAge: Int(retirementAge)
        )
    }
}

struct ComparisonCard: View {
    let original: WorkLifeData
    let whatIf: WorkLifeData

    var hoursDifference: Double {
        return whatIf.projectedTotalWorkHours - original.projectedTotalWorkHours
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Impact on Your Life")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                ComparisonRow(
                    label: "Total Work Hours",
                    original: original.projectedTotalWorkHours,
                    whatIf: whatIf.projectedTotalWorkHours,
                    format: "%.0f hrs"
                )

                ComparisonRow(
                    label: "Work Life %",
                    original: original.workPercentage,
                    whatIf: whatIf.workPercentage,
                    format: "%.1f%%"
                )
            }

            Text(hoursDifference > 0 ?
                 "You'd work \(Int(abs(hoursDifference))) more hours" :
                 "You'd save \(Int(abs(hoursDifference))) hours!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(hoursDifference > 0 ? .red : .green)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill((hoursDifference > 0 ? Color.red : Color.green).opacity(0.1))
                )
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct ComparisonRow: View {
    let label: String
    let original: Double
    let whatIf: Double
    let format: String

    var body: some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            HStack {
                VStack {
                    Text("Current")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                    Text(String(format: format, original))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.primary)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.textSecondary)

                VStack {
                    Text("What If")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                    Text(String(format: format, whatIf))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.accent)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

// MARK: - Footer View
struct FooterView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Remember: It's never too late to change your balance")
                .font(.system(size: 14))
                .italic()
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Text("Made with ❤️ for your life's journey")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary.opacity(0.7))
        }
        .padding()
    }
}

#Preview {
    let userProfile = UserProfile(
        name: "Alex",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
        industry: "Technology",
        jobRole: "Software Engineer",
        yearsWorked: 13,
        relationshipStatus: .married,
        children: [
            Child(name: "Emma", dateOfBirth: Calendar.current.date(byAdding: .year, value: -5, to: Date())!),
            Child(name: "Liam", dateOfBirth: Calendar.current.date(byAdding: .year, value: -3, to: Date())!)
        ],
        pets: [
            Pet(name: "Buddy", type: .dog, birthday: Calendar.current.date(byAdding: .year, value: -2, to: Date()))
        ]
    )

    DashboardView(
        userProfile: userProfile,
        themeEngine: NostalgiaThemeEngine(birthYear: 1988)
    )
}
