//
//  RecurringReminderView.swift
//  simpleApp
//
//  Recurring reminder configuration for memories
//

import SwiftUI

struct RecurringReminderView: View {
    @Binding var isRecurring: Bool
    @Binding var frequency: RecurringFrequency?
    @Binding var endDate: Date?
    @Binding var leadTime: Int?
    @Binding var leadTimeUnit: LeadTimeUnit?

    @State private var selectedFrequency: RecurringFrequency = .weekly
    @State private var selectedEndDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
    @State private var selectedLeadTime: Int = 1
    @State private var selectedLeadTimeUnit: LeadTimeUnit = .days

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Recurring toggle
            Toggle(isOn: $isRecurring) {
                HStack {
                    Image(systemName: isRecurring ? "repeat.circle.fill" : "repeat.circle")
                        .font(.system(size: 20))
                        .foregroundColor(isRecurring ? AppColors.accent : AppColors.textSecondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Create Recurring Reminders")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Text("Generate future goals based on this memory")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .onChange(of: isRecurring) { oldValue, newValue in
                if newValue {
                    // Set default values when enabled
                    frequency = selectedFrequency
                    endDate = selectedEndDate
                    leadTime = selectedLeadTime
                    leadTimeUnit = selectedLeadTimeUnit
                } else {
                    // Clear values when disabled
                    frequency = nil
                    endDate = nil
                    leadTime = nil
                    leadTimeUnit = nil
                }
            }

            if isRecurring {
                VStack(alignment: .leading, spacing: 16) {
                    // Frequency picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Frequency")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        Picker("Frequency", selection: $selectedFrequency) {
                            ForEach(RecurringFrequency.allCases, id: \.self) { freq in
                                Text(freq.displayName).tag(freq)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedFrequency) { oldValue, newValue in
                            frequency = newValue
                        }
                    }

                    // End date picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Date")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        DatePicker("", selection: $selectedEndDate, in: Date()..., displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .onChange(of: selectedEndDate) { oldValue, newValue in
                                endDate = newValue
                            }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )

                    // Notification lead time
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notify Me")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)

                        HStack(spacing: 12) {
                            // Lead time value
                            VStack(alignment: .leading, spacing: 4) {
                                Text("How far ahead")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textSecondary)

                                Picker("", selection: $selectedLeadTime) {
                                    ForEach(1...selectedLeadTimeUnit.maxValue, id: \.self) { value in
                                        Text("\(value)").tag(value)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                                .clipped()
                                .onChange(of: selectedLeadTime) { oldValue, newValue in
                                    leadTime = newValue
                                }
                            }

                            // Lead time unit
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time unit")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColors.textSecondary)

                                Picker("", selection: $selectedLeadTimeUnit) {
                                    ForEach(LeadTimeUnit.allCases, id: \.self) { unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 100)
                                .clipped()
                                .onChange(of: selectedLeadTimeUnit) { oldValue, newValue in
                                    leadTimeUnit = newValue
                                    // Reset lead time if it exceeds the new max
                                    if selectedLeadTime > newValue.maxValue {
                                        selectedLeadTime = newValue.maxValue
                                    }
                                }
                            }
                        }

                        Text("You'll be notified \(selectedLeadTime) \(selectedLeadTimeUnit.rawValue) before each reminder")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.textSecondary)
                            .padding(.top, 4)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                    )

                    // Summary
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(AppColors.accent)
                            Text("Recurring Reminder Summary")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }

                        Text(summaryText)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.accent.opacity(0.1))
                    )
                }
                .padding(.leading, 8)
            }
        }
    }

    private var summaryText: String {
        let frequencyText = selectedFrequency.displayName.lowercased()
        let endDateText = formatDate(selectedEndDate)
        let leadTimeText = "\(selectedLeadTime) \(selectedLeadTimeUnit.rawValue)"

        return "Goals will be created \(frequencyText) until \(endDateText). You'll receive a notification \(leadTimeText) before each reminder date."
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    RecurringReminderView(
        isRecurring: .constant(true),
        frequency: .constant(.weekly),
        endDate: .constant(Calendar.current.date(byAdding: .year, value: 1, to: Date())!),
        leadTime: .constant(1),
        leadTimeUnit: .constant(.days)
    )
    .padding()
    .background(AppColors.background)
}
