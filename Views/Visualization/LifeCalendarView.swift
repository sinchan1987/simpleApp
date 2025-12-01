//
//  LifeCalendarView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct LifeCalendarView: View {
    let userProfile: UserProfile
    let workLifeData: WorkLifeData

    @EnvironmentObject var authService: AuthenticationService
    @StateObject private var memoryViewModel = MemoryViewModel()

    @State private var selectedYear: YearData?
    @State private var animateGrid = false
    @State private var showYearDetailSheet = false
    @State private var showAuthPrompt = false

    let yearsPerRow = 10
    let maxYears = 90

    var yearData: [YearData] {
        let currentAge = userProfile.age
        let yearsWorked = Int(userProfile.yearsWorked)
        let workStartAge = max(0, currentAge - yearsWorked)

        return (0..<maxYears).map { year in
            createYearData(year: year, currentAge: currentAge, workStartAge: workStartAge)
        }
    }

    private func createYearData(year: Int, currentAge: Int, workStartAge: Int) -> YearData {
        let isPast = year < currentAge
        let isWork = year >= workStartAge && year < currentAge
        let isCurrent = year == currentAge
        let hasMemory = checkHasMemory(year: year)

        return YearData(
            year: year,
            isPast: isPast,
            isWork: isWork,
            isCurrent: isCurrent,
            hasMemory: hasMemory
        )
    }

    private func checkHasMemory(year: Int) -> Bool {
        for week in 0..<52 {
            if memoryViewModel.hasEntry(week: week, year: year) {
                return true
            }
        }
        return false
    }

    var body: some View {
        contentWithSheets
            .task {
                await loadUserData()
            }
            .onChange(of: authService.isAuthenticated) { oldValue, newValue in
                handleAuthStateChange(newValue)
            }
            .onAppear {
                animateGrid = true
            }
    }

    private var contentWithSheets: some View {
        mainContent
            .sheet(isPresented: $showYearDetailSheet) {
                yearDetailSheetContent
            }
            .sheet(isPresented: $showAuthPrompt) {
                authPromptContent
            }
    }

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection
            legendSection
            calendarGrid

            // Statistics
            StatisticsRow(workLifeData: workLifeData, userProfile: userProfile)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusLarge)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 6)
        )
    }

    @ViewBuilder
    private var yearDetailSheetContent: some View {
        if let year = selectedYear {
            YearDetailSheet(year: year, userProfile: userProfile)
                .environmentObject(memoryViewModel)
                .environmentObject(authService)
        }
    }

    private var authPromptContent: some View {
        AuthPromptView()
            .environmentObject(authService)
    }

    private func loadUserData() async {
        if let userId = authService.currentUser?.id {
            await memoryViewModel.loadEntries(forUser: userId)
            memoryViewModel.startListening(forUser: userId)

            // Convert any completed goals to memories on load
            await memoryViewModel.convertCompletedGoalsToMemories(userBirthDate: userProfile.dateOfBirth)
        }
    }

    private func handleAuthStateChange(_ isAuthenticated: Bool) {
        if isAuthenticated, let userId = authService.currentUser?.id {
            Task {
                await memoryViewModel.loadEntries(forUser: userId)
                memoryViewModel.startListening(forUser: userId)
            }
        } else if !isAuthenticated {
            memoryViewModel.stopListening()
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 4) {
            ForEach(0..<(maxYears / yearsPerRow), id: \.self) { rowIndex in
                HStack(spacing: 4) {
                    ForEach(0..<yearsPerRow, id: \.self) { colIndex in
                        let yearIndex = rowIndex * yearsPerRow + colIndex
                        if yearIndex < maxYears {
                            let year = yearData[yearIndex]
                            YearSquare(
                                year: year,
                                isSelected: selectedYear?.id == year.id,
                                userProfile: userProfile
                            )
                            .frame(width: 31, height: 31)
                            .opacity(animateGrid ? 1 : 0)
                            .animation(
                                Constants.Animation.smooth.delay(Double(yearIndex) * 0.005),
                                value: animateGrid
                            )
                            .onTapGesture {
                                selectedYear = year
                                handleYearTap(year)
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 16)
        .background(Color.white)
        .cornerRadius(12)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Life in Years")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            Text("Each square represents one year. \(maxYears) years of life visualized")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var legendSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                LegendItem(color: AppColors.primary, label: "Current")
                LegendItem(color: AppColors.accent, label: "Goals")
            }

            HStack(spacing: 12) {
                SpecialDateLegendItem(type: .birthday, label: "Birthday")
                SpecialDateLegendItem(type: .anniversary, label: "Anniversary")
                SpecialDateLegendItem(type: .childBirthday, label: "Child")
            }
        }
        .font(.system(size: 11))
    }

    private func handleYearTap(_ year: YearData) {
        Constants.Haptics.light.impactOccurred()

        // Check if user is authenticated
        if authService.currentUser == nil {
            showAuthPrompt = true
        } else {
            showYearDetailSheet = true
        }
    }
}

// MARK: - Data Models
struct YearData: Identifiable, Equatable {
    let id = UUID()
    let year: Int
    let isPast: Bool
    let isWork: Bool
    let isCurrent: Bool
    var hasMemory: Bool
}

// Keep WeekData for backward compatibility with other views
struct WeekData: Identifiable, Equatable {
    let id = UUID()
    let year: Int
    let week: Int
    let isPast: Bool
    let isWork: Bool
    let isCurrent: Bool
    let age: Int
}

// MARK: - Year Square
struct YearSquare: View {
    let year: YearData
    let isSelected: Bool
    let userProfile: UserProfile

    var yearColor: Color {
        // Current year takes priority over everything
        if year.isCurrent {
            return AppColors.primary
        } else if year.hasMemory {
            return AppColors.accent
        } else if year.isWork {
            return AppColors.workColor
        } else if year.isPast {
            return AppColors.personalColor
        } else {
            return Color.gray.opacity(0.2)
        }
    }

    private var calendarYear: Int {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: userProfile.dateOfBirth)
        return birthYear + year.year
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4)
                .fill(yearColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                )
                .scaleEffect(isSelected ? 1.1 : 1.0)
                .shadow(color: isSelected ? yearColor.opacity(0.6) : Color.clear, radius: 4)

            // Age and calendar year
            VStack(spacing: 1) {
                Text("\(year.year)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                Text("'\(String(calendarYear).suffix(2))")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.75))
            }
        }
    }
}

