//
//  WeekDetailSheet.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct WeekDetailSheet: View {
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    let week: WeekData
    let userProfile: UserProfile

    @State private var showEditor = false
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    @State private var showReminderSheet = false

    var entry: WeekEntry? {
        memoryViewModel.getEntry(week: week.week, year: week.year)
    }

    var isPastWeek: Bool {
        return week.year < userProfile.age ||
               (week.year == userProfile.age && week.week <= getCurrentWeekNumber())
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Week Info Header
                        WeekInfoHeader(week: week, userProfile: userProfile)

                        if let entry = entry {
                            // Show existing entry
                            EntryContentView(entry: entry)
                                .environmentObject(memoryViewModel)
                        } else {
                            // Show empty state
                            EmptyStateView(isPast: isPastWeek)
                        }
                    }
                    .padding(Constants.Layout.paddingLarge)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }

                if let currentEntry = entry {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // Show reminder option only for goals
                            if currentEntry.entryType == .goal {
                                Button(action: { showReminderSheet = true }) {
                                    Label(currentEntry.reminderEnabled ? "Edit Reminder" : "Set Reminder",
                                          systemImage: currentEntry.reminderEnabled ? "bell.fill" : "bell")
                                }
                            }

                            Button(action: { showEditor = true }) {
                                Label("Edit", systemImage: "pencil")
                            }

                            Button(role: .destructive, action: { showDeleteAlert = true }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                } else {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: { showEditor = true }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppColors.primary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                EntryEditorView(
                    week: week,
                    userProfile: userProfile,
                    existingEntry: entry,
                    isPast: isPastWeek
                )
                .environmentObject(memoryViewModel)
                .environmentObject(authService)
            }
            .sheet(isPresented: $showReminderSheet) {
                if let currentEntry = entry {
                    ReminderSettingsView(entry: currentEntry) { reminderDate in
                        saveReminder(for: currentEntry, date: reminderDate)
                    }
                    .environmentObject(memoryViewModel)
                }
            }
            .alert("Delete Entry", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
            } message: {
                Text("Are you sure you want to delete this \(entry?.entryType.displayName.lowercased() ?? "entry")? This action cannot be undone.")
            }
        }
    }

    private func getCurrentWeekNumber() -> Int {
        // Use consistent calculation with DateCalculator
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)
        guard let yearStart = calendar.date(from: DateComponents(year: currentYear, month: 1, day: 1)) else {
            return 0
        }
        let daysSinceYearStart = calendar.dateComponents([.day], from: yearStart, to: now).day ?? 0
        return daysSinceYearStart / 7  // 0-indexed week number
    }

    private func saveReminder(for entry: WeekEntry, date: Date) {
        print("🔔 WeekDetailSheet: Saving reminder for '\(entry.title)' at \(date)")

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

                print("✅ WeekDetailSheet: Reminder saved successfully")
            } catch {
                print("❌ WeekDetailSheet: Failed to save reminder - \(error.localizedDescription)")
            }
        }
    }

    private func deleteEntry() {
        guard let entry = entry else { return }

        isDeleting = true

        Task {
            do {
                try await memoryViewModel.deleteEntry(entry)
                dismiss()
            } catch {
                // Show error
                isDeleting = false
            }
        }
    }
}

// MARK: - Week Info Header
struct WeekInfoHeader: View {
    let week: WeekData
    let userProfile: UserProfile

