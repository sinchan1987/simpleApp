//
//  SpecialDateGoalEditorView.swift
//  simpleApp
//
//  Editor for creating/editing goals associated with special dates
//

import SwiftUI

struct SpecialDateGoalEditorView: View {
    let specialDate: CombinedSpecialDate
    let userProfile: UserProfile
    let existingGoal: SpecialDateGoal?

    @EnvironmentObject var specialDatesViewModel: SpecialDatesViewModel
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var goalTitle: String
    @State private var goalDescription: String
    @State private var frequency: RecurringFrequency
    @State private var reminderEnabled: Bool
    @State private var reminderLeadTime: Int
    @State private var reminderLeadTimeUnit: LeadTimeUnit
    @State private var generateEntries: Bool = true

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeleteAlert = false

    var isEditing: Bool {
        existingGoal != nil
    }

    init(specialDate: CombinedSpecialDate, userProfile: UserProfile, existingGoal: SpecialDateGoal?) {
        self.specialDate = specialDate
        self.userProfile = userProfile
        self.existingGoal = existingGoal

        // Initialize state with existing values or defaults
        _goalTitle = State(initialValue: existingGoal?.goalTitle ?? "")
        _goalDescription = State(initialValue: existingGoal?.goalDescription ?? "")
        _frequency = State(initialValue: existingGoal?.frequency ?? .yearly)
        _reminderEnabled = State(initialValue: existingGoal?.reminderEnabled ?? false)
        _reminderLeadTime = State(initialValue: existingGoal?.reminderLeadTime ?? 1)
        _reminderLeadTimeUnit = State(initialValue: existingGoal?.reminderLeadTimeUnit ?? .weeks)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Goal Info Section
                    goalInfoSection

                    // Frequency Section
                    frequencySection

                    // Reminder Section
                    reminderSection

                    // Generate Entries Toggle (only for new goals)
                    if !isEditing {
                        generateEntriesSection
                    }

                    // Delete Button (only for existing goals)
                    if isEditing {
                        deleteButton
                    }
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle(isEditing ? "Edit Goal" : "Add Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.accent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGoal()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(canSave ? AppColors.accent : AppColors.textSecondary)
                    .disabled(!canSave || isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Goal", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteGoal()
                }
            } message: {
                Text("Are you sure you want to delete this goal?")
            }
        }
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !goalTitle.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - View Components

    private var goalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with special date info
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(specialDate.color.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Image(systemName: specialDate.icon)
                        .font(.system(size: 16))
                        .foregroundColor(specialDate.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal for")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)

                    Text(specialDate.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)

            // Title Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Goal Title")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                TextField("e.g., Buy gift, Plan celebration", text: $goalTitle)
                    .font(.system(size: 16))
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
            }

            // Description Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Description (Optional)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)

                TextEditor(text: $goalDescription)
                    .font(.system(size: 16))
                    .frame(minHeight: 80)
                    .padding(8)
                    .background(Color.white)
                    .cornerRadius(12)
            }
        }
    }

    private var frequencySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Frequency")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 0) {
                ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                    Button(action: { frequency = freq }) {
                        HStack {
                            Text(freq.rawValue.capitalized)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            if frequency == freq {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.accent)
                            }
                        }
                        .padding(16)
                    }

                    if freq != RecurringFrequency.allCases.last {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminder")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            VStack(spacing: 0) {
                // Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable Reminder")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.textPrimary)

                        Text("Get notified before the date")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Spacer()

                    Toggle("", isOn: $reminderEnabled)
                        .labelsHidden()
                        .tint(AppColors.accent)
                }
                .padding(16)

                if reminderEnabled {
                    Divider().padding(.leading, 16)

                    // Lead Time
                    HStack {
                        Text("Remind me")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)

                        Spacer()

                        Picker("", selection: $reminderLeadTime) {
                            ForEach(1...reminderLeadTimeUnit.maxValue, id: \.self) { value in
                                Text("\(value)").tag(value)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.accent)

                        Picker("", selection: $reminderLeadTimeUnit) {
                            ForEach(LeadTimeUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AppColors.accent)

                        Text("before")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(16)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private var generateEntriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar Entries")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Generate Calendar Entries")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Automatically create goals on your calendar for the next 5 years")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $generateEntries)
                    .labelsHidden()
                    .tint(AppColors.accent)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private var deleteButton: some View {
        Button(action: { showDeleteAlert = true }) {
            HStack {
                Image(systemName: "trash")
                Text("Delete Goal")
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

    // MARK: - Actions

    private func saveGoal() {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }

        isSaving = true

        let goal = SpecialDateGoal(
            id: existingGoal?.id ?? UUID(),
            specialDateId: specialDate.id,
            userId: userId,
            goalTitle: goalTitle.trimmingCharacters(in: .whitespaces),
            goalDescription: goalDescription.isEmpty ? nil : goalDescription,
            frequency: frequency,
            reminderEnabled: reminderEnabled,
            reminderLeadTime: reminderEnabled ? reminderLeadTime : nil,
            reminderLeadTimeUnit: reminderEnabled ? reminderLeadTimeUnit : nil,
            isActive: true,
            createdAt: existingGoal?.createdAt ?? Date(),
            updatedAt: Date()
        )

        Task {
            do {
                if isEditing {
                    try await specialDatesViewModel.updateGoal(goal)
                } else {
                    try await specialDatesViewModel.createGoal(goal)

                    // Generate calendar entries if requested
                    if generateEntries {
                        try await specialDatesViewModel.generateWeekEntries(
                            for: specialDate,
                            goal: goal,
                            userProfile: userProfile,
                            memoryViewModel: memoryViewModel
                        )
                    }
                }

                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isSaving = false
                }
            }
        }
    }

    private func deleteGoal() {
        guard let goal = existingGoal else { return }

        Task {
            do {
                try await specialDatesViewModel.deleteGoal(goal)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

// MARK: - Preview
// Preview disabled - requires full app context