// MARK: - Supporting Views
struct LegendItem: View {
    let color: Color
    let label: String
    var isCurrent: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.white, lineWidth: isCurrent ? 2 : 0)
                )

            Text(label)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

struct SpecialDateLegendItem: View {
    let type: SpecialDateType
    let label: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.system(size: 8))
                .foregroundColor(type.color)

            Text(label)
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

struct StatisticsRow: View {
    let workLifeData: WorkLifeData
    let userProfile: UserProfile

    var yearsLived: Int {
        return userProfile.age
    }

    var yearsWorked: Int {
        return Int(workLifeData.totalYearsWorked)
    }

    var yearsRemaining: Int {
        let lifeExpectancy = Int(workLifeData.lifeExpectancy)
        return max(0, lifeExpectancy - userProfile.age)
    }

    var body: some View {
        HStack(spacing: 12) {
            StatCard(value: yearsLived, label: "Years Lived", color: AppColors.personalColor)
            StatCard(value: yearsWorked, label: "Years Worked", color: AppColors.workColor)
            StatCard(value: yearsRemaining, label: "Years Ahead", color: AppColors.accent)
        }
    }
}

struct StatCard: View {
    let value: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text("\(value)")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 10))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Year Detail Sheet
struct YearDetailSheet: View {
    let year: YearData
    let userProfile: UserProfile

    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var selectedDate: Date?
    @State private var showMemoryEditor = false
    @State private var showGoalEditor = false
    @State private var showEntryViewer = false
    @State private var selectedEntryToView: WeekEntry?
    @State private var allEntriesToView: [WeekEntry] = []

    // Use centralized date calculator for consistent calculations
    private let dateCalculator = DateCalculator()

    private var calendarYear: Int {
        dateCalculator.calendarYear(forWeekYear: year.year, userBirthDate: userProfile.dateOfBirth)
    }

    private var yearStartDate: Date {
        Calendar.current.date(from: DateComponents(year: calendarYear, month: 1, day: 1))!
    }

