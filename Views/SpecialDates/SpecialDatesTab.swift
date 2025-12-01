//
//  SpecialDatesTab.swift
//  simpleApp
//
//  Main tab view for managing special dates
//

import SwiftUI

struct SpecialDatesTab: View {
    let userProfile: UserProfile

    @EnvironmentObject var specialDatesViewModel: SpecialDatesViewModel
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService

    @State private var showAddSheet = false
    @State private var selectedDate: CombinedSpecialDate?
    @State private var searchText = ""
    @State private var selectedFilter: FilterOption = .all

    enum FilterOption: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case custom = "Custom"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            // Filter and Search
            filterAndSearchView

            // Content
            if specialDatesViewModel.isLoading {
                loadingView
            } else if filteredDates.isEmpty {
                emptyStateView
            } else {
                dateListView
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddSpecialDateView(userProfile: userProfile)
        }
        .sheet(item: $selectedDate) { date in
            SpecialDateDetailView(specialDate: date, userProfile: userProfile)
        }
        .onAppear {
            loadData()
        }
    }

    // MARK: - Computed Properties

    private var allDates: [CombinedSpecialDate] {
        specialDatesViewModel.getAllSpecialDates(userProfile: userProfile)
    }

    private var filteredDates: [CombinedSpecialDate] {
        var dates = allDates

        // Apply filter
        switch selectedFilter {
        case .all:
            break
        case .upcoming:
            dates = dates.filter { $0.daysUntilNext <= 30 }
        case .custom:
            dates = dates.filter { $0.isCustom }
        }

        // Apply search
        if !searchText.isEmpty {
            dates = dates.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.category.displayName.localizedCaseInsensitiveContains(searchText)
            }
        }

        return dates
    }

    // MARK: - View Components

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Special Dates")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("\(allDates.count) dates tracked")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Button(action: { showAddSheet = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.accent)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var filterAndSearchView: some View {
        VStack(spacing: 12) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppColors.textSecondary)

                TextField("Search dates...", text: $searchText)
                    .font(.system(size: 16))

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .padding(12)
            .background(Color.white)
            .cornerRadius(12)

            // Filter pills
            HStack(spacing: 8) {
                ForEach(FilterOption.allCases, id: \.self) { option in
                    FilterPill(
                        title: option.rawValue,
                        isSelected: selectedFilter == option,
                        action: { selectedFilter = option }
                    )
                }
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private var loadingView: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading special dates...")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))

            Text(searchText.isEmpty ? "No special dates yet" : "No results found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)

            Text(searchText.isEmpty ?
                 "Add birthdays, anniversaries, and other important dates to track." :
                 "Try adjusting your search or filter.")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if searchText.isEmpty {
                Button(action: { showAddSheet = true }) {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Special Date")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(AppColors.accent)
                    .cornerRadius(12)
                }
                .padding(.top, 8)
            }

            Spacer()
        }
    }

    private var dateListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredDates) { date in
                    SpecialDateRow(date: date)
                        .onTapGesture {
                            selectedDate = date
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Helper Methods

    private func loadData() {
        guard let userId = authService.currentUser?.id else { return }

        Task {
            await specialDatesViewModel.loadAllData(forUser: userId)
        }
    }
}

// MARK: - Filter Pill Component
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : AppColors.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppColors.accent : Color.white)
                .cornerRadius(20)
        }
    }
}

// MARK: - Special Date Row Component
struct SpecialDateRow: View {
    let date: CombinedSpecialDate

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(date.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: date.icon)
                    .font(.system(size: 20))
                    .foregroundColor(date.color)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(date.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)

                HStack(spacing: 8) {
                    Text(date.category.displayName)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)

                    if date.isRecurring {
                        Text("Recurring")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppColors.accent)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.accent.opacity(0.1))
                            .cornerRadius(4)
                    }
                }

                Text(formattedDate)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            // Next occurrence
            VStack(alignment: .trailing, spacing: 4) {
                Text(date.nextOccurrenceText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(date.daysUntilNext <= 7 ? AppColors.accent : AppColors.textPrimary)

                if date.isCustom {
                    Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary.opacity(0.5))
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date.date)
    }
}

// MARK: - Preview
// Preview disabled - requires full app context
