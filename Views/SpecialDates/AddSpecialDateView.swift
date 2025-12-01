//
//  AddSpecialDateView.swift
//  simpleApp
//
//  Form for adding new custom special dates
//

import SwiftUI

struct AddSpecialDateView: View {
    let userProfile: UserProfile

    @EnvironmentObject var specialDatesViewModel: SpecialDatesViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var date = Date()
    @State private var selectedCategory: SpecialDateCategory = .custom
    @State private var isRecurring = true
    @State private var notes = ""
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Name Section
                    nameSection

                    // Date Section
                    dateSection

                    // Category Section
                    categorySection

                    // Options Section
                    optionsSection

                    // Notes Section
                    notesSection
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Add Special Date")
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
                        saveDate()
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
        }
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - View Components

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            TextField("e.g., Mom's Birthday, First Job Anniversary", text: $name)
                .font(.system(size: 16))
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
        }
    }

    private var dateSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(SpecialDateCategory.allCases, id: \.self) { category in
                    CategoryButton(
                        category: category,
                        isSelected: selectedCategory == category,
                        action: { selectedCategory = category }
                    )
                }
            }
        }
    }

    private var optionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Options")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recurring Yearly")
                        .font(.system(size: 16))
                        .foregroundColor(AppColors.textPrimary)

                    Text("Show this date every year")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }

                Spacer()

                Toggle("", isOn: $isRecurring)
                    .labelsHidden()
                    .tint(AppColors.accent)
            }
            .padding(16)
            .background(Color.white)
            .cornerRadius(12)
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes (Optional)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppColors.textSecondary)

            TextEditor(text: $notes)
                .font(.system(size: 16))
                .frame(minHeight: 80)
                .padding(12)
                .background(Color.white)
                .cornerRadius(12)
        }
    }

    // MARK: - Actions

    private func saveDate() {
        guard let userId = authService.currentUser?.id else {
            errorMessage = "User not authenticated"
            showError = true
            return
        }

        isSaving = true

        let customDate = CustomSpecialDate(
            userId: userId,
            name: name.trimmingCharacters(in: .whitespaces),
            date: date,
            category: selectedCategory,
            isRecurring: isRecurring,
            notes: notes.isEmpty ? nil : notes
        )

        Task {
            do {
                try await specialDatesViewModel.createCustomDate(customDate)
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
}

// MARK: - Category Button Component
struct CategoryButton: View {
    let category: SpecialDateCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : category.color)

                Text(category.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? category.color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Edit Special Date View
struct EditSpecialDateView: View {
    let customDate: CustomSpecialDate
    let userProfile: UserProfile

    @EnvironmentObject var specialDatesViewModel: SpecialDatesViewModel
    @Environment(\.dismiss) var dismiss

    @State private var name: String
    @State private var date: Date
    @State private var selectedCategory: SpecialDateCategory
    @State private var isRecurring: Bool
    @State private var notes: String
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(customDate: CustomSpecialDate, userProfile: UserProfile) {
        self.customDate = customDate
        self.userProfile = userProfile
        _name = State(initialValue: customDate.name)
        _date = State(initialValue: customDate.date)
        _selectedCategory = State(initialValue: customDate.category)
        _isRecurring = State(initialValue: customDate.isRecurring)
        _notes = State(initialValue: customDate.notes ?? "")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        TextField("e.g., Mom's Birthday", text: $name)
                            .font(.system(size: 16))
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    // Date Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Date")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        DatePicker("", selection: $date, displayedComponents: .date)
                            .datePickerStyle(.graphical)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                    }

                    // Category Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(SpecialDateCategory.allCases, id: \.self) { category in
                                CategoryButton(
                                    category: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                    }

                    // Recurring Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recurring Yearly")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Show this date every year")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Toggle("", isOn: $isRecurring)
                            .labelsHidden()
                            .tint(AppColors.accent)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)

                    // Notes Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (Optional)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        TextEditor(text: $notes)
                            .font(.system(size: 16))
                            .frame(minHeight: 80)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(12)
                    }
                }
                .padding(20)
            }
            .background(AppColors.background)
            .navigationTitle("Edit Special Date")
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
                        saveChanges()
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(!name.isEmpty ? AppColors.accent : AppColors.textSecondary)
                    .disabled(name.isEmpty || isSaving)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveChanges() {
        isSaving = true

        var updated = customDate
        updated.name = name.trimmingCharacters(in: .whitespaces)
        updated.date = date
        updated.category = selectedCategory
        updated.isRecurring = isRecurring
        updated.notes = notes.isEmpty ? nil : notes

        Task {
            do {
                try await specialDatesViewModel.updateCustomDate(updated)
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
}

// MARK: - Preview
// Preview disabled - requires full app context