    private var selectedWeekData: WeekData? {
        guard let date = selectedDate else { return nil }
        let calendar = Calendar.current

        // Use centralized DateCalculator for consistent date→week conversion
        let coordinates = dateCalculator.dateToWeekCoordinates(date: date, userBirthDate: userProfile.dateOfBirth)

        return WeekData(
            year: coordinates.weekYear,
            week: coordinates.weekNumber,
            isPast: isDateInPast(date),
            isWork: year.isWork,
            isCurrent: calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear),
            age: coordinates.weekYear
        )
    }

    private func getExistingEntries() -> [WeekEntry] {
        guard let date = selectedDate else { return [] }

        // Use centralized DateCalculator for consistent date→week conversion
        let coordinates = dateCalculator.dateToWeekCoordinates(date: date, userBirthDate: userProfile.dateOfBirth)

        return memoryViewModel.getEntries(week: coordinates.weekNumber, year: coordinates.weekYear, dayOfWeek: coordinates.dayOfWeek)
    }

    private func isDateInPast(_ date: Date) -> Bool {
        return date < Date()
    }

    private func isDateCurrent(_ date: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date, equalTo: Date(), toGranularity: .day)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Fixed header - Year info
                    VStack(spacing: 12) {
                        Text("Age \(year.year) · \(String(calendarYear))")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColors.primary)

                        Text(getYearDescription())
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(AppColors.background)

                    // Scrollable content
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("Select a date")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            YearCalendarView(
                                year: calendarYear,
                                selectedDate: $selectedDate,
                                userProfile: userProfile,
                                onDateWithEntriesTapped: { date, entries in
                                    // Set the selected date and open the entry viewer directly
                                    selectedDate = date
                                    allEntriesToView = entries
                                    showEntryViewer = true
                                }
                            )
                            .environmentObject(memoryViewModel)
                        }
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, selectedDate != nil ? 100 : 20)
                    }
                }

                // Action buttons pinned to bottom
                if let date = selectedDate {
                    ActionButtonsView(
                        date: date,
                        year: year,
                        existingEntries: getExistingEntries(),
                        isDateInPast: isDateInPast,
                        isDateCurrent: isDateCurrent,
                        showMemoryEditor: $showMemoryEditor,
                        showGoalEditor: $showGoalEditor,
                        showEntryViewer: $showEntryViewer,
                        allEntriesToView: $allEntriesToView
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
            .sheet(isPresented: $showMemoryEditor) {
                if let weekData = selectedWeekData, let date = selectedDate {
                    EntryEditorView(
                        week: weekData,
                        userProfile: userProfile,
                        existingEntry: nil,
                        isPast: true,
                        selectedDate: date
                    )
                    .environmentObject(memoryViewModel)
                    .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showGoalEditor) {
                if let weekData = selectedWeekData, let date = selectedDate {
                    EntryEditorView(
                        week: weekData,
                        userProfile: userProfile,
                        existingEntry: nil,
                        isPast: false,
                        selectedDate: date
                    )
                    .environmentObject(memoryViewModel)
                    .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showEntryViewer) {
                if !allEntriesToView.isEmpty {
                    MultipleEntriesCarouselView(
                        initialEntries: allEntriesToView,
                        userProfile: userProfile
                    )
                    .environmentObject(memoryViewModel)
                    .environmentObject(authService)
                }
            }
        }
    }

    private func getYearDescription() -> String {
        if year.isCurrent {
            return "This is your current year. Make it count!"
        } else if year.isWork {
            return "A year spent building your career"
        } else if year.isPast {
            return "A year of life lived"
        } else {
            return "A year yet to come"
        }
    }
}

// MARK: - Year Calendar View
struct YearCalendarView: View {
    let year: Int
    @Binding var selectedDate: Date?
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    let userProfile: UserProfile
    var onDateWithEntriesTapped: ((Date, [WeekEntry]) -> Void)?

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    private var months: [Date] {
        (1...12).compactMap { month in
            calendar.date(from: DateComponents(year: year, month: month, day: 1))
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            ForEach(months, id: \.self) { monthDate in
                MonthView(
                    monthDate: monthDate,
                    selectedDate: $selectedDate,
                    userProfile: userProfile,
                    onDateWithEntriesTapped: onDateWithEntriesTapped
                )
                .environmentObject(memoryViewModel)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

// MARK: - Month View
struct MonthView: View {
    let monthDate: Date
    @Binding var selectedDate: Date?
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    let userProfile: UserProfile
    var onDateWithEntriesTapped: ((Date, [WeekEntry]) -> Void)?

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]
    private let dateCalculator = DateCalculator()

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: monthDate)
    }

    private var daysInMonth: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: monthDate),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        let days = (0..<42).map { index -> Date? in
            guard let date = calendar.date(byAdding: .day, value: index, to: monthFirstWeek.start) else {
                return nil
            }
            return calendar.isDate(date, equalTo: monthDate, toGranularity: .month) ? date : nil
        }

        return days
    }

    // Force SwiftUI to re-render when entries change by creating a unique identifier
    private var entriesIdentifier: Int {
        // Sum of all entry counts across all weeks
        memoryViewModel.entriesByWeek.values.reduce(0) { $0 + $1.count }
    }

    // Get entries for a specific date
    private func getEntriesForDate(_ date: Date) -> [WeekEntry] {
        let coordinates = dateCalculator.dateToWeekCoordinates(date: date, userBirthDate: userProfile.dateOfBirth)
        return memoryViewModel.getEntries(week: coordinates.weekNumber, year: coordinates.weekYear, dayOfWeek: coordinates.dayOfWeek)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Month name
            Text(monthName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Days of week header
            HStack(spacing: 4) {
                ForEach(Array(daysOfWeek.enumerated()), id: \.offset) { index, day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Days grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(0..<daysInMonth.count, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        DayCell(
                            date: date,
                            isSelected: selectedDate != nil && calendar.isDate(date, inSameDayAs: selectedDate!),
                            userProfile: userProfile
                        )
                        .environmentObject(memoryViewModel)
                        .id("\(date.timeIntervalSince1970)-\(entriesIdentifier)")
                        .onTapGesture {
                            Constants.Haptics.light.impactOccurred()

                            // Check if this date has any entries
                            let entries = getEntriesForDate(date)

                            if !entries.isEmpty {
                                // If date has entries, directly open the viewer
                                onDateWithEntriesTapped?(date, entries)
                            } else {
                                // If no entries, just select the date to show add buttons
                                selectedDate = date
                            }
                        }
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
        }
    }
}

// MARK: - Day Cell
struct DayCell: View {
    let date: Date
    let isSelected: Bool
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    let userProfile: UserProfile

    private let calendar = Calendar.current
    // Use centralized date calculator for consistent calculations
    private let dateCalculator = DateCalculator()

    private var dayNumber: Int {
        calendar.component(.day, from: date)
    }

    private var isToday: Bool {
        calendar.isDateInToday(date)
    }

    private var isPast: Bool {
        date < Date()
    }

    // Check for special dates
    private var specialDateTypes: [SpecialDateType] {
        userProfile.getAllSpecialDateTypes(for: date)
    }

    private var hasSpecialDate: Bool {
        !specialDateTypes.isEmpty
    }

    private var primarySpecialDateType: SpecialDateType? {
        // Priority order: birthday > anniversary > spouse > child > pet > graduation
        let priority: [SpecialDateType] = [.birthday, .anniversary, .spouseBirthday, .childBirthday, .petBirthday, .graduation]
        for type in priority {
            if specialDateTypes.contains(type) {
                return type
            }
        }
        return specialDateTypes.first
    }

    // Cache the entry lookup to avoid repeated calls
    // Note: We need to access memoryViewModel.entriesByWeek to trigger reactivity
    private var entriesForDate: [WeekEntry] {
        // Use centralized DateCalculator for consistent date→week conversion
        let coordinates = dateCalculator.dateToWeekCoordinates(date: date, userBirthDate: userProfile.dateOfBirth)

        // Quick lookup - return empty array if no entries for this week at all
        let key = "\(coordinates.weekYear)-\(coordinates.weekNumber)"

        // IMPORTANT: Force SwiftUI to observe changes by accessing the entire dictionary first
        // This ensures the @Published wrapper triggers view updates
        let _ = memoryViewModel.entriesByWeek.count

        // IMPORTANT: Access via the @Published property to ensure SwiftUI reactivity
        let allWeekEntries = memoryViewModel.entriesByWeek[key] ?? []

        // Debug logging for November 17, 2025 specifically
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy"
        let dateString = dateFormatter.string(from: date)
        if dateString == "Nov 17, 2025" {
            print("📅 DayCell.entriesForDate DEBUG for Nov 17, 2025:")
            print("  Date: \(date)")
            print("  Calculated age (weekYear): \(coordinates.weekYear)")
            print("  Week of year: \(coordinates.weekNumber)")
            print("  Day of week: \(coordinates.dayOfWeek)")
            print("  Looking for key: \(key)")
            print("  All week entries count: \(allWeekEntries.count)")
            for entry in allWeekEntries {
                print("    - Entry: \(entry.title), type: \(entry.entryType.rawValue), dayOfWeek: \(entry.dayOfWeek?.description ?? "nil")")
            }
        }

        // Debug logging for today's date ONLY (once)
        if isToday {
            print("📅 DayCell.entriesForDate DEBUG for TODAY (\(dayNumber)):")
            print("  Date: \(date)")
            print("  Birth year: \(calendar.component(.year, from: userProfile.dateOfBirth))")
            print("  Current calendar year: \(calendar.component(.year, from: date))")
            print("  Calculated age (weekYear): \(coordinates.weekYear)")
            print("  Week of year: \(coordinates.weekNumber)")
            print("  Day of week: \(coordinates.dayOfWeek)")
            print("  Looking for key: \(key)")
            print("  All week entries count: \(allWeekEntries.count)")

            // Also print ALL keys in the entire entriesByWeek dictionary
            print("  ALL KEYS in MemoryViewModel:")
            let allKeys = Array(memoryViewModel.entriesByWeek.keys).sorted()
            for dictKey in allKeys {
                let count = memoryViewModel.entriesByWeek[dictKey]?.count ?? 0
                let entries = memoryViewModel.entriesByWeek[dictKey] ?? []
                print("    - \(dictKey): \(count) entries - \(entries.map { $0.title }.joined(separator: ", "))")
            }

            for entry in allWeekEntries {
                print("    - Entry: \(entry.title), type: \(entry.entryType.rawValue), dayOfWeek: \(entry.dayOfWeek?.description ?? "nil")")
            }
        }

        // Filter to entries that match this specific day OR have no specific day set
        let filtered = allWeekEntries.filter { entry in
            entry.dayOfWeek == coordinates.dayOfWeek || entry.dayOfWeek == nil
        }

        // Debug November 17 filtering
        if dateString == "Nov 17, 2025" {
            print("  Filtered entries count: \(filtered.count)")
            for entry in filtered {
                print("    - Filtered: \(entry.title), type: \(entry.entryType.rawValue), dayOfWeek: \(entry.dayOfWeek?.description ?? "nil")")
            }
        }

        if isToday && !filtered.isEmpty {
            print("  Filtered entries count: \(filtered.count)")
            for entry in filtered {
                print("    - Filtered: \(entry.title), type: \(entry.entryType.rawValue)")
            }
        }

        return filtered
    }

    private var hasMemory: Bool {
        entriesForDate.contains { $0.entryType == .memory }
    }

    private var hasGoal: Bool {
        entriesForDate.contains { $0.entryType == .goal }
    }

    private var hasCompletedGoal: Bool {
        entriesForDate.contains { $0.entryType == .goal && $0.isCompleted }
    }

    var body: some View {
        ZStack {
            // Background color based on entry type
            if hasMemory {
                Circle()
                    .fill(AppColors.personalColor.opacity(isSelected ? 1.0 : 0.7))
                // Add red stroke if it's today, or black stroke if selected
                if isToday {
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                } else if isSelected {
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                }
            } else if hasCompletedGoal {
                // Green highlight for completed goals
                Circle()
                    .fill(Color.green.opacity(isSelected ? 1.0 : 0.7))
                // Add red stroke if it's today, or black stroke if selected
                if isToday {
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                } else if isSelected {
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                }
            } else if hasGoal {
                Circle()
                    .fill(AppColors.accent.opacity(isSelected ? 1.0 : 0.7))
                // Add red stroke if it's today, or black stroke if selected
                if isToday {
                    Circle()
                        .stroke(Color.red, lineWidth: 2)
                } else if isSelected {
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                }
            } else if isSelected {
                Circle()
                    .fill(AppColors.primary)
            } else if isToday {
                Circle()
                    .stroke(AppColors.primary, lineWidth: 2)
            }

            Text("\(dayNumber)")
                .font(.system(size: 12, weight: isSelected || isToday || hasMemory || hasGoal || hasCompletedGoal ? .bold : .regular))
                .foregroundColor(
                    hasMemory || hasGoal || hasCompletedGoal || isSelected ? .white :
                    isToday ? AppColors.primary :
                    isPast ? AppColors.textPrimary :
                    AppColors.textSecondary
                )

            // Special date indicator (small icon in corner)
            if let specialType = primarySpecialDateType {
                VStack {
                    HStack {
                        Spacer()
                        Image(systemName: specialType.icon)
                            .font(.system(size: 6))
                            .foregroundColor(specialType.color)
                            .padding(2)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                            )
                    }
                    Spacer()
                }
                .padding(1)
            }
        }
        .frame(height: 32)
    }
}

// MARK: - Week Picker View
struct WeekPickerView: View {
    @Binding var selectedWeek: Int
    let age: Int
    let userProfile: UserProfile
    @Environment(\.dismiss) var dismiss

    private var calendarYear: Int {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: userProfile.dateOfBirth)
        return birthYear + age
    }

    var body: some View {
        NavigationView {
            VStack {
                Picker("Week", selection: $selectedWeek) {
                    ForEach(0..<52, id: \.self) { week in
                        Text(getWeekLabel(week: week)).tag(week)
                    }
                }
                .pickerStyle(.wheel)
                .padding()

                Spacer()
            }
            .navigationTitle("Select Week")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }

    private func getWeekLabel(week: Int) -> String {
        let calendar = Calendar.current

        // Get the first day of the calendar year
        guard let yearStart = calendar.date(from: DateComponents(year: calendarYear)),
              let weekStart = calendar.date(byAdding: .day, value: week * 7, to: yearStart),
              let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
            return "Week \(week + 1)"
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        let startString = dateFormatter.string(from: weekStart)
        let endString = dateFormatter.string(from: weekEnd)

        // Get the actual year for this week (it might spill into next year)
        let weekYear = calendar.component(.year, from: weekStart)

        return "Week \(week + 1) - \(startString)-\(endString), \(weekYear)"
    }
}

#Preview {
    let sampleProfile = UserProfile(
        name: "Alex",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
        industry: "Technology",
        jobRole: "Software Engineer",
        yearsWorked: 13
    )

    let sampleData = WorkLifeData(
        averageWorkHoursPerDay: 8.0,
        averageWorkDaysPerWeek: 5.0,
        averageCommuteHoursPerDay: 1.0,
        averageOvertimeHoursPerWeek: 5.0,
        totalHoursWorked: 20000,
        totalDaysWorked: 2500,
        totalWeeksWorked: 676,
        totalMonthsWorked: 156,
        totalYearsWorked: 13,
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

    return LifeCalendarView(userProfile: sampleProfile, workLifeData: sampleData)
        .environmentObject(AuthenticationService.shared)
        .padding()
        .background(AppColors.background)
}

// MARK: - Action Buttons View
struct ActionButtonsView: View {
    let date: Date
    let year: YearData
    let existingEntries: [WeekEntry]
    let isDateInPast: (Date) -> Bool
    let isDateCurrent: (Date) -> Bool

    @Binding var showMemoryEditor: Bool
    @Binding var showGoalEditor: Bool
    @Binding var showEntryViewer: Bool
    @Binding var allEntriesToView: [WeekEntry]

    private var memories: [WeekEntry] {
        existingEntries.filter { $0.entryType == .memory }
    }

    private var goals: [WeekEntry] {
        existingEntries.filter { $0.entryType == .goal }
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 12) {
                // Show Add Memory button for past and current dates
                if isDateInPast(date) || isDateCurrent(date) {
                    AnimatedButton(
                        title: "Add Memory",
                        icon: "plus.circle.fill",
                        action: {
                            showMemoryEditor = true
                        },
                        style: .primary
                    )
                }

                // Show Add Goal button for future and current dates
                if !isDateInPast(date) || isDateCurrent(date) {
                    AnimatedButton(
                        title: "Add Goal",
                        icon: "plus.circle.fill",
                        action: {
                            showGoalEditor = true
                        },
                        style: .secondary
                    )
                }
            }
            .id(existingEntries.count)
            .padding()
            .background(
                AppColors.background
                    .shadow(color: Color.black.opacity(0.1), radius: 8, y: -4)
            )
        }
    }
}

