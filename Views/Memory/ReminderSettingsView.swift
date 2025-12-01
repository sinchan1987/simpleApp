//
//  ReminderSettingsView.swift
//  simpleApp
//
//  View for setting custom reminders for goals
//

import SwiftUI

struct ReminderSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var memoryViewModel: MemoryViewModel

    let entry: WeekEntry
    let onSave: (Date) -> Void

    @State private var reminderDate: Date
    @State private var reminderEnabled: Bool
    @State private var showError = false
    @State private var errorMessage = ""

    init(entry: WeekEntry, onSave: @escaping (Date) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _reminderDate = State(initialValue: entry.reminderDate ?? Date().addingTimeInterval(3600)) // Default to 1 hour from now
        _reminderEnabled = State(initialValue: entry.reminderEnabled)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 50))
                                .foregroundColor(AppColors.accent)
                                .padding(.top, 20)

                            Text("Set Reminder")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.textPrimary)

                            Text("Get notified about your goal")
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(.bottom, 20)

                        // Goal Info Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goal")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            HStack(spacing: 12) {
                                Image(systemName: "flag.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppColors.accent)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(entry.title)
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)

                                    if let description = entry.description, !description.isEmpty {
                                        Text(description)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textSecondary)
                                            .lineLimit(2)
                                    }
                                }

                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.accent.opacity(0.1))
                            )
                        }

                        // Date & Time Picker
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reminder Date & Time")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            DatePicker(
                                "Select Date & Time",
                                selection: $reminderDate,
                                in: Date()...,
                                displayedComponents: [.date, .hourAndMinute]
                            )
                            .datePickerStyle(.graphical)
                            .accentColor(AppColors.accent)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
                            )
                        }

                        // Reminder Preview
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Preview")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            HStack(spacing: 12) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.primary)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("You'll be reminded on:")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textSecondary)

                                    Text(formatReminderDate(reminderDate))
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.textPrimary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.primary.opacity(0.1))
                            )
                        }

                        // Save Button
                        Button(action: saveReminder) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                Text("Set Reminder")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppColors.accent)
                            )
                        }
                        .padding(.top, 10)

                        // Clear Reminder Button (if reminder exists)
                        if entry.reminderEnabled {
                            Button(action: clearReminder) {
                                HStack {
                                    Image(systemName: "bell.slash.fill")
                                        .font(.system(size: 16))
                                    Text("Clear Reminder")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red, lineWidth: 2)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitle("", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func formatReminderDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func saveReminder() {
        onSave(reminderDate)
        dismiss()
    }

    private func clearReminder() {
        // Create entry with cleared reminder
        var updatedEntry = entry
        updatedEntry.reminderEnabled = false
        updatedEntry.reminderDate = nil

        // Cancel notification
        if let notificationId = entry.notificationId {
            NotificationManager.shared.cancelNotification(withId: notificationId)
        }

        updatedEntry.notificationId = nil

        // Update in ViewModel
        Task {
            do {
                try await memoryViewModel.updateEntry(updatedEntry)
                dismiss()
            } catch {
                errorMessage = "Failed to clear reminder: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}
