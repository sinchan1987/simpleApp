//
//  InputViews.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

// MARK: - Name Input View
struct NameInputView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        InputScreenTemplate(
            title: viewModel.currentStep.title,
            subtitle: viewModel.currentStep.subtitle,
            showContent: $showContent
        ) {
            VStack(spacing: 24) {
                NostalgicTextField(
                    placeholder: "Your name",
                    text: $viewModel.nameInput,
                    icon: "person.fill",
                    errorMessage: viewModel.nameError
                )

                Spacer()

                NavigationButtons()
            }
        }
    }
}

// MARK: - Date of Birth Input View
struct DateOfBirthInputView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var themeEngine: NostalgiaThemeEngine
    @State private var showContent = false

    var body: some View {
        InputScreenTemplate(
            title: viewModel.currentStep.title,
            subtitle: viewModel.currentStep.subtitle,
            showContent: $showContent
        ) {
            VStack(spacing: 24) {
                DatePicker(
                    "Date of Birth",
                    selection: $viewModel.selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                )

                if viewModel.dobError != nil {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 14))
                        Text(viewModel.dobError ?? "")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.red)
                }

                // Show nostalgia era hint
                if viewModel.selectedDate < Date() {
                    let age = Calendar.current.dateComponents([.year], from: viewModel.selectedDate, to: Date()).year ?? 0
                    if age >= 16 && age <= 100 {
                        HStack(spacing: 8) {
                            Image(systemName: themeEngine.getEraIcon())
                                .foregroundColor(AppColors.accent)
                            Text(themeEngine.getTagline())
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppColors.accent.opacity(0.1))
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Spacer()

                NavigationButtons()
            }
        }
    }
}

// MARK: - Education Step View
struct EducationStepView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        InputScreenTemplate(
            title: viewModel.currentStep.title,
            subtitle: viewModel.currentStep.subtitle,
            showContent: $showContent
        ) {
            ScrollView {
                VStack(spacing: 24) {
                    // Degree Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Highest Degree", systemImage: "graduationcap.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Constants.degrees, id: \.self) { degree in
                                    DegreeCard(
                                        degree: degree,
                                        isSelected: viewModel.selectedDegree == degree
                                    ) {
                                        withAnimation(Constants.Animation.bouncy) {
                                            viewModel.selectedDegree = degree
                                        }
                                        Constants.Haptics.selection.selectionChanged()
                                    }
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                    }

                    // School Name
                    NostalgicTextField(
                        placeholder: "School/University name",
                        text: $viewModel.schoolNameInput,
                        icon: "building.columns.fill"
                    )

                    // Graduation Year
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Graduation Year", systemImage: "calendar")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        Picker("Graduation Year", selection: $viewModel.graduationYear) {
                            ForEach((1950...Calendar.current.component(.year, from: Date()) + 10).reversed(), id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                    )

                    if let error = viewModel.educationError {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }

                    Spacer()

                    NavigationButtons()
                }
            }
        }
    }
}

struct DegreeCard: View {
    let degree: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(degree)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : AppColors.textPrimary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? AppColors.primary : Color.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? AppColors.primary : Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}