// MARK: - Multiple Entries Carousel View
struct MultipleEntriesCarouselView: View {
    let initialEntries: [WeekEntry]
    let userProfile: UserProfile

    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var currentIndex = 0
    @State private var showDeleteAlert = false
    @State private var showEditSheet = false
    @State private var showReminderSheet = false
    @State private var showCompleteAlert = false
    @State private var convertToMemory = false

    // Compute current entries dynamically from MemoryViewModel
    private var entries: [WeekEntry] {
        guard let firstEntry = initialEntries.first else { return [] }
        let currentEntries = memoryViewModel.getEntries(
            week: firstEntry.weekNumber,
            year: firstEntry.weekYear,
            dayOfWeek: firstEntry.dayOfWeek
        )
        // Filter to match the same entry type as initial entries
        return currentEntries.filter { $0.entryType == firstEntry.entryType }
    }

    // Safe accessor for current entry
    private var currentEntry: WeekEntry? {
        guard !entries.isEmpty, currentIndex >= 0, currentIndex < entries.count else {
            return nil
        }
        return entries[currentIndex]
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Check if entries is empty first
                if entries.isEmpty {
                    // Dismiss if no entries left
                    Color.clear
                        .onAppear {
                            dismiss()
                        }
                } else if let entry = currentEntry {
                    // Background
                    if entry.entryType == .memory {
                        MemoryBackground()
                    } else {
                        GoalBackground()
                    }
                }

                VStack(spacing: 0) {
                    // Page indicator
                    if entries.count > 1 {
                        HStack(spacing: 8) {
                            ForEach(0..<entries.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: 8, height: 8)
                            }
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    }

                    // Carousel content
                    TabView(selection: $currentIndex) {
                        ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                            ScrollView {
                                if entry.entryType == .memory {
                                    MemoryContentView(
                                        entry: entry,
                                        userProfile: userProfile,
                                        selectedPhotoIndex: .constant(nil)
                                    )
                                } else {
                                    GoalContentView(
                                        entry: entry,
                                        userProfile: userProfile,
                                        selectedPhotoIndex: .constant(nil)
                                    )
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .overlay(alignment: .bottom) {
                // Persistent swipe indicators at bottom
                if entries.count > 1 {
                    HStack(spacing: 60) {
                        // Left arrow
                        SwipeIndicator(
                            direction: .left,
                            isEnabled: currentIndex > 0
                        )

                        // Right arrow
                        SwipeIndicator(
                            direction: .right,
                            isEnabled: currentIndex < entries.count - 1
                        )
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(currentEntry?.entryType == .memory ?
                            Color(red: 0.7, green: 0.5, blue: 0.4) : AppColors.accent)
                    }
                }

                ToolbarItem(placement: .principal) {
                    if entries.count > 1 {
                        Text("\(currentIndex + 1) of \(entries.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if let entry = currentEntry {
                        Menu {
                            // Show Mark as Complete option only for goals
                            if entry.entryType == .goal {
                                if !entry.isCompleted {
                                    Button(action: { showCompleteAlert = true }) {
                                        Label("Mark as Complete", systemImage: "checkmark.circle")
                                    }
                                } else {
                                    Label("Completed", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }

                                Button(action: { showReminderSheet = true }) {
                                    Label(entry.reminderEnabled ? "Edit Reminder" : "Set Reminder",
                                          systemImage: entry.reminderEnabled ? "bell.fill" : "bell")
                                }
                            }

                            Button(action: {
                                showEditSheet = true
                            }) {
                                Label("Edit", systemImage: "pencil")
                            }
                            Button(role: .destructive, action: {
                                showDeleteAlert = true
                            }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(entry.entryType == .memory ?
                                    Color(red: 0.7, green: 0.5, blue: 0.4) : AppColors.accent)
                        }
                    }
                }
            }
            .alert(currentEntry?.entryType == .memory ? "Delete Memory" : "Delete Goal", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteCurrentEntry()
                }
            } message: {
                Text("Are you sure you want to delete this \(currentEntry?.entryType == .memory ? "memory" : "goal")?")
            }
            .alert("Mark Goal as Complete", isPresented: $showCompleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Complete & Convert to Memory") {
                    convertToMemory = true
                    markGoalComplete()
                }
                Button("Complete Only") {
                    convertToMemory = false
                    markGoalComplete()
                }
            } message: {
                Text("Would you like this goal to become a memory once the goal date passes?")
            }
            .sheet(isPresented: $showEditSheet) {
                if let weekData = createWeekData(), let entry = currentEntry {
                    EntryEditorView(
                        week: weekData,
                        userProfile: userProfile,
                        existingEntry: entry,
                        isPast: entry.entryType == .memory
                    )
                    .environmentObject(memoryViewModel)
                    .environmentObject(authService)
                }
            }
            .sheet(isPresented: $showReminderSheet) {
                if let entry = currentEntry {
                    ReminderSettingsView(entry: entry) { reminderDate in
                        saveReminder(for: entry, date: reminderDate)
                    }
                }
            }
        }
    }

    private func createWeekData() -> WeekData? {
        guard let entry = currentEntry else { return nil }
        return WeekData(
            year: entry.weekYear,
            week: entry.weekNumber,
            isPast: entry.entryType == .memory,
            isWork: false,
            isCurrent: false,
            age: entry.weekYear
        )
    }

    private func deleteCurrentEntry() {
        print("🗑️ MultipleEntriesCarouselView.deleteCurrentEntry: Delete button pressed")
        print("  Current index: \(currentIndex)")
        print("  Total entries: \(entries.count)")

        Task {
            do {
                guard let entryToDelete = currentEntry else {
                    print("❌ MultipleEntriesCarouselView: No current entry to delete")
                    return
                }
                print("📝 MultipleEntriesCarouselView: About to delete entry")
                print("  Entry ID: \(entryToDelete.id.uuidString)")
                print("  Entry title: \(entryToDelete.title)")
                print("  Entry type: \(entryToDelete.entryType.rawValue)")

                // Adjust currentIndex BEFORE deleting to prevent out-of-bounds
                let entriesCountBeforeDelete = entries.count
                if entriesCountBeforeDelete > 1 && currentIndex >= entriesCountBeforeDelete - 1 {
                    print("  Adjusting currentIndex from \(currentIndex) to \(currentIndex - 1)")
                    currentIndex -= 1
                }

                try await memoryViewModel.deleteEntry(entryToDelete)
                print("✅ MultipleEntriesCarouselView: Entry deleted successfully")

                // The view will automatically update since entries is now a computed property
                // If entries becomes empty, the onAppear in body will dismiss the view
                print("📱 MultipleEntriesCarouselView: Entries remaining after delete: \(entries.count)")
            } catch {
                print("❌ MultipleEntriesCarouselView: Failed to delete entry: \(error.localizedDescription)")
                print("  Error details: \(error)")
            }
        }
    }

    private func saveReminder(for entry: WeekEntry, date: Date) {
        print("🔔 MultipleEntriesCarouselView: Saving reminder for '\(entry.title)' at \(date)")

        Task { @MainActor in
            do {
                // Schedule notification
                let notificationId = try await NotificationManager.shared.scheduleReminder(for: entry, at: date)

                // Update entry
                var updatedEntry = entry
                updatedEntry.reminderDate = date
                updatedEntry.reminderEnabled = true
                updatedEntry.notificationId = notificationId

                try await memoryViewModel.updateEntry(updatedEntry)

                print("✅ MultipleEntriesCarouselView: Reminder saved successfully")
            } catch {
                print("❌ MultipleEntriesCarouselView: Failed to save reminder - \(error.localizedDescription)")
            }
        }
    }

    private func markGoalComplete() {
        guard let entry = currentEntry else { return }

        print("✅ MultipleEntriesCarouselView.markGoalComplete: Marking goal as complete")
        print("  Entry ID: \(entry.id.uuidString)")
        print("  Entry title: \(entry.title)")
        print("  Convert to memory: \(convertToMemory)")

        Task { @MainActor in
            do {
                var updatedEntry = entry
                updatedEntry.isCompleted = true
                updatedEntry.completedAt = Date()
                updatedEntry.convertToMemoryWhenPassed = convertToMemory

                try await memoryViewModel.updateEntry(updatedEntry)
                print("✅ MultipleEntriesCarouselView: Goal marked as complete successfully")

                // Dismiss after successful update
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                dismiss()
            } catch {
                print("❌ MultipleEntriesCarouselView: Failed to mark goal as complete - \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Swipe Indicator Component
struct SwipeIndicator: View {
    enum Direction {
        case left, right

        var chevron: String {
            switch self {
            case .left: return "chevron.left"
            case .right: return "chevron.right"
            }
        }
    }

    let direction: Direction
    let isEnabled: Bool

    var body: some View {
        ZStack {
            // Subtle background for visibility
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 44, height: 44)

            Image(systemName: direction.chevron)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white.opacity(isEnabled ? 1.0 : 0.4))
        }
    }
}
