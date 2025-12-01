//
//  EntryEditorView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI
import PhotosUI

struct EntryEditorView: View {
    @EnvironmentObject var memoryViewModel: MemoryViewModel
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) var dismiss

    let week: WeekData
    let userProfile: UserProfile
    let existingEntry: WeekEntry?
    let isPast: Bool

    // Use centralized date calculator for consistent calculations
    private let dateCalculator = DateCalculator()

    // Form state
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var textContent: String = ""
    @State private var selectedDay: Int? = nil
    @State private var tags: String = ""
    @State private var isFavorite: Bool = false

    // Location state
    @State private var locationName: String? = nil
    @State private var locationLatitude: Double? = nil
    @State private var locationLongitude: Double? = nil
    @State private var showLocationPicker = false

    // Recurring reminder state
    @State private var isRecurring: Bool = false
    @State private var recurringFrequency: RecurringFrequency? = nil
    @State private var recurringEndDate: Date? = nil
    @State private var notificationLeadTime: Int? = nil
    @State private var notificationLeadTimeUnit: LeadTimeUnit? = nil

    // Photo picker
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoURLs: [String] = []
    @State private var uploadingPhotos: [UIImage] = []
    @State private var photoUploadProgress: [String: Double] = [:]

    // Audio
    @State private var audioURL: String? = nil
    @State private var recordedAudioURL: URL? = nil
    @State private var isRecordingAudio = false

    // UI state
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showDeletePhotoAlert = false
    @State private var photoToDelete: String?

    // Haptics
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    let notificationFeedback = UINotificationFeedbackGenerator()

    var isEditing: Bool {
        existingEntry != nil
    }

    var entryType: EntryType {
        isPast ? .memory : .goal
    }

    var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(week: WeekData, userProfile: UserProfile, existingEntry: WeekEntry? = nil, isPast: Bool, selectedDate: Date? = nil) {
        self.week = week
        self.userProfile = userProfile
        self.existingEntry = existingEntry
        self.isPast = isPast

        // Initialize state from existing entry
        if let entry = existingEntry {
            _title = State(initialValue: entry.title)
            _description = State(initialValue: entry.description ?? "")
            _textContent = State(initialValue: entry.textContent ?? "")
            _selectedDay = State(initialValue: entry.dayOfWeek)
            _tags = State(initialValue: entry.tags.joined(separator: ", "))
            _isFavorite = State(initialValue: entry.isFavorite)
            _photoURLs = State(initialValue: entry.photoURLs)
            _audioURL = State(initialValue: entry.audioURL)
            _locationName = State(initialValue: entry.locationName)
            _locationLatitude = State(initialValue: entry.locationLatitude)
            _locationLongitude = State(initialValue: entry.locationLongitude)
            _isRecurring = State(initialValue: entry.isRecurring)
            _recurringFrequency = State(initialValue: entry.recurringFrequency)
            _recurringEndDate = State(initialValue: entry.recurringEndDate)
            _notificationLeadTime = State(initialValue: entry.notificationLeadTime)
            _notificationLeadTimeUnit = State(initialValue: entry.notificationLeadTimeUnit)
        } else if let date = selectedDate {
            // Use centralized DateCalculator for consistent date→week conversion
            let calculator = DateCalculator()
            let coordinates = calculator.dateToWeekCoordinates(date: date, userBirthDate: userProfile.dateOfBirth)
            _selectedDay = State(initialValue: coordinates.dayOfWeek)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    formContent
                        .padding(Constants.Layout.paddingLarge)
                }

                // Save button overlay
                if isSaving {
                    savingOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                Task {
                    await loadSelectedPhotos(newValue)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Delete Photo", isPresented: $showDeletePhotoAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let url = photoToDelete {
                        deletePhoto(url)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this photo?")
            }
            .sheet(isPresented: $isRecordingAudio) {
                AudioRecorderView(recordedAudioURL: $recordedAudioURL)
            }
            .sheet(isPresented: $showLocationPicker) {
                LocationPickerView(
                    locationName: $locationName,
                    locationLatitude: $locationLatitude,
                    locationLongitude: $locationLongitude
                )
            }
        }
    }

    @ViewBuilder
    private var formContent: some View {
        VStack(spacing: 24) {
                        // Entry Type Badge
                        HStack {
                            Label(entryType.displayName, systemImage: entryType.icon)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(entryType == .memory ? AppColors.personalColor : AppColors.accent)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill((entryType == .memory ? AppColors.personalColor : AppColors.accent).opacity(0.1))
                                )

                            Spacer()

                            Text("Week \(week.week + 1), Year \(week.year)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }

                        // Title
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title *")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            TextField("What happened?", text: $title)
                                .textFieldStyle(CustomTextFieldStyle())
                                .submitLabel(.next)
                        }

                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            TextField("Brief summary (optional)", text: $description, axis: .vertical)
                                .textFieldStyle(CustomTextFieldStyle())
                                .lineLimit(2...4)
                        }

                        // Selected Date Display
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            SelectedDateDisplay(selectedDay: $selectedDay, week: week, userProfile: userProfile)
                        }

                        // Location Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Location")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            Button(action: {
                                showLocationPicker = true
                            }) {
                                HStack {
                                    Image(systemName: locationName != nil ? "mappin.circle.fill" : "mappin.and.ellipse")
                                        .foregroundColor(locationName != nil ? AppColors.primary : AppColors.textSecondary)

                                    if let name = locationName {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(name)
                                                .font(.system(size: 15))
                                                .foregroundColor(AppColors.textPrimary)

                                            if let lat = locationLatitude, let long = locationLongitude {
                                                Text("Lat: \(lat, specifier: "%.4f"), Long: \(long, specifier: "%.4f")")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppColors.textSecondary)
                                            }
                                        }
                                    } else {
                                        Text("Add location")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(AppColors.textSecondary)
                                }
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }

                            if locationName != nil {
                                Button(action: {
                                    locationName = nil
                                    locationLatitude = nil
                                    locationLongitude = nil
                                }) {
                                    Text("Remove Location")
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                            }
                        }

                        // Photos Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Photos")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)

                                Spacer()

                                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 10, matching: .images) {
                                    Label("Add Photos", systemImage: "photo.badge.plus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                }
                            }

                            // Existing photos
                            if !photoURLs.isEmpty || !uploadingPhotos.isEmpty {
                                PhotoGridView(
                                    photoURLs: photoURLs,
                                    uploadingPhotos: uploadingPhotos,
                                    uploadProgress: photoUploadProgress,
                                    onDelete: { url in
                                        photoToDelete = url
                                        showDeletePhotoAlert = true
                                    }
                                )
                            }
                        }

                        // Audio Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Audio Recording")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            if let audioURL = audioURL {
                                AudioPlayerView(audioURL: audioURL)
                            } else if let recordedURL = recordedAudioURL {
                                HStack {
                                    Image(systemName: "waveform")
                                        .foregroundColor(AppColors.accent)
                                    Text("Recording ready to upload")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.textSecondary)
                                    Spacer()
                                    Button(action: { recordedAudioURL = nil }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(AppColors.textSecondary)
                                    }
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                )
                            } else {
                                Button(action: { isRecordingAudio = true }) {
                                    Label("Record Audio", systemImage: "mic.fill")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.primary.opacity(0.1))
                                        )
                                }
                            }
                        }

                        // Tags
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.textSecondary)

                            TextField("Separate tags with commas", text: $tags)
                                .textFieldStyle(CustomTextFieldStyle())
                        }

                        // Favorite Toggle
                        Toggle(isOn: $isFavorite) {
                            HStack {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .foregroundColor(isFavorite ? AppColors.accent : AppColors.textSecondary)
                                Text("Mark as Favorite")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )

                        // Recurring Reminder Section (only for past entries/memories)
                        if isPast {
                            RecurringReminderView(
                                isRecurring: $isRecurring,
                                frequency: $recurringFrequency,
                                endDate: $recurringEndDate,
                                leadTime: $notificationLeadTime,
                                leadTimeUnit: $notificationLeadTimeUnit
                            )
                        }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") {
                dismiss()
            }
            .foregroundColor(AppColors.primary)
            .disabled(isSaving)
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: saveEntry) {
                Text("Save")
                    .fontWeight(.semibold)
            }
            .foregroundColor(canSave ? AppColors.primary : AppColors.textSecondary)
            .disabled(!canSave || isSaving)
        }
    }

    @ViewBuilder
    private var savingOverlay: some View {
        Color.black.opacity(0.3)
            .ignoresSafeArea()

        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            if memoryViewModel.uploadProgress > 0 && memoryViewModel.uploadProgress < 1 {
                Text("Uploading media... \(Int(memoryViewModel.uploadProgress * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            } else {
                Text("Saving...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.8))
        )
    }

    // MARK: - Photo Loading
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                uploadingPhotos.append(image)
                await uploadPhoto(image)
            }
        }
        selectedPhotos = []
    }

    private func uploadPhoto(_ image: UIImage) async {
        print("📸 EntryEditorView.uploadPhoto: Starting photo upload")

        guard let userId = authService.currentUser?.id else {
            print("❌ EntryEditorView.uploadPhoto: No userId available")
            errorMessage = "Please sign in to upload photos"
            showError = true
            return
        }

        print("  userId: \(userId)")

        let photoId = UUID().uuidString
        photoUploadProgress[photoId] = 0

        do {
            print("  Calling memoryViewModel.uploadPhoto...")
            let url = try await memoryViewModel.uploadPhoto(image, userId: userId)
            print("✅ EntryEditorView.uploadPhoto: Photo uploaded successfully")
            print("  URL: \(url)")

            photoURLs.append(url)
            print("  Added to photoURLs array. Total photos: \(photoURLs.count)")

            if let index = uploadingPhotos.firstIndex(where: { $0 === image }) {
                uploadingPhotos.remove(at: index)
            }
            photoUploadProgress.removeValue(forKey: photoId)

            impactFeedback.impactOccurred()
        } catch {
            print("❌ EntryEditorView.uploadPhoto: Upload failed")
            print("  Error: \(error.localizedDescription)")
            print("  Error details: \(error)")

            errorMessage = "Failed to upload photo: \(error.localizedDescription)"
            showError = true

            if let index = uploadingPhotos.firstIndex(where: { $0 === image }) {
                uploadingPhotos.remove(at: index)
            }
            photoUploadProgress.removeValue(forKey: photoId)
        }
    }

    private func deletePhoto(_ url: String) {
        photoURLs.removeAll { $0 == url }
        impactFeedback.impactOccurred()
    }

    // MARK: - Save Entry
    private func saveEntry() {
        guard canSave else { return }
        guard let userId = authService.currentUser?.id else {
            errorMessage = "You must be signed in to save entries"
            showError = true
            return
        }

        isSaving = true
        impactFeedback.impactOccurred()

        Task {
            do {
                // Upload recorded audio if any
                var finalAudioURL = audioURL
                if let recordedURL = recordedAudioURL {
                    finalAudioURL = try await memoryViewModel.uploadAudio(recordedURL, userId: userId)
                }

                // Parse tags
                let tagArray = tags
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }

                // Create or update entry
                let entry = WeekEntry(
                    id: existingEntry?.id ?? UUID(),
                    userId: userId,
                    weekYear: week.year,
                    weekNumber: week.week,
                    entryType: entryType,
                    dayOfWeek: selectedDay,
                    title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                    description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
                    textContent: textContent.isEmpty ? nil : textContent.trimmingCharacters(in: .whitespacesAndNewlines),
                    photoURLs: photoURLs,
                    audioURL: finalAudioURL,
                    locationName: locationName,
                    locationLatitude: locationLatitude,
                    locationLongitude: locationLongitude,
                    createdAt: existingEntry?.createdAt ?? Date(),
                    updatedAt: Date(),
                    tags: tagArray,
                    isFavorite: isFavorite,
                    isRecurring: isRecurring,
                    recurringFrequency: recurringFrequency,
                    recurringEndDate: recurringEndDate,
                    notificationLeadTime: notificationLeadTime,
                    notificationLeadTimeUnit: notificationLeadTimeUnit
                )

                print("💾 EntryEditor: About to save - week=\(week.week), year=\(week.year), type=\(entryType.rawValue), title=\(entry.title)")
                print("  isRecurring: \(isRecurring)")

                if isEditing {
                    print("  Updating existing entry")
                    try await memoryViewModel.updateEntry(entry)
                } else {
                    print("  Creating new entry")
                    try await memoryViewModel.createEntry(entry)
                }

                // Generate recurring goal entries if this is a memory with recurring reminders
                if isRecurring && isPast && !isEditing,
                   let frequency = recurringFrequency,
                   let endDate = recurringEndDate,
                   let leadTime = notificationLeadTime,
                   let leadTimeUnit = notificationLeadTimeUnit {
                    print("🔄 EntryEditor: Generating recurring goal entries")
                    try await generateRecurringGoals(
                        fromMemory: entry,
                        userId: userId,
                        frequency: frequency,
                        endDate: endDate,
                        leadTime: leadTime,
                        leadTimeUnit: leadTimeUnit
                    )
                }

                print("✅ EntryEditor: Save completed successfully")
                notificationFeedback.notificationOccurred(.success)
                isSaving = false
                dismiss()

            } catch {
                isSaving = false
                errorMessage = "Failed to save: \(error.localizedDescription)"
                showError = true
                notificationFeedback.notificationOccurred(.error)
            }
        }
    }

    // MARK: - Recurring Goals Generation
    private func generateRecurringGoals(
        fromMemory memory: WeekEntry,
        userId: String,
        frequency: RecurringFrequency,
        endDate: Date,
        leadTime: Int,
        leadTimeUnit: LeadTimeUnit
    ) async throws {
        print("🔄 generateRecurringGoals: Starting generation")
        print("  Frequency: \(frequency.displayName)")
        print("  End date: \(endDate)")
        print("  Lead time: \(leadTime) \(leadTimeUnit.rawValue)")

        let calendar = Calendar.current

        // Use centralized DateCalculator for consistent week→date conversion
        // Reconstruct the actual memory date from week coordinates
        guard let memoryDate = dateCalculator.weekCoordinatesToDate(
            weekYear: memory.weekYear,
            weekNumber: memory.weekNumber,
            dayOfWeek: memory.dayOfWeek ?? 1,
            userBirthDate: userProfile.dateOfBirth
        ) else {
            print("❌ Failed to reconstruct memory date from week coordinates")
            return
        }

        // Extract the month and day to use for future years
        let memoryMonth = calendar.component(.month, from: memoryDate)
        let memoryDay = calendar.component(.day, from: memoryDate)

        print("  Memory week year: \(memory.weekYear), week number: \(memory.weekNumber), day: \(memory.dayOfWeek ?? 0)")
        print("  Reconstructed memory date: \(memoryDate)")
        print("  Memory month/day: \(memoryMonth)/\(memoryDay)")

        let now = Date()
        var currentDate = memoryDate
        var goalsCreated = 0

        // Generate goals based on frequency until end date
        while true {
            // Calculate next occurrence
            // For yearly frequency, use exact month/day to avoid drift
            let nextDate: Date
            if frequency == .yearly {
                // Use the exact month/day from the original memory
                let nextYear = calendar.component(.year, from: currentDate) + 1
                guard let exactDate = calendar.date(from: DateComponents(year: nextYear, month: memoryMonth, day: memoryDay)) else {
                    break
                }
                nextDate = exactDate
            } else {
                // For other frequencies, use interval addition
                guard let calculatedDate = calendar.date(byAdding: frequency.interval, to: currentDate) else {
                    break
                }
                nextDate = calculatedDate
            }

            // Stop if we've passed the end date
            if nextDate > endDate {
                break
            }

            // Skip if the date is in the past (only create future goals)
            if nextDate < now {
                currentDate = nextDate
                continue
            }

            // Use centralized DateCalculator for consistent date→week conversion
            let goalCoordinates = dateCalculator.dateToWeekCoordinates(date: nextDate, userBirthDate: userProfile.dateOfBirth)

            // Skip if the age is beyond our calendar (90 years)
            if goalCoordinates.weekYear >= 90 {
                break
            }

            print("  📅 Goal calculation for nextDate: \(nextDate)")
            print("    Calculated weekYear (age): \(goalCoordinates.weekYear)")
            print("    Calculated weekNumber: \(goalCoordinates.weekNumber)")
            print("    Calculated dayOfWeek: \(goalCoordinates.dayOfWeek)")
            print("    Using month/day: \(memoryMonth)/\(memoryDay)")

            // Calculate notification date (lead time before the goal date)
            let notificationDate: Date?
            switch leadTimeUnit {
            case .days:
                notificationDate = calendar.date(byAdding: .day, value: -leadTime, to: nextDate)
            case .weeks:
                notificationDate = calendar.date(byAdding: .weekOfYear, value: -leadTime, to: nextDate)
            case .months:
                notificationDate = calendar.date(byAdding: .month, value: -leadTime, to: nextDate)
            }

            // Create goal entry using consistent week coordinates from DateCalculator
            let goalEntry = WeekEntry(
                id: UUID(),
                userId: userId,
                weekYear: goalCoordinates.weekYear,
                weekNumber: goalCoordinates.weekNumber,
                entryType: .goal,
                dayOfWeek: goalCoordinates.dayOfWeek,
                title: memory.title,
                description: memory.description,
                textContent: memory.textContent,
                photoURLs: memory.photoURLs,
                audioURL: memory.audioURL,
                createdAt: Date(),
                updatedAt: Date(),
                tags: memory.tags,
                isFavorite: false,
                reminderDate: notificationDate,
                reminderEnabled: notificationDate != nil,
                notificationId: nil,
                parentMemoryId: memory.id
            )

            print("  Creating goal for: \(nextDate), age: \(goalCoordinates.weekYear), week: \(goalCoordinates.weekNumber)")

            try await memoryViewModel.createEntry(goalEntry)
            goalsCreated += 1

            currentDate = nextDate
        }

        print("✅ generateRecurringGoals: Created \(goalsCreated) goal entries")
    }
}

