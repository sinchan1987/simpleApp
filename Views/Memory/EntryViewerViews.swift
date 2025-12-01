//
//  EntryViewerViews.swift
//  simpleApp
//
//  Created by Claude Code
//

import SwiftUI
import MapKit

// MARK: - Memory Viewer (Nostalgic Design)
struct MemoryViewerView: View {
    let entry: WeekEntry
    let userProfile: UserProfile

    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var selectedPhotoIndex: Int? = nil

    var body: some View {
        NavigationView {
            memoryScrollContent
        }
    }

    private var memoryScrollContent: some View {
        scrollViewContent
            .sheet(isPresented: $showEditSheet) {
                editSheet
            }
            .alert("Delete Memory", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
            } message: {
                Text("Are you sure you want to delete this memory?")
            }
    }

    private var scrollViewContent: some View {
        ScrollView {
            MemoryContentView(
                entry: entry,
                userProfile: userProfile,
                selectedPhotoIndex: $selectedPhotoIndex
            )
        }
        .background(MemoryBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                menuButton
            }
        }
    }

    private var backButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.4))
        }
    }

    private var menuButton: some View {
        Menu {
            Button(action: { showEditSheet = true }) {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive, action: { showDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.4))
        }
    }

    @ViewBuilder
    private var editSheet: some View {
        if let weekData = createWeekData() {
            EntryEditorView(
                week: weekData,
                userProfile: userProfile,
                existingEntry: entry,
                isPast: true
            )
            .environmentObject(memoryViewModel)
            .environmentObject(authService)
        }
    }

    private func createWeekData() -> WeekData? {
        WeekData(
            year: entry.weekYear,
            week: entry.weekNumber,
            isPast: true,
            isWork: false,
            isCurrent: false,
            age: entry.weekYear
        )
    }

    private func deleteEntry() {
        print("🗑️ MemoryViewerView.deleteEntry: Delete button pressed")
        print("  Entry ID: \(entry.id.uuidString)")
        print("  Entry title: \(entry.title)")
        print("  Entry type: \(entry.entryType.rawValue)")

        Task { @MainActor in
            do {
                print("📝 MemoryViewerView: Calling memoryViewModel.deleteEntry")
                try await memoryViewModel.deleteEntry(entry)
                print("✅ MemoryViewerView: Delete successful, waiting before dismissing")

                // Add a small delay to allow state updates to complete before dismissing
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                print("✅ MemoryViewerView: Dismissing view")
                dismiss()
            } catch {
                print("❌ MemoryViewerView: Delete failed with error: \(error.localizedDescription)")
                print("  Error details: \(error)")
            }
        }
    }
}

// MARK: - Memory Content View
struct MemoryContentView: View {
    let entry: WeekEntry
    let userProfile: UserProfile
    @Binding var selectedPhotoIndex: Int?

    @State private var animateContent = false

    var body: some View {
        VStack(spacing: 24) {
            MemoryHeaderView(entry: entry, userProfile: userProfile)
                .scaleEffect(animateContent ? 1 : 0.9)
                .opacity(animateContent ? 1 : 0)

            if !entry.photoURLs.isEmpty {
                MemoryPhotosView(
                    photoURLs: entry.photoURLs,
                    selectedPhotoIndex: $selectedPhotoIndex
                )
                .scaleEffect(animateContent ? 1 : 0.95)
                .opacity(animateContent ? 1 : 0)
            }

            if let locationName = entry.locationName,
               let latitude = entry.locationLatitude,
               let longitude = entry.locationLongitude {
                MemoryLocationView(
                    locationName: locationName,
                    latitude: latitude,
                    longitude: longitude
                )
                .scaleEffect(animateContent ? 1 : 0.95)
                .opacity(animateContent ? 1 : 0)
            }

            if let description = entry.description, !description.isEmpty {
                MemoryDescriptionCard(text: description)
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }

            if let textContent = entry.textContent, !textContent.isEmpty {
                MemoryDetailCard(text: textContent)
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }

            if !entry.tags.isEmpty {
                MemoryTagsView(tags: entry.tags)
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }

            if entry.isFavorite {
                MemoryFavoriteView()
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }
        }
        .padding(.bottom, 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateContent = true
            }
        }
    }
}

