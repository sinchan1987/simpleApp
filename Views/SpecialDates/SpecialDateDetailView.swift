//
//  SpecialDateDetailView.swift
//  simpleApp
//
//  Detail view for a special date with goals management
//

import SwiftUI

struct SpecialDateDetailView: View {
    let specialDate: CombinedSpecialDate
    let userProfile: UserProfile

    @EnvironmentObject var specialDatesViewModel: SpecialDatesViewModel
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var showEditSheet = false
    @State private var showAddGoalSheet = false
    @State private var showDeleteAlert = false
    @State private var selectedGoal: SpecialDateGoal?

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Card
                    headerCard

                    // Info Section
                    infoSection

                    // Goals Section
                    goalsSection

                    // Notes Section (if custom and has notes)
                    if specialDate.isCustom, let notes = specialDate.notes, !notes.isEmpty {
                        notesSection(notes)
                    }

                    // Delete Button (only for custom dates)
                    if specialDate.isCustom {
                        deleteButton
                    }
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Special Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }

                if specialDate.isCustom {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Edit") {
                            showEditSheet = true
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                if case .custom(let customDate) = specialDate.sourceType {
                    EditSpecialDateView(customDate: customDate, userProfile: userProfile)
                }
            }
            .sheet(isPresented: $showAddGoalSheet) {
                SpecialDateGoalEditorView(
                    specialDate: specialDate,
                    userProfile: userProfile,
                    existingGoal: nil
                )
            }
            .sheet(item: $selectedGoal) { goal in
                SpecialDateGoalEditorView(
                    specialDate: specialDate,
                    userProfile: userProfile,
                    existingGoal: goal
                )
            }
            .alert("Delete Special Date", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteDate()
                }
            } message: {
                Text("Are you sure you want to delete this special date? This will also delete all associated goals.")
            }
        }
    }

    // MARK: - Computed Properties

    private var goals: [SpecialDateGoal] {
        specialDatesViewModel.getGoals(for: specialDate.id)
    }

    // MARK: - View Components

    private var headerCard: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(specialDate.color.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: specialDate.icon)
                    .font(.system(size: 36))
                    .foregroundColor(specialDate.color)
            }

            // Name
            Text(specialDate.name)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            // Category Badge
            Text(specialDate.category.displayName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(specialDate.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(specialDate.color.opacity(0.1))
                .cornerRadius(8)

            // Next occurrence
            VStack(spacing: 4) {
                Text(specialDate.nextOccurrenceText)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(specialDate.daysUntilNext <= 7 ? AppColors.accent : AppColors.textPrimary)

                Text(formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 0) {
                InfoRow(icon: "calendar", label: "Date", value: formattedFullDate)
                Divider().padding(.leading, 44)
                InfoRow(icon: "arrow.clockwise", label: "Recurring", value: specialDate.isRecurring ? "Yearly" : "One-time")
                Divider().padding(.leading, 44)
                InfoRow(icon: "tag", label: "Type", value: specialDate.isCustom ? "Custom" : "System")
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Goals")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Button(action: { showAddGoalSheet = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("Add")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.accent)
                }
            }

            if goals.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "target")
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.textSecondary.opacity(0.5))

                    Text("No goals yet")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)

                    Text("Add a goal to automatically create calendar entries for this date.")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)

                    Button(action: { showAddGoalSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Goal")
                        }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppColors.accent)
                        .cornerRadius(8)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white)
                .cornerRadius(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(goals) { goal in
                        GoalRow(goal: goal)
                            .onTapGesture {
                                selectedGoal = goal
                            }
                    }
                }
            }
        }
    }

    private func notesSection(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            Text(notes)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textPrimary)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .cornerRadius(12)
        }
    }

    private var deleteButton: some View {
        Button(action: { showDeleteAlert = true }) {
            HStack {
                Image(systemName: "trash")
                Text("Delete Special Date")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(16)
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
        }
        .padding(.top, 8)
    }

    // MARK: - Computed Formatting

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: specialDate.date)
    }

    private var formattedFullDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: specialDate.date)
    }

    // MARK: - Actions

    private func deleteDate() {
        guard case .custom(let customDate) = specialDate.sourceType else { return }

        Task {
            do {
                try await specialDatesViewModel.deleteCustomDate(customDate)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print("❌ Failed to delete date: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(12)
    }
}

// MARK: - Goal Row Component
struct GoalRow: View {
    let goal: SpecialDateGoal

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 16))
                .foregroundColor(AppColors.accent)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.goalTitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: 8) {
                    Text(goal.frequency.rawValue.capitalized)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)

                    if goal.reminderEnabled {
                        HStack(spacing: 4) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 10))
                            Text("Reminder")
                                .font(.system(size: 10))
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview
// Preview disabled - requires full app context
