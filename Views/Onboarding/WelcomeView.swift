//
//  WelcomeView.swift
//  simpleApp
//
//  Created by Sinchan Roychowdhury on 11/5/25.
//

import SwiftUI

struct WelcomeView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @StateObject private var themeEngine = NostalgiaThemeEngine()
    @StateObject private var specialDatesViewModel = SpecialDatesViewModel()
    @StateObject private var memoryViewModel = MemoryViewModel()
    @EnvironmentObject var authService: AuthenticationService

    var body: some View {
        ZStack {
            if viewModel.showDashboard {
                DashboardView(userProfile: viewModel.userProfile, themeEngine: themeEngine)
                    .environmentObject(authService)
                    .environmentObject(specialDatesViewModel)
                    .environmentObject(memoryViewModel)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                OnboardingContainerView()
                    .environmentObject(viewModel)
                    .environmentObject(themeEngine)
                    .environmentObject(authService)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(Constants.Animation.smooth, value: viewModel.showDashboard)
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            // When user signs out, reset the onboarding
            if !newValue && oldValue {
                viewModel.resetOnboarding()
            }
        }
    }
}

struct OnboardingContainerView: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var themeEngine: NostalgiaThemeEngine

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    AppColors.background,
                    AppColors.secondary.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if viewModel.isLoading {
                CircularProgressIndicator(message: "Calculating your life's journey...")
                    .transition(.scale.combined(with: .opacity))
            } else {
                VStack(spacing: 0) {
                    // Progress indicator (hidden on welcome screen)
                    if viewModel.currentStep != .welcome {
                        ProgressIndicator(
                            progress: viewModel.getProgress(),
                            totalSteps: Constants.OnboardingStep.allCases.count - 1,
                            currentStep: viewModel.currentStep.rawValue
                        )
                        .padding(.horizontal, Constants.Layout.paddingLarge)
                        .padding(.top, Constants.Layout.paddingMedium)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Main content
                    currentStepView
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                }
            }
        }
        .onChange(of: viewModel.userProfile.dateOfBirth) { oldValue, newValue in
            // Update theme based on birth year
            themeEngine.updateTheme(for: viewModel.userProfile)
        }
    }

    @ViewBuilder
    private var currentStepView: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeScreen()
        case .name:
            NameInputView()
        case .dateOfBirth:
            DateOfBirthInputView()
        case .education:
            EducationStepView()
        case .work:
            WorkStepView()
        case .family:
            FamilyStepView()
        }
    }
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    @EnvironmentObject var viewModel: OnboardingViewModel
    @EnvironmentObject var authService: AuthenticationService
    @State private var showContent = false
    @State private var pulseAnimation = false
    @State private var showAuthSheet = false

    init() {
        print("🟡 WelcomeScreen: Initializing")
    }

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App icon/logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.accent],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .opacity(pulseAnimation ? 0.8 : 1.0)

                Image(systemName: "hourglass")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(showContent ? 0 : 180))
            }
            .shadow(color: AppColors.primary.opacity(0.4), radius: 20, y: 10)

            VStack(spacing: 16) {
                Text("Life Journey")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                Text("Discover how you're spending\nyour one precious life")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)

            Spacer()

            VStack(spacing: 16) {
                // Sign In Button
                AnimatedButton(
                    title: "Sign In",
                    icon: "person.fill",
                    action: {
                        showAuthSheet = true
                    },
                    style: .primary
                )

                // Continue as Guest Button
                AnimatedButton(
                    title: "Continue as Guest",
                    icon: "arrow.right",
                    action: {
                        viewModel.moveToNextStep()
                    },
                    style: .ghost
                )

                Text("Takes less than 2 minutes")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
            }
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 20)
        }
        .padding(Constants.Layout.paddingLarge)
        .onAppear {
            withAnimation(Constants.Animation.smooth.delay(0.2)) {
                showContent = true
            }

            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                pulseAnimation = true
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            LoginView()
                .environmentObject(authService)
        }
        .onAppear {
            print("🟡 WelcomeScreen: onAppear - isAuthenticated = \(authService.isAuthenticated), viewModel.showDashboard = \(viewModel.showDashboard), isRestoringSession = \(authService.isRestoringSession)")

            // If user is already authenticated when view appears, load their profile
            // Wait for session restoration to complete first
            if authService.isAuthenticated && !viewModel.showDashboard && !authService.isRestoringSession {
                print("🟡 WelcomeScreen: User already authenticated on appear (session restored), loading profile")
                handleAuthenticatedUser()
            } else if authService.isAuthenticated && authService.isRestoringSession {
                print("🟡 WelcomeScreen: User authenticated but still restoring session, will handle after restoration")
            }
        }
        .onChange(of: authService.isRestoringSession) { oldValue, newValue in
            print("🟡 WelcomeScreen: onChange(isRestoringSession) - old: \(oldValue), new: \(newValue)")

            // When session restoration completes and user is authenticated, load profile
            if oldValue && !newValue && authService.isAuthenticated && !viewModel.showDashboard {
                print("🟡 WelcomeScreen: Session restoration completed with authenticated user, loading profile")
                handleAuthenticatedUser()
            }
        }
        .onChange(of: authService.isAuthenticated) { oldValue, newValue in
            print("🟡 WelcomeScreen: onChange(isAuthenticated) triggered - old: \(oldValue), new: \(newValue)")
            print("🟡 WelcomeScreen: isRestoringSession = \(authService.isRestoringSession)")

            // Only process when user just authenticated (transitioned from false to true)
            // AND we're not in the middle of restoring a saved session
            if !oldValue && newValue && !authService.isRestoringSession {
                print("🟡 WelcomeScreen: User authenticated (not session restore), processing...")

                // Dismiss the auth sheet if it's open
                if showAuthSheet {
                    showAuthSheet = false
                    print("🟡 WelcomeScreen: showAuthSheet set to false")
                }

                handleAuthenticatedUser()
            }
        }
    }

    private func handleAuthenticatedUser() {
        // Update user profile with auth info
        viewModel.userProfile.userId = authService.currentUser?.id
        viewModel.userProfile.email = authService.currentUser?.email
        viewModel.userProfile.isAnonymous = false
        print("🟡 WelcomeScreen: User profile updated with auth info")
        print("🟡 WelcomeScreen: isNewUser flag = \(authService.isNewUser)")

        // Check if this is a new user (sign-up) or existing user (sign-in)
        if authService.isNewUser {
            print("🟡 WelcomeScreen: New user sign-up detected")

            // Check if user has already completed some onboarding steps as guest
            let hasExistingProfile = !viewModel.userProfile.name.isEmpty

            if hasExistingProfile {
                print("🟡 WelcomeScreen: User has existing guest profile, saving to cloud and going to dashboard")
                // User was using app as guest and now signed up - save their guest profile to Firestore
                Task {
                    do {
                        if let userId = authService.currentUser?.id {
                            print("🟡 WelcomeScreen: Saving guest profile to Firestore for userId: \(userId)")
                            try await UserProfileService.shared.saveProfile(viewModel.userProfile)
                            print("✅ WelcomeScreen: Guest profile saved successfully to Firestore")
                        }
                    } catch {
                        print("❌ WelcomeScreen: Failed to save guest profile: \(error.localizedDescription)")
                    }
                    viewModel.showDashboard = true
                }
            } else {
                print("🟡 WelcomeScreen: No existing profile, proceeding with onboarding")
                // New user with no existing data - go through onboarding
                viewModel.moveToNextStep()
            }
        } else {
            print("🟡 WelcomeScreen: Existing user sign-in detected, loading profile from Firestore")
            // Existing user - load their profile from Firestore
            Task {
                do {
                    if let userId = authService.currentUser?.id {
                        print("🟡 WelcomeScreen: Loading profile for userId: \(userId)")
                        if let loadedProfile = try await UserProfileService.shared.loadProfile(userId: userId) {
                            print("✅ WelcomeScreen: Profile loaded successfully from Firestore")
                            viewModel.userProfile = loadedProfile

                            // Check if profile is complete before going to dashboard
                            if isProfileComplete(loadedProfile) {
                                print("✅ WelcomeScreen: Profile is complete, navigating to dashboard")
                                viewModel.showDashboard = true
                            } else {
                                print("⚠️ WelcomeScreen: Profile is incomplete, proceeding with onboarding")
                                // Profile exists but is incomplete - continue onboarding
                                if let displayName = authService.currentUser?.displayName, loadedProfile.name.isEmpty {
                                    viewModel.userProfile.name = displayName
                                }
                                viewModel.moveToNextStep()
                            }
                        } else {
                            print("⚠️ WelcomeScreen: No profile found in Firestore, proceeding with onboarding")
                            // User signed in but hasn't completed onboarding yet
                            if let displayName = authService.currentUser?.displayName {
                                viewModel.userProfile.name = displayName
                            }
                            viewModel.moveToNextStep()
                        }
                    }
                } catch {
                    print("❌ WelcomeScreen: Failed to load profile: \(error.localizedDescription)")
                    // Load failed - redirect to onboarding to create profile
                    if let displayName = authService.currentUser?.displayName {
                        viewModel.userProfile.name = displayName
                    }
                    viewModel.moveToNextStep()
                }
            }
        }
        print("🟡 WelcomeScreen: Processing complete")
    }

    // Helper function to check if profile is complete
    private func isProfileComplete(_ profile: UserProfile) -> Bool {
        // A complete profile should have:
        // - Non-empty name
        // - Valid date of birth (not today's date which is the default)
        // - Industry and job role filled
        // - Years worked >= 0

        let hasName = !profile.name.isEmpty
        let hasValidDOB = Calendar.current.dateComponents([.day], from: profile.dateOfBirth, to: Date()).day ?? 0 > 0
        let hasIndustry = !profile.industry.isEmpty
        let hasJobRole = !profile.jobRole.isEmpty

        let isComplete = hasName && hasValidDOB && hasIndustry && hasJobRole

        print("🔍 Profile completeness check:")
        print("  hasName: \(hasName) (\(profile.name))")
        print("  hasValidDOB: \(hasValidDOB) (age: \(profile.age))")
        print("  hasIndustry: \(hasIndustry) (\(profile.industry))")
        print("  hasJobRole: \(hasJobRole) (\(profile.jobRole))")
        print("  isComplete: \(isComplete)")

        return isComplete
    }
}

#Preview {
    WelcomeView()
        .environmentObject(AuthenticationService.shared)
}