// MARK: - Memory Background
struct MemoryBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.95, blue: 0.90),
                    Color(red: 0.96, green: 0.93, blue: 0.88),
                    Color(red: 0.95, green: 0.91, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Color.white.opacity(0.3)
                .blendMode(.overlay)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Memory Header
struct MemoryHeaderView: View {
    let entry: WeekEntry
    let userProfile: UserProfile

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.4))
                Text("Memory")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.4))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color(red: 0.9, green: 0.8, blue: 0.7).opacity(0.4))
            )

            Text(entry.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            if let actualDate = calculateActualDate() {
                Text(formatDate(actualDate))
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .italic()
            }
        }
        .padding(.top, 20)
    }

    private func calculateActualDate() -> Date? {
        // Use centralized DateCalculator for consistent week→date conversion
        let dateCalculator = DateCalculator()
        return dateCalculator.weekCoordinatesToDate(
            weekYear: entry.weekYear,
            weekNumber: entry.weekNumber,
            dayOfWeek: entry.dayOfWeek ?? 1,
            userBirthDate: userProfile.dateOfBirth
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Memory Photos
struct MemoryPhotosView: View {
    let photoURLs: [String]
    @Binding var selectedPhotoIndex: Int?

    var body: some View {
        VStack(spacing: 16) {
            ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, photoURL in
                PolaroidPhotoView(photoURL: photoURL, index: index)
                    .onTapGesture {
                        selectedPhotoIndex = index
                    }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Polaroid Photo
struct PolaroidPhotoView: View {
    let photoURL: String
    let index: Int

    @State private var rotation: Double = 0

    var body: some View {
        polaroidCard
            .rotationEffect(.degrees(rotation))
            .onAppear {
                rotation = Double.random(in: -3...3)
            }
    }

    private var polaroidCard: some View {
        VStack(spacing: 0) {
            photoContent
            Rectangle()
                .fill(Color.white)
                .frame(width: 280, height: 60)
        }
        .background(Color.white)
        .cornerRadius(4)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 5, y: 5)
    }

    private var photoContent: some View {
        AsyncImage(url: URL(string: photoURL)) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 280, height: 280)
                    .clipped()
            default:
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 280, height: 280)
            }
        }
    }
}

// MARK: - Memory Description Card
struct MemoryDescriptionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "quote.opening")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.4))
                Text("What Happened")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }

            Text(text)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .lineSpacing(6)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Memory Detail Card
struct MemoryDetailCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.closed")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.4))
                Text("The Full Story")
                    .font(.system(size: 14, weight: .semibold, design: .serif))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }

            Text(text)
                .font(.system(size: 16, design: .serif))
                .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))
                .lineSpacing(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color(red: 0.3, green: 0.2, blue: 0.1).opacity(0.1), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - Memory Tags
struct MemoryTagsView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Moments")
                .font(.system(size: 14, weight: .semibold, design: .serif))
                .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.3))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(red: 0.9, green: 0.8, blue: 0.7).opacity(0.4))
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Memory Favorite
struct MemoryFavoriteView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .foregroundColor(Color(red: 0.8, green: 0.4, blue: 0.4))
            Text("A Cherished Memory")
                .font(.system(size: 14, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.6, green: 0.3, blue: 0.3))
                .italic()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(red: 0.95, green: 0.85, blue: 0.85).opacity(0.6))
        )
    }
}

// MARK: - Goal Viewer (Motivational Design)
struct GoalViewerView: View {
    let entry: WeekEntry
    let userProfile: UserProfile

    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    @State private var showEditSheet = false
    @State private var showDeleteAlert = false
    @State private var selectedPhotoIndex: Int? = nil
    @State private var showReminderSheet = false
    @State private var showCompleteAlert = false
    @State private var convertToMemory = false

    var body: some View {
        NavigationView {
            goalScrollContent
        }
    }

    private var goalScrollContent: some View {
        goalScrollViewContent
            .sheet(isPresented: $showEditSheet) {
                goalEditSheet
            }
            .sheet(isPresented: $showReminderSheet) {
                reminderSheet
            }
            .alert("Delete Goal", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteEntry()
                }
            } message: {
                Text("Are you sure you want to delete this goal?")
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
    }