    var weekDateRange: String {
        let calendar = Calendar.current
        let birthDate = userProfile.dateOfBirth

        // Calculate the start date of this week
        guard let weekStartDate = calendar.date(
            byAdding: .day,
            value: (week.year * 52 + week.week) * 7,
            to: birthDate
        ) else {
            return "Week \(week.week + 1)"
        }

        guard let weekEndDate = calendar.date(byAdding: .day, value: 6, to: weekStartDate) else {
            return "Week \(week.week + 1)"
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(week.week + 1), Year \(week.year)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)

                    Text(weekDateRange)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Age \(week.age)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                // Week type indicator
                WeekTypeIndicator(week: week)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

struct WeekTypeIndicator: View {
    let week: WeekData

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: week.isWork ? "briefcase.fill" : week.isPast ? "heart.fill" : "sparkles")
                .font(.system(size: 24))
                .foregroundColor(week.isWork ? AppColors.workColor : week.isPast ? AppColors.personalColor : AppColors.accent)

            Text(week.isWork ? "Work" : week.isPast ? "Life" : "Future")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
        }
        .frame(width: 70, height: 70)
        .background(
            Circle()
                .fill(week.isWork ? AppColors.workColor.opacity(0.1) : week.isPast ? AppColors.personalColor.opacity(0.1) : AppColors.accent.opacity(0.1))
        )
    }
}

// MARK: - Entry Content View
struct EntryContentView: View {
    let entry: WeekEntry
    @EnvironmentObject var memoryViewModel: MemoryViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Entry Type Badge
            HStack {
                Label(entry.entryType.displayName, systemImage: entry.entryType.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(entry.entryType == .memory ? AppColors.personalColor : AppColors.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((entry.entryType == .memory ? AppColors.personalColor : AppColors.accent).opacity(0.1))
                    )

                if entry.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundColor(AppColors.accent)
                }

                Spacer()

                if let dayOfWeek = entry.dayOfWeek {
                    Text(dayName(dayOfWeek))
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            // Title
            Text(entry.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            // Description
            if let description = entry.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .lineSpacing(4)
            }

            // Text Content
            if let textContent = entry.textContent, !textContent.isEmpty {
                Text(textContent)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textPrimary)
                    .lineSpacing(6)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )
            }

            // Photos
            if !entry.photoURLs.isEmpty {
                PhotoGalleryView(photoURLs: entry.photoURLs)
                    .environmentObject(memoryViewModel)
            }

            // Audio
            if let audioURL = entry.audioURL {
                AudioPlayerView(audioURL: audioURL)
            }

            // Tags
            if !entry.tags.isEmpty {
                TagsView(tags: entry.tags)
            }

            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                Text("Created: \(entry.createdAt, style: .date)")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)

                if entry.createdAt != entry.updatedAt {
                    Text("Updated: \(entry.updatedAt, style: .date)")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .padding(.top, 8)
        }
    }

    private func dayName(_ day: Int) -> String {
        let days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        return days[max(0, min(day - 1, 6))]
    }
}

struct TagsView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppColors.primary.opacity(0.1))
                        )
                }
            }
        }
    }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let subviewSize = subview.sizeThatFits(.unspecified)

                if x + subviewSize.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, subviewSize.height)
                x += subviewSize.width + spacing
            }

            size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let isPast: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: isPast ? "photo.on.rectangle.angled" : "flag.fill")
                .font(.system(size: 80))
                .foregroundColor(isPast ? AppColors.personalColor : AppColors.accent)
                .padding(.top, 40)

            VStack(spacing: 12) {
                Text(isPast ? "No Memory Yet" : "No Goal Set")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text(isPast ? "Tap the + button to add a memory from this week of your life" : "Tap the + button to set a goal for this week")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, Constants.Layout.paddingLarge)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

#Preview {
    let sampleWeek = WeekData(
        year: 10,
        week: 25,
        isPast: true,
        isWork: true,
        isCurrent: false,
        age: 10
    )

    let sampleProfile = UserProfile(
        userId: "test123",
        email: "test@example.com",
        isAnonymous: false,
        name: "Alex",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -35, to: Date())!,
        industry: "Technology",
        jobRole: "Software Engineer",
        yearsWorked: 10
    )

    return WeekDetailSheet(week: sampleWeek, userProfile: sampleProfile)
        .environmentObject(MemoryViewModel())
        .environmentObject(AuthenticationService.shared)
}
