//
//  OnboardingViewModel.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class OnboardingViewModel: ObservableObject {
    // Memory creation for special dates
    private let memoryViewModel = MemoryViewModel()
    private let dateCalculator = DateCalculator()
    @Published var userProfile = UserProfile()
    @Published var currentStep: Constants.OnboardingStep = .welcome
    @Published var isLoading = false
    @Published var showDashboard = false

    // Validation states
    @Published var nameError: String?
    @Published var dobError: String?
    @Published var educationError: String?
    @Published var workError: String?
    @Published var familyError: String?

    // Temporary input values - Basic
    @Published var nameInput: String = ""
    @Published var selectedDate: Date = Date()

    // Education inputs
    @Published var selectedDegree: String = ""
    @Published var schoolNameInput: String = ""
    @Published var graduationYear: Int = Calendar.current.component(.year, from: Date())

    // Work inputs (combined)
    @Published var selectedIndustry: String = ""
    @Published var jobRoleInput: String = ""
    @Published var yearsWorkedValue: Double = 0

    // Family inputs
    @Published var selectedRelationshipStatus: RelationshipStatus = .single
    @Published var isMarried: Bool = false
    @Published var spouseNameInput: String = ""
    @Published var spouseDateOfBirth: Date = Date()
    @Published var marriageDate: Date = Date()
    @Published var children: [Child] = []
    @Published var pets: [Pet] = []

    // MARK: - Navigation
    func moveToNextStep() {
        // Validate current step before moving
        guard validateCurrentStep() else { return }

        // Save current step data
        saveCurrentStepData()

        // Move to next step
        if let nextStep = Constants.OnboardingStep(rawValue: currentStep.rawValue + 1) {
            withAnimation(Constants.Animation.smooth) {
                currentStep = nextStep
                Constants.Haptics.light.impactOccurred()
            }
        } else {
            // Finished onboarding
            completeOnboarding()
        }
    }

    func moveToPreviousStep() {
        if currentStep == .welcome { return }

        if let previousStep = Constants.OnboardingStep(rawValue: currentStep.rawValue - 1) {
            withAnimation(Constants.Animation.smooth) {
                currentStep = previousStep
                Constants.Haptics.light.impactOccurred()
            }
        }
    }

    func skipToStep(_ step: Constants.OnboardingStep) {
        withAnimation(Constants.Animation.smooth) {
            currentStep = step
        }
    }

    // MARK: - Validation
    private func validateCurrentStep() -> Bool {
        switch currentStep {
        case .welcome:
            return true

        case .name:
            if nameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                nameError = "Please enter your name"
                return false
            }
            nameError = nil
            return true

        case .dateOfBirth:
            let age = Calendar.current.dateComponents([.year], from: selectedDate, to: Date()).year ?? 0
            if age < 16 {
                dobError = "You must be at least 16 years old"
                return false
            }
            if age > 100 {
                dobError = "Please enter a valid date of birth"
                return false
            }
            dobError = nil
            return true

        case .education:
            // Education is optional, so just return true
            educationError = nil
            return true

        case .work:
            if selectedIndustry.isEmpty {
                workError = "Please select an industry"
                return false
            }
            if jobRoleInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                workError = "Please enter your job role"
                return false
            }
            workError = nil
            return true

        case .family:
            // Validate spouse name if married
            if isMarried && spouseNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                familyError = "Please enter your spouse's name"
                return false
            }
            // Validate children names
            for child in children {
                if child.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    familyError = "Please enter names for all children"
                    return false
                }
            }
            // Validate pet names
            for pet in pets {
                if pet.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    familyError = "Please enter names for all pets"
                    return false
                }
            }
            familyError = nil
            return true
        }
    }

    // MARK: - Save Data
    private func saveCurrentStepData() {
        switch currentStep {
        case .name:
            userProfile.name = nameInput.trimmingCharacters(in: .whitespacesAndNewlines)

        case .dateOfBirth:
            userProfile.dateOfBirth = selectedDate

        case .education:
            userProfile.degree = selectedDegree
            userProfile.schoolName = schoolNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
            userProfile.graduationYear = graduationYear

        case .work:
            userProfile.industry = selectedIndustry
            userProfile.jobRole = jobRoleInput.trimmingCharacters(in: .whitespacesAndNewlines)
            userProfile.yearsWorked = yearsWorkedValue

        case .family:
            userProfile.relationshipStatus = isMarried ? .married : selectedRelationshipStatus
            if isMarried {
                userProfile.spouseName = spouseNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                userProfile.spouseDateOfBirth = spouseDateOfBirth
                userProfile.marriageDate = marriageDate
            } else {
                userProfile.spouseName = ""
                userProfile.spouseDateOfBirth = nil
                userProfile.marriageDate = nil
            }
            userProfile.children = children
            userProfile.pets = pets

        default:
            break
        }
    }

    // MARK: - Children Management
    func addChild() {
        let newChild = Child()
        children.append(newChild)
        Constants.Haptics.light.impactOccurred()
    }

    func removeChild(at index: Int) {
        guard index >= 0 && index < children.count else { return }
        children.remove(at: index)
        Constants.Haptics.light.impactOccurred()
    }

    func updateChild(at index: Int, name: String? = nil, dateOfBirth: Date? = nil) {
        guard index >= 0 && index < children.count else { return }
        if let name = name {
            children[index].name = name
        }
        if let dob = dateOfBirth {
            children[index].dateOfBirth = dob
        }
    }

    // MARK: - Pets Management
    func addPet() {
        let newPet = Pet()
        pets.append(newPet)
        Constants.Haptics.light.impactOccurred()
    }

    func removePet(at index: Int) {
        guard index >= 0 && index < pets.count else { return }
        pets.remove(at: index)
        Constants.Haptics.light.impactOccurred()
    }

    func updatePet(at index: Int, name: String? = nil, type: PetType? = nil, birthday: Date? = nil) {
        guard index >= 0 && index < pets.count else { return }
        if let name = name {
            pets[index].name = name
        }
        if let type = type {
            pets[index].type = type
        }
        if let birthday = birthday {
            pets[index].birthday = birthday
        }
    }

    // MARK: - Complete Onboarding
    private func completeOnboarding() {
        isLoading = true

        Task {
            do {
                // Save profile to Firestore if user is authenticated
                if let userId = userProfile.userId, !userProfile.isAnonymous {
                    print("💾 OnboardingViewModel: Saving profile to Firestore for user: \(userId)")
                    try await UserProfileService.shared.saveProfile(userProfile)
                    print("✅ OnboardingViewModel: Profile saved successfully")

                    // Create automatic memories for special dates
                    await createAutomaticMemories(for: userId)
                } else {
                    print("💾 OnboardingViewModel: User is guest, skipping Firestore save")
                }

                // Small delay for better UX
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

                withAnimation(Constants.Animation.smooth) {
                    isLoading = false
                    showDashboard = true
                }

                Constants.Haptics.notification.notificationOccurred(.success)
            } catch {
                print("❌ OnboardingViewModel: Failed to save profile: \(error.localizedDescription)")
                // Continue to dashboard even if save fails
                withAnimation(Constants.Animation.smooth) {
                    isLoading = false
                    showDashboard = true
                }
            }
        }
    }

    // MARK: - Automatic Memory Creation
    private func createAutomaticMemories(for userId: String) async {
        print("🎂 OnboardingViewModel: Creating automatic memories for special dates")
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())

        // 1. Create birthday memories for each year up to current age
        await createBirthdayMemories(userId: userId, currentYear: currentYear)

        // 2. Create wedding anniversary memory (if married)
        await createAnniversaryMemory(userId: userId, currentYear: currentYear)

        // 3. Create spouse birthday memories (if has spouse)
        await createSpouseBirthdayMemories(userId: userId, currentYear: currentYear)

        // 4. Create children birthday memories
        await createChildrenBirthdayMemories(userId: userId, currentYear: currentYear)

        // 5. Create pet birthday memories
        await createPetBirthdayMemories(userId: userId, currentYear: currentYear)

        // 6. Create graduation memory
        await createGraduationMemory(userId: userId)

        print("✅ OnboardingViewModel: Finished creating automatic memories")
    }

    private func createBirthdayMemories(userId: String, currentYear: Int) async {
        let calendar = Calendar.current
        let birthYear = calendar.component(.year, from: userProfile.dateOfBirth)
        let birthMonth = calendar.component(.month, from: userProfile.dateOfBirth)
        let birthDay = calendar.component(.day, from: userProfile.dateOfBirth)

        // Create a memory for each birthday from birth to current age
        for year in birthYear...currentYear {
            // Create the date for this birthday
            guard let birthdayDate = calendar.date(from: DateComponents(year: year, month: birthMonth, day: birthDay)) else {
                continue
            }

            // Skip if birthday is in the future
            if birthdayDate > Date() {
                continue
            }

            let age = year - birthYear
            let coordinates = dateCalculator.dateToWeekCoordinates(date: birthdayDate, userBirthDate: userProfile.dateOfBirth)

            let entry = WeekEntry(
                userId: userId,
                weekYear: coordinates.weekYear,
                weekNumber: coordinates.weekNumber,
                entryType: .memory,
                dayOfWeek: coordinates.dayOfWeek,
                title: age == 0 ? "The Day I Was Born" : "My \(age)\(ordinalSuffix(for: age)) Birthday",
                description: age == 0 ? "The beginning of my life journey" : "Celebrating \(age) years of life",
                tags: ["birthday", "milestone", "special-date"]
            )

            do {
                try await memoryViewModel.createEntry(entry)
                print("  ✅ Created birthday memory for age \(age)")
            } catch {
                print("  ❌ Failed to create birthday memory for age \(age): \(error.localizedDescription)")
            }
        }
    }

    private func createAnniversaryMemory(userId: String, currentYear: Int) async {
        guard let marriageDate = userProfile.marriageDate else { return }

        let calendar = Calendar.current
        let marriageYear = calendar.component(.year, from: marriageDate)
        let marriageMonth = calendar.component(.month, from: marriageDate)
        let marriageDay = calendar.component(.day, from: marriageDate)

        // Create memories for each anniversary from wedding year to now
        for year in marriageYear...currentYear {
            guard let anniversaryDate = calendar.date(from: DateComponents(year: year, month: marriageMonth, day: marriageDay)) else {
                continue
            }

            // Skip if anniversary is in the future
            if anniversaryDate > Date() {
                continue
            }

            let yearsMarried = year - marriageYear
            let coordinates = dateCalculator.dateToWeekCoordinates(date: anniversaryDate, userBirthDate: userProfile.dateOfBirth)

            let title: String
            let description: String

            if yearsMarried == 0 {
                title = "Our Wedding Day"
                description = "The day we started our journey together"
            } else {
                title = "Our \(yearsMarried)\(ordinalSuffix(for: yearsMarried)) Wedding Anniversary"
                description = "Celebrating \(yearsMarried) years of marriage"
            }

            let entry = WeekEntry(
                userId: userId,
                weekYear: coordinates.weekYear,
                weekNumber: coordinates.weekNumber,
                entryType: .memory,
                dayOfWeek: coordinates.dayOfWeek,
                title: title,
                description: description,
                tags: ["anniversary", "marriage", "special-date"]
            )

            do {
                try await memoryViewModel.createEntry(entry)
                print("  ✅ Created anniversary memory for year \(yearsMarried)")
            } catch {
                print("  ❌ Failed to create anniversary memory: \(error.localizedDescription)")
            }
        }
    }

    private func createSpouseBirthdayMemories(userId: String, currentYear: Int) async {
        guard let spouseBirthday = userProfile.spouseDateOfBirth,
              !userProfile.spouseName.isEmpty else { return }

        let calendar = Calendar.current
        let spouseBirthYear = calendar.component(.year, from: spouseBirthday)
        let spouseMonth = calendar.component(.month, from: spouseBirthday)
        let spouseDay = calendar.component(.day, from: spouseBirthday)

        // Create memories starting from when user could remember (say age 5 or spouse birth, whichever is later)
        let userBirthYear = calendar.component(.year, from: userProfile.dateOfBirth)
        let startYear = max(spouseBirthYear, userBirthYear + 5)

        for year in startYear...currentYear {
            guard let birthdayDate = calendar.date(from: DateComponents(year: year, month: spouseMonth, day: spouseDay)) else {
                continue
            }

            // Skip if birthday is in the future
            if birthdayDate > Date() {
                continue
            }

            let spouseAge = year - spouseBirthYear
            let coordinates = dateCalculator.dateToWeekCoordinates(date: birthdayDate, userBirthDate: userProfile.dateOfBirth)

            let entry = WeekEntry(
                userId: userId,
                weekYear: coordinates.weekYear,
                weekNumber: coordinates.weekNumber,
                entryType: .memory,
                dayOfWeek: coordinates.dayOfWeek,
                title: "\(userProfile.spouseName)'s \(spouseAge)\(ordinalSuffix(for: spouseAge)) Birthday",
                description: "Celebrating \(userProfile.spouseName)'s birthday",
                tags: ["birthday", "spouse", "special-date"]
            )

            do {
                try await memoryViewModel.createEntry(entry)
                print("  ✅ Created spouse birthday memory for \(userProfile.spouseName) age \(spouseAge)")
            } catch {
                print("  ❌ Failed to create spouse birthday memory: \(error.localizedDescription)")
            }
        }
    }

    private func createChildrenBirthdayMemories(userId: String, currentYear: Int) async {
        let calendar = Calendar.current

        for child in userProfile.children {
            guard !child.name.isEmpty else { continue }

            let childBirthYear = calendar.component(.year, from: child.dateOfBirth)
            let childMonth = calendar.component(.month, from: child.dateOfBirth)
            let childDay = calendar.component(.day, from: child.dateOfBirth)

            // Create memories from child's birth year to now
            for year in childBirthYear...currentYear {
                guard let birthdayDate = calendar.date(from: DateComponents(year: year, month: childMonth, day: childDay)) else {
                    continue
                }

                // Skip if birthday is in the future
                if birthdayDate > Date() {
                    continue
                }

                let childAge = year - childBirthYear
                let coordinates = dateCalculator.dateToWeekCoordinates(date: birthdayDate, userBirthDate: userProfile.dateOfBirth)

                let title: String
                let description: String

                if childAge == 0 {
                    title = "\(child.name) Was Born"
                    description = "Welcome to the world, \(child.name)!"
                } else {
                    title = "\(child.name)'s \(childAge)\(ordinalSuffix(for: childAge)) Birthday"
                    description = "Celebrating \(child.name)'s \(childAge)\(ordinalSuffix(for: childAge)) birthday"
                }

                let entry = WeekEntry(
                    userId: userId,
                    weekYear: coordinates.weekYear,
                    weekNumber: coordinates.weekNumber,
                    entryType: .memory,
                    dayOfWeek: coordinates.dayOfWeek,
                    title: title,
                    description: description,
                    tags: ["birthday", "child", "family", "special-date"]
                )

                do {
                    try await memoryViewModel.createEntry(entry)
                    print("  ✅ Created birthday memory for \(child.name) age \(childAge)")
                } catch {
                    print("  ❌ Failed to create child birthday memory: \(error.localizedDescription)")
                }
            }
        }
    }

    private func createPetBirthdayMemories(userId: String, currentYear: Int) async {
        let calendar = Calendar.current

        for pet in userProfile.pets {
            guard !pet.name.isEmpty, let petBirthday = pet.birthday else { continue }

            let petBirthYear = calendar.component(.year, from: petBirthday)
            let petMonth = calendar.component(.month, from: petBirthday)
            let petDay = calendar.component(.day, from: petBirthday)

            // Create memories from pet's birth year to now
            for year in petBirthYear...currentYear {
                guard let birthdayDate = calendar.date(from: DateComponents(year: year, month: petMonth, day: petDay)) else {
                    continue
                }

                // Skip if birthday is in the future
                if birthdayDate > Date() {
                    continue
                }

                let petAge = year - petBirthYear
                let coordinates = dateCalculator.dateToWeekCoordinates(date: birthdayDate, userBirthDate: userProfile.dateOfBirth)

                let title: String
                let description: String

                if petAge == 0 {
                    title = "\(pet.name) Joined Our Family"
                    description = "Welcome home, \(pet.name)!"
                } else {
                    title = "\(pet.name)'s \(petAge)\(ordinalSuffix(for: petAge)) Birthday"
                    description = "Celebrating \(pet.name)'s birthday"
                }

                let entry = WeekEntry(
                    userId: userId,
                    weekYear: coordinates.weekYear,
                    weekNumber: coordinates.weekNumber,
                    entryType: .memory,
                    dayOfWeek: coordinates.dayOfWeek,
                    title: title,
                    description: description,
                    tags: ["birthday", "pet", pet.type.rawValue.lowercased(), "special-date"]
                )

                do {
                    try await memoryViewModel.createEntry(entry)
                    print("  ✅ Created birthday memory for \(pet.name) age \(petAge)")
                } catch {
                    print("  ❌ Failed to create pet birthday memory: \(error.localizedDescription)")
                }
            }
        }
    }

    private func createGraduationMemory(userId: String) async {
        guard !userProfile.schoolName.isEmpty, userProfile.graduationYear > 0 else { return }

        let calendar = Calendar.current

        // Use June 1st as graduation date
        guard let graduationDate = calendar.date(from: DateComponents(year: userProfile.graduationYear, month: 6, day: 1)) else {
            return
        }

        // Skip if graduation is in the future
        if graduationDate > Date() {
            return
        }

        let coordinates = dateCalculator.dateToWeekCoordinates(date: graduationDate, userBirthDate: userProfile.dateOfBirth)

        let degreeText = userProfile.degree.isEmpty ? "" : " with \(userProfile.degree)"
        let entry = WeekEntry(
            userId: userId,
            weekYear: coordinates.weekYear,
            weekNumber: coordinates.weekNumber,
            entryType: .memory,
            dayOfWeek: coordinates.dayOfWeek,
            title: "Graduation from \(userProfile.schoolName)",
            description: "Graduated\(degreeText) in \(userProfile.graduationYear)",
            tags: ["graduation", "education", "milestone", "special-date"]
        )

        do {
            try await memoryViewModel.createEntry(entry)
            print("  ✅ Created graduation memory")
        } catch {
            print("  ❌ Failed to create graduation memory: \(error.localizedDescription)")
        }
    }

    // Helper function for ordinal suffixes (1st, 2nd, 3rd, etc.)
    private func ordinalSuffix(for number: Int) -> String {
        let ones = number % 10
        let tens = (number / 10) % 10

        if tens == 1 {
            return "th"
        }

        switch ones {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }

    // MARK: - Helper Methods
    func getProgress() -> Double {
        return currentStep.progress
    }

    func canGoBack() -> Bool {
        return currentStep.rawValue > 0 && currentStep != .welcome
    }

    func isLastStep() -> Bool {
        return currentStep == .family
    }

    func resetOnboarding() {
        withAnimation {
            currentStep = .welcome
            userProfile = UserProfile()
            nameInput = ""
            selectedDate = Date()
            selectedDegree = ""
            schoolNameInput = ""
            graduationYear = Calendar.current.component(.year, from: Date())
            selectedIndustry = ""
            jobRoleInput = ""
            yearsWorkedValue = 0
            selectedRelationshipStatus = .single
            isMarried = false
            spouseNameInput = ""
            spouseDateOfBirth = Date()
            marriageDate = Date()
            children = []
            pets = []
            showDashboard = false
        }
    }
}