// MARK: - Selected Date Display
struct SelectedDateDisplay: View {
    @Binding var selectedDay: Int?
    let week: WeekData
    let userProfile: UserProfile

    // Use centralized date calculator for consistent calculations
    private let dateCalculator = DateCalculator()

    // Calculate the selected date for this week using centralized DateCalculator
    private var selectedDate: Date? {
        let dayOfWeek = selectedDay ?? 1  // If no day selected, use position 1
        return dateCalculator.weekCoordinatesToDate(
            weekYear: week.year,
            weekNumber: week.week,
            dayOfWeek: dayOfWeek,
            userBirthDate: userProfile.dateOfBirth
        )
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 20))
                .foregroundColor(AppColors.primary)

            if let date = selectedDate {
                Text(formatDate(date))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
            } else {
                Text("No date available")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
}

// MARK: - Photo Grid
struct PhotoGridView: View {
    let photoURLs: [String]
    let uploadingPhotos: [UIImage]
    let uploadProgress: [String: Double]
    let onDelete: (String) -> Void

    let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Uploading photos
            ForEach(uploadingPhotos.indices, id: \.self) { index in
                Image(uiImage: uploadingPhotos[index])
                    .resizable()
                    .scaledToFill()
                    .frame(width: 100, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        ZStack {
                            Color.black.opacity(0.5)
                            ProgressView()
                                .tint(.white)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    )
            }

            // Uploaded photos
            ForEach(photoURLs, id: \.self) { url in
                AsyncImage(url: URL(string: url)) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(alignment: .topTrailing) {
                                Button(action: { onDelete(url) }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.5))
                                                .frame(width: 24, height: 24)
                                        )
                                        .padding(4)
                                }
                            }

                    case .failure:
                        ZStack {
                            Color.gray.opacity(0.2)
                            Image(systemName: "photo.fill")
                                .foregroundColor(.gray)
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
            )
            .font(.system(size: 16))
            .foregroundColor(AppColors.textPrimary)
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

    return EntryEditorView(
        week: sampleWeek,
        userProfile: sampleProfile,
        existingEntry: nil,
        isPast: true
    )
    .environmentObject(MemoryViewModel())
    .environmentObject(AuthenticationService.shared)
}