    private var goalScrollViewContent: some View {
        ScrollView {
            GoalContentView(
                entry: entry,
                userProfile: userProfile,
                selectedPhotoIndex: $selectedPhotoIndex
            )
        }
        .background(GoalBackground())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                goalBackButton
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                goalMenuButton
            }
        }
    }

    private var goalBackButton: some View {
        Button(action: { dismiss() }) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                Text("Back")
            }
            .foregroundColor(AppColors.accent)
        }
    }

    private var goalMenuButton: some View {
        Menu {
            if !entry.isCompleted {
                Button(action: { showCompleteAlert = true }) {
                    Label("Mark as Complete", systemImage: "checkmark.circle")
                }
            } else {
                Label("Completed", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }

            Button(action: { showReminderSheet = true }) {
                Label(entry.reminderEnabled ? "Edit Reminder" : "Set Reminder", systemImage: entry.reminderEnabled ? "bell.fill" : "bell")
            }

            Button(action: { showEditSheet = true }) {
                Label("Edit", systemImage: "pencil")
            }

            Button(role: .destructive, action: { showDeleteAlert = true }) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .foregroundColor(AppColors.accent)
        }
    }

    @ViewBuilder
    private var goalEditSheet: some View {
        if let weekData = createWeekData() {
            EntryEditorView(
                week: weekData,
                userProfile: userProfile,
                existingEntry: entry,
                isPast: false
            )
            .environmentObject(memoryViewModel)
            .environmentObject(authService)
        }
    }

    private var reminderSheet: some View {
        ReminderSettingsView(entry: entry) { reminderDate in
            saveReminder(date: reminderDate)
        }
        .environmentObject(memoryViewModel)
    }

    private func createWeekData() -> WeekData? {
        WeekData(
            year: entry.weekYear,
            week: entry.weekNumber,
            isPast: false,
            isWork: false,
            isCurrent: false,
            age: entry.weekYear
        )
    }

    private func saveReminder(date: Date) {
        print("🔔 GoalViewerView: Saving reminder for '\(entry.title)' at \(date)")

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

                print("✅ GoalViewerView: Reminder saved successfully")
            } catch {
                print("❌ GoalViewerView: Failed to save reminder - \(error.localizedDescription)")
            }
        }
    }

    private func deleteEntry() {
        print("🗑️ GoalViewerView.deleteEntry: Delete button pressed")
        print("  Entry ID: \(entry.id.uuidString)")
        print("  Entry title: \(entry.title)")
        print("  Entry type: \(entry.entryType.rawValue)")

        Task { @MainActor in
            do {
                print("📝 GoalViewerView: Calling memoryViewModel.deleteEntry")
                try await memoryViewModel.deleteEntry(entry)
                print("✅ GoalViewerView: Delete successful, waiting before dismissing")

                // Add a small delay to allow state updates to complete before dismissing
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

                print("✅ GoalViewerView: Dismissing view")
                dismiss()
            } catch {
                print("❌ GoalViewerView: Delete failed with error: \(error.localizedDescription)")
                print("  Error details: \(error)")
            }
        }
    }

    private func markGoalComplete() {
        print("✅ GoalViewerView.markGoalComplete: Marking goal as complete")
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
                print("✅ GoalViewerView: Goal marked as complete successfully")

                // Dismiss after successful update
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                dismiss()
            } catch {
                print("❌ GoalViewerView: Failed to mark goal as complete - \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Goal Content View
struct GoalContentView: View {
    let entry: WeekEntry
    let userProfile: UserProfile
    @Binding var selectedPhotoIndex: Int?

    @State private var animateContent = false
    @State private var pulseAnimation = false

    var body: some View {
        VStack(spacing: 24) {
            GoalHeaderView(entry: entry, userProfile: userProfile, pulseAnimation: pulseAnimation)
                .scaleEffect(animateContent ? 1 : 0.9)
                .opacity(animateContent ? 1 : 0)

            if !entry.photoURLs.isEmpty {
                GoalPhotosView(
                    photoURLs: entry.photoURLs,
                    selectedPhotoIndex: $selectedPhotoIndex
                )
                .scaleEffect(animateContent ? 1 : 0.95)
                .opacity(animateContent ? 1 : 0)
            }

            if let locationName = entry.locationName,
               let latitude = entry.locationLatitude,
               let longitude = entry.locationLongitude {
                GoalLocationView(
                    locationName: locationName,
                    latitude: latitude,
                    longitude: longitude
                )
                .scaleEffect(animateContent ? 1 : 0.95)
                .opacity(animateContent ? 1 : 0)
            }

            if let description = entry.description, !description.isEmpty {
                GoalDescriptionCard(text: description)
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }

            if let textContent = entry.textContent, !textContent.isEmpty {
                GoalActionCard(text: textContent)
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }

            if !entry.tags.isEmpty {
                GoalTagsView(tags: entry.tags)
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }

            if entry.isFavorite {
                GoalFavoriteView()
                    .scaleEffect(animateContent ? 1 : 0.95)
                    .opacity(animateContent ? 1 : 0)
            }
        }
        .padding(.bottom, 40)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                animateContent = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulseAnimation = true
            }
        }
    }
}