// MARK: - Work Step View (Combined)
struct WorkStepView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showContent = false
    @State private var searchText = ""

    var filteredIndustries: [String] {
        if searchText.isEmpty {
            return Constants.industries
        }
        return Constants.industries.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        InputScreenTemplate(
            title: viewModel.currentStep.title,
            subtitle: viewModel.currentStep.subtitle,
            showContent: $showContent
        ) {
            ScrollView {
                VStack(spacing: 24) {
                    // Industry Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Industry", systemImage: "building.2.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)

                        NostalgicTextField(
                            placeholder: "Search industries...",
                            text: $searchText,
                            icon: "magnifyingglass"
                        )

                        ScrollView {
                            LazyVStack(spacing: 8) {
                                ForEach(filteredIndustries, id: \.self) { industry in
                                    IndustryCard(
                                        industry: industry,
                                        isSelected: viewModel.selectedIndustry == industry
                                    ) {
                                        withAnimation(Constants.Animation.bouncy) {
                                            viewModel.selectedIndustry = industry
                                            viewModel.workError = nil
                                        }
                                        Constants.Haptics.selection.selectionChanged()
                                    }
                                }
                            }
                        }
                        .frame(height: 150)
                    }

                    // Job Role
                    NostalgicTextField(
                        placeholder: "e.g., Software Engineer, Nurse, Teacher",
                        text: $viewModel.jobRoleInput,
                        icon: "briefcase.fill"
                    )

                    // Years Worked
                    VStack(spacing: 16) {
                        Label("Years of Experience", systemImage: "clock.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Text("\(String(format: "%.1f", viewModel.yearsWorkedValue)) years")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppColors.primary)

                        Slider(
                            value: $viewModel.yearsWorkedValue,
                            in: 0...50,
                            step: 0.5
                        )
                        .accentColor(AppColors.primary)
                        .onChange(of: viewModel.yearsWorkedValue) { oldValue, newValue in
                            Constants.Haptics.selection.selectionChanged()
                        }

                        HStack {
                            Text("0 years")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)

                            Spacer()

                            Text("50+ years")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    .padding(Constants.Layout.paddingMedium)
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                    )

                    if let error = viewModel.workError {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }

                    NavigationButtons()
                }
            }
        }
    }
}

struct IndustryCard: View {
    let industry: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(industry)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppColors.primary)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(Constants.Layout.paddingMedium)
            .background(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                    .fill(isSelected ? AppColors.primary.opacity(0.1) : Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                    .stroke(isSelected ? AppColors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Family Step View
struct FamilyStepView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @State private var showContent = false

    var body: some View {
        InputScreenTemplate(
            title: viewModel.currentStep.title,
            subtitle: viewModel.currentStep.subtitle,
            showContent: $showContent
        ) {
            ScrollView {
                VStack(spacing: 24) {
                    // Marriage Toggle
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle(isOn: $viewModel.isMarried) {
                            Label("I am married", systemImage: "heart.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .tint(AppColors.primary)
                        .onChange(of: viewModel.isMarried) { oldValue, newValue in
                            Constants.Haptics.selection.selectionChanged()
                        }

                        // Spouse Details (shown only if married)
                        if viewModel.isMarried {
                            VStack(spacing: 16) {
                                NostalgicTextField(
                                    placeholder: "Spouse's name",
                                    text: $viewModel.spouseNameInput,
                                    icon: "person.fill"
                                )

                                VStack(spacing: 8) {
                                    Text("Spouse's Date of Birth")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    DatePicker(
                                        "",
                                        selection: $viewModel.spouseDateOfBirth,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                }
                                .frame(maxWidth: .infinity)

                                VStack(spacing: 8) {
                                    Text("Marriage Date")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.textSecondary)

                                    DatePicker(
                                        "",
                                        selection: $viewModel.marriageDate,
                                        in: ...Date(),
                                        displayedComponents: .date
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding(.leading, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                    )

                    // Children Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Children", systemImage: "figure.2.and.child.holdinghands")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            Button(action: {
                                viewModel.addChild()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primary)
                            }
                        }

                        if viewModel.children.isEmpty {
                            Text("No children added")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(viewModel.children.enumerated()), id: \.element.id) { index, child in
                                ChildEntryView(
                                    index: index,
                                    child: child,
                                    onUpdate: { name, dob in
                                        viewModel.updateChild(at: index, name: name, dateOfBirth: dob)
                                    },
                                    onRemove: {
                                        viewModel.removeChild(at: index)
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                    )

                    // Pets Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("Pets", systemImage: "pawprint.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            Button(action: {
                                viewModel.addPet()
                            }) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primary)
                            }
                        }

                        if viewModel.pets.isEmpty {
                            Text("No pets added")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(Array(viewModel.pets.enumerated()), id: \.element.id) { index, pet in
                                PetEntryView(
                                    index: index,
                                    pet: pet,
                                    onUpdate: { name, type, birthday in
                                        viewModel.updatePet(at: index, name: name, type: type, birthday: birthday)
                                    },
                                    onRemove: {
                                        viewModel.removePet(at: index)
                                    }
                                )
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Constants.Layout.cornerRadiusMedium)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                    )

                    if let error = viewModel.familyError {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }

                    NavigationButtons()
                }
            }
        }
    }
}

// MARK: - Child Entry View
struct ChildEntryView: View {
    let index: Int
    let child: Child
    let onUpdate: (String?, Date?) -> Void
    let onRemove: () -> Void

    @State private var name: String = ""
    @State private var dateOfBirth: Date = Date()

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Child \(index + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.7))
                }
            }

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: name) { oldValue, newValue in
                    onUpdate(newValue, nil)
                }

            DatePicker(
                "Date of Birth",
                selection: $dateOfBirth,
                in: ...Date(),
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .onChange(of: dateOfBirth) { oldValue, newValue in
                onUpdate(nil, newValue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.background)
        )
        .onAppear {
            name = child.name
            dateOfBirth = child.dateOfBirth
        }
    }
}