// MARK: - Goal Background
struct GoalBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.15, blue: 0.25),
                    Color(red: 0.15, green: 0.2, blue: 0.35),
                    Color(red: 0.2, green: 0.25, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geometry in
                ForEach(0..<20, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 2, height: 2)
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Goal Header
struct GoalHeaderView: View {
    let entry: WeekEntry
    let userProfile: UserProfile
    let pulseAnimation: Bool

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppColors.accent.opacity(0.3),
                                AppColors.accent.opacity(0.0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.2 : 1.0)

                VStack(spacing: 8) {
                    Image(systemName: "target")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppColors.accent)
                    Text("GOAL")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(AppColors.accent)
                        .tracking(2)
                }
            }

            Text(entry.title)
                .font(.system(size: 32, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .shadow(color: AppColors.accent.opacity(0.5), radius: 10)

            if let actualDate = calculateActualDate() {
                Text(formatDate(actualDate))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.accent.opacity(0.8))
                    .italic()
            } else {
                Text("YOUR VISION FOR THE FUTURE")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.accent)
                    .tracking(3)
            }
        }
        .padding(.top, 20)
    }

    private func calculateActualDate() -> Date? {
        // Use centralized DateCalculator for consistent week→date conversion
        let dateCalculator = DateCalculator()
        return dateCalculator.weekCoordinatesToDate(
            weekYear: entry.weekYear,
            weekNumber: entry.weekNumber,
            dayOfWeek: entry.dayOfWeek ?? 1,
            userBirthDate: userProfile.dateOfBirth
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Goal Photos
struct GoalPhotosView: View {
    let photoURLs: [String]
    @Binding var selectedPhotoIndex: Int?

    var body: some View {
        VStack(spacing: 12) {
            Text("VISION BOARD")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(AppColors.accent)
                .tracking(2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Array(photoURLs.enumerated()), id: \.offset) { index, photoURL in
                    AsyncImage(url: URL(string: photoURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(AppColors.accent.opacity(0.5), lineWidth: 2)
                                )
                        default:
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 160, height: 160)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .onTapGesture {
                        selectedPhotoIndex = index
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Goal Description Card
struct GoalDescriptionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .lineSpacing(8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// MARK: - Goal Action Card
struct GoalActionCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Rectangle()
                    .fill(AppColors.accent)
                    .frame(width: 4, height: 24)
                Text("ACTION PLAN")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.white)
                    .tracking(1)
            }

            Text(text)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
                .lineSpacing(8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal)
    }
}

// MARK: - Goal Tags
struct GoalTagsView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MILESTONES")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .tracking(1)

            FlowLayout(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag.uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(AppColors.accent.opacity(0.3))
                        )
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Goal Favorite
struct GoalFavoriteView: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "star.fill")
                .foregroundColor(AppColors.accent)
            Text("PRIORITY GOAL")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)
                .tracking(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(AppColors.accent.opacity(0.2))
        )
    }
}

// MARK: - Goal Quote
struct GoalQuoteView: View {
    var body: some View {
        Text("\"The future belongs to those who believe in the beauty of their dreams.\"")
            .font(.system(size: 14, weight: .medium, design: .serif))
            .foregroundColor(.white.opacity(0.7))
            .italic()
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
    }
}

// MARK: - Memory Location View
struct MemoryLocationView: View {
    let locationName: String
    let latitude: Double
    let longitude: Double

    @State private var region: MKCoordinateRegion

    init(locationName: String, latitude: Double, longitude: Double) {
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude

        // Initialize the region centered on the location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location header
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(Color(red: 0.7, green: 0.5, blue: 0.4))
                    .font(.system(size: 18))

                Text("Location")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }
            .padding(.horizontal, 20)

            // Map view
            Map(coordinateRegion: .constant(region), annotationItems: [MapLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))]) { location in
                MapMarker(coordinate: location.coordinate, tint: Color(red: 0.7, green: 0.5, blue: 0.4))
            }
            .frame(height: 200)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(red: 0.9, green: 0.8, blue: 0.7), lineWidth: 2)
            )

            // Location name and coordinates
            VStack(alignment: .leading, spacing: 4) {
                Text(locationName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(red: 0.3, green: 0.2, blue: 0.1))

                Text("Lat: \(latitude, specifier: "%.4f"), Long: \(longitude, specifier: "%.4f")")
                    .font(.system(size: 12))
                    .foregroundColor(Color(red: 0.5, green: 0.4, blue: 0.3))
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.7))
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
        )
        .padding(.horizontal)
    }
}

// Helper struct for map annotations
private struct MapLocation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}

// MARK: - Goal Location View
struct GoalLocationView: View {
    let locationName: String
    let latitude: Double
    let longitude: Double

    @State private var region: MKCoordinateRegion

    init(locationName: String, latitude: Double, longitude: Double) {
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude

        // Initialize the region centered on the location
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Location header
            HStack(spacing: 8) {
                Image(systemName: "mappin.circle.fill")
                    .foregroundColor(AppColors.accent)
                    .font(.system(size: 18))

                Text("Location")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(1)
            }
            .padding(.horizontal, 20)

            // Map view
            Map(coordinateRegion: .constant(region), annotationItems: [MapLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude))]) { location in
                MapMarker(coordinate: location.coordinate, tint: AppColors.accent)
            }
            .frame(height: 200)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.accent.opacity(0.5), lineWidth: 2)
            )

            // Location name and coordinates
            VStack(alignment: .leading, spacing: 4) {
                Text(locationName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Text("Lat: \(latitude, specifier: "%.4f"), Long: \(longitude, specifier: "%.4f")")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppColors.accent.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal)
    }
}