// MARK: - Pet Entry View
struct PetEntryView: View {
    let index: Int
    let pet: Pet
    let onUpdate: (String?, PetType?, Date?) -> Void
    let onRemove: () -> Void

    @State private var name: String = ""
    @State private var type: PetType = .dog
    @State private var birthday: Date = Date()
    @State private var hasBirthday: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Pet \(index + 1)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)

                Spacer()

                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.7))
                }
            }

            TextField("Name", text: $name)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: name) { oldValue, newValue in
                    onUpdate(newValue, nil, nil)
                }

            Picker("Type", selection: $type) {
                ForEach(PetType.allCases, id: \.self) { petType in
                    Text(petType.displayName).tag(petType)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: type) { oldValue, newValue in
                onUpdate(nil, newValue, nil)
            }

            Toggle("Add Birthday", isOn: $hasBirthday)
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)

            if hasBirthday {
                DatePicker(
                    "Birthday",
                    selection: $birthday,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .onChange(of: birthday) { oldValue, newValue in
                    onUpdate(nil, nil, newValue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.background)
        )
        .onAppear {
            name = pet.name
            type = pet.type
            if let petBirthday = pet.birthday {
                birthday = petBirthday
                hasBirthday = true
            }
        }
    }
}

struct StepperCard: View {
    let title: String
    let icon: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Label(title, systemImage: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textPrimary)

            Spacer()

            HStack(spacing: 16) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                        Constants.Haptics.light.impactOccurred()
                    }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(value > range.lowerBound ? AppColors.primary : Color.gray.opacity(0.3))
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.primary)
                    .frame(width: 40)

                Button(action: {
                    if value < range.upperBound {
                        value += 1
                        Constants.Haptics.light.impactOccurred()
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(value < range.upperBound ? AppColors.primary : Color.gray.opacity(0.3))
                }
                .disabled(value >= range.upperBound)
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

// MARK: - Input Screen Template
struct InputScreenTemplate<Content: View>: View {
    let title: String
    let subtitle: String
    @Binding var showContent: Bool
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Constants.Layout.paddingLarge)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : -20)

            content
                .padding(.horizontal, Constants.Layout.paddingLarge)
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
        }
        .onAppear {
            withAnimation(Constants.Animation.smooth.delay(0.1)) {
                showContent = true
            }
        }
    }
}

// MARK: - Navigation Buttons
struct NavigationButtons: View {
    @EnvironmentObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 12) {
            AnimatedButton(
                title: viewModel.isLastStep() ? "See My Life Journey" : "Continue",
                icon: viewModel.isLastStep() ? "chart.pie.fill" : "arrow.right",
                action: {
                    viewModel.moveToNextStep()
                },
                style: .primary
            )

            if viewModel.canGoBack() {
                Button(action: {
                    viewModel.moveToPreviousStep()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.vertical, 12)
                }
            }
        }
    }
}

#Preview("Name Input") {
    NameInputView()
        .environmentObject(OnboardingViewModel())
}

#Preview("Date of Birth") {
    DateOfBirthInputView()
        .environmentObject(OnboardingViewModel())
        .environmentObject(NostalgiaThemeEngine())
}

