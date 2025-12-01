# simpleApp

A SwiftUI-based iOS life tracking and memory visualization application that helps users track their life journey through an interactive calendar interface, manage special dates, and preserve memories.

## Overview

simpleApp is a personal life tracking application that visualizes your life as a grid of weeks, similar to the concept of "Your Life in Weeks." It combines life visualization with memory tracking, special date management, and personal milestone documentation.

## Features

### Life Visualization
- **Life Calendar View**: Visualize your entire life as a grid of weeks (up to 90 years)
- **Week-by-Week Tracking**: Each week can contain memories, photos, audio recordings, and notes
- **Interactive Timeline**: Navigate through your life history with an intuitive interface
- **Work/Life Balance Visualization**: Color-coded representation of work years vs. other life periods

### Memory Management
- **Rich Memories**: Create detailed memory entries with:
  - Photos and image galleries
  - Audio recordings
  - Location data
  - Text descriptions
  - Custom tags
- **Special Date Memories**: Automatic memory creation for birthdays, anniversaries, and other milestones
- **Memory Search & Filter**: Find memories by tags, dates, or content

### Special Dates Tracking
- **Personal Milestones**: Track your birthday, graduation, and other important dates
- **Family Events**: Remember anniversaries, spouse birthdays, children's birthdays
- **Pet Birthdays**: Keep track of your pets' special days
- **Recurring Reminders**: Get notified about upcoming special dates
- **Goal Setting**: Set and track goals for special occasions

### User Profile & Onboarding
- **Comprehensive Profile**: Capture personal information including:
  - Basic info (name, date of birth)
  - Education (degree, school, graduation year)
  - Work history (industry, job role, years worked)
  - Family details (relationship status, spouse, children, pets)
- **Guided Onboarding**: Step-by-step onboarding flow to set up your profile
- **Nostalgia Themes**: Era-based theming based on your birth year (80s, 90s, 2000s, etc.)

### Authentication & Cloud Sync
- **Firebase Authentication**: Secure user authentication with support for:
  - Email/password authentication
  - Guest/anonymous mode
- **Cloud Storage**: Sync your data across devices using Firebase Firestore
- **Media Storage**: Securely store photos and audio in Firebase Storage
- **Supabase Integration**: Alternative backend support (in progress)

## Tech Stack

### Frontend
- **SwiftUI**: Modern declarative UI framework
- **Combine**: Reactive programming for state management
- **Core Data**: Local persistence layer

### Backend & Services
- **Firebase**:
  - Firebase Authentication
  - Cloud Firestore (database)
  - Firebase Storage (media files)
- **Supabase** (optional alternative):
  - Supabase Auth
  - Supabase Database
  - Supabase Storage

### Key Frameworks
- AVFoundation (audio recording/playback)
- MapKit (location services)
- UserNotifications (reminders)

## Project Structure

```
simpleApp/
├── Models/
│   ├── UserProfile.swift          # User profile data model
│   ├── WeekEntry.swift            # Memory/week entry model
│   ├── CustomSpecialDate.swift    # Special date model
│   ├── MediaItem.swift            # Media attachment model
│   ├── WorkLifeData.swift         # Work/life data model
│   └── IndustryData.swift         # Industry reference data
│
├── Views/
│   ├── Visualization/
│   │   ├── LifeCalendarView.swift      # Main life calendar grid
│   │   ├── DashboardView.swift         # Dashboard overview
│   │   ├── TimelineView.swift          # Timeline visualization
│   │   └── PieChartView.swift          # Data charts
│   ├── Memory/
│   │   ├── WeekDetailSheet.swift       # Week detail view
│   │   ├── EntryEditorView.swift       # Memory editor
│   │   ├── EntryViewerViews.swift      # Memory viewer
│   │   ├── PhotoGalleryView.swift      # Photo gallery
│   │   ├── AudioRecorderView.swift     # Audio recorder
│   │   ├── AudioPlayerView.swift       # Audio player
│   │   ├── LocationPickerView.swift    # Location picker
│   │   └── ReminderSettingsView.swift  # Reminder configuration
│   ├── SpecialDates/
│   │   ├── SpecialDatesTab.swift       # Special dates list
│   │   ├── AddSpecialDateView.swift    # Add new special date
│   │   ├── SpecialDateDetailView.swift # Date detail view
│   │   └── SpecialDateGoalEditorView.swift # Goal editor
│   ├── Onboarding/
│   │   ├── WelcomeView.swift           # Onboarding welcome
│   │   └── InputViews.swift            # Onboarding input forms
│   ├── Authentication/
│   │   ├── AuthenticationContainerView.swift
│   │   ├── LoginView.swift             # Login screen
│   │   ├── SignUpView.swift            # Sign up screen
│   │   └── AuthPromptView.swift        # Auth prompt
│   ├── Settings/
│   │   └── SettingsView.swift          # App settings
│   └── Components/
│       ├── AnimatedButton.swift        # Reusable button component
│       ├── NostalgicTextField.swift    # Themed text field
│       └── ProgressIndicator.swift     # Progress indicator
│
├── ViewModels/
│   ├── OnboardingViewModel.swift       # Onboarding logic
│   ├── MemoryViewModel.swift           # Memory management
│   ├── SpecialDatesViewModel.swift     # Special dates logic
│   ├── CalculationEngine.swift         # Life calculations
│   └── APIService.swift                # API integration
│
├── Services/
│   ├── Protocols/
│   │   └── BackendServiceProtocols.swift # Service interfaces
│   ├── Firebase/
│   │   ├── FirebaseAuthService.swift
│   │   ├── FirebaseDatabaseService.swift
│   │   ├── FirebaseStorageService.swift
│   │   └── FirestoreService.swift
│   ├── Supabase/
│   │   ├── SupabaseConfig.swift
│   │   ├── SupabaseAuthService.swift
│   │   ├── SupabaseDatabaseService.swift
│   │   └── SupabaseStorageService.swift
│   ├── AuthenticationService.swift      # Unified auth service
│   ├── UserProfileService.swift         # Profile management
│   ├── StorageService.swift             # File storage
│   ├── NotificationManager.swift        # Push notifications
│   └── BackendContainer.swift           # Service container
│
├── Utilities/
│   ├── Constants.swift                  # App constants
│   ├── ColorSchemes.swift               # Color definitions
│   ├── NostalgiaThemeEngine.swift       # Theme engine
│   └── AccessibilityHelpers.swift       # Accessibility support
│
├── Utils/
│   └── DateCalculator.swift             # Date utility functions
│
├── simpleApp.xcdatamodeld/              # Core Data model
├── ContentView.swift                    # Root content view
├── simpleAppApp.swift                   # App entry point
└── Persistence.swift                    # Core Data stack

```

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0 or later
- Swift 5.9 or later
- CocoaPods or Swift Package Manager

### Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use an existing one

2. **Add iOS App to Firebase**
   - Register your app with bundle identifier
   - Download `GoogleService-Info.plist`
   - Add the file to your Xcode project root

3. **Enable Firebase Services**
   - Enable **Authentication** (Email/Password, Anonymous)
   - Enable **Cloud Firestore**
   - Enable **Storage**

4. **Configure Firestore Security Rules**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
       match /weekEntries/{entryId} {
         allow read, write: if request.auth != null &&
           request.auth.uid == resource.data.userId;
       }
     }
   }
   ```

5. **Configure Storage Security Rules**
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /users/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/sinchan1987/simpleApp.git
   cd simpleApp/simpleApp
   ```

2. **Install Dependencies**

   If using Swift Package Manager (recommended):
   - Open the project in Xcode
   - Dependencies should resolve automatically

   If using CocoaPods:
   ```bash
   pod install
   ```

3. **Add Firebase Configuration**
   - Ensure `GoogleService-Info.plist` is in the project root
   - Verify it's included in the target

4. **Build and Run**
   - Select your target device or simulator
   - Press Cmd+R to build and run

## Configuration

### Switching Between Firebase and Supabase

The app supports both Firebase and Supabase as backend services. To switch:

1. Open `Services/BackendContainer.swift`
2. Modify the initialization to use your preferred backend
3. Configure the corresponding service credentials

### Customizing Themes

Edit `Utilities/NostalgiaThemeEngine.swift` to customize era-based themes.

### Modifying Onboarding Flow

Edit `ViewModels/OnboardingViewModel.swift` and `Views/Onboarding/` to customize the onboarding experience.

## Key Concepts

### Week Coordinates
The app uses a unique week-based coordinate system:
- **Week Year**: Age in years (0 = birth year)
- **Week Number**: Week within that year (0-51)
- **Day of Week**: Specific day within the week (0-6)

This allows precise mapping of any date to a specific "week box" in the life calendar.

### Special Date Types
- `birthday`: User's birthday
- `anniversary`: Wedding anniversary
- `spouseBirthday`: Spouse's birthday
- `childBirthday`: Children's birthdays
- `petBirthday`: Pet birthdays
- `graduation`: Graduation date

### Memory Entry Types
- `memory`: User-created memory
- `milestone`: Auto-generated milestone
- `goal`: Future goal or aspiration

## Data Models

### UserProfile
Contains all user information including personal details, education, work history, and family information.

### WeekEntry
Represents a memory or event tied to a specific week in the user's life calendar.

### CustomSpecialDate
User-defined special dates with goals, reminders, and recurring settings.

## Privacy & Security

- All user data is stored securely in Firebase/Supabase
- Authentication required for data access
- Media files stored with user-specific permissions
- Guest mode available for testing without account creation
- No analytics or tracking implemented

## Contributing

This is a personal project. If you'd like to contribute or have suggestions:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

[Add your license here]

## Author

Sinchan Roychowdhury

## Acknowledgments

- Inspired by the "Your Life in Weeks" concept
- Built with SwiftUI and Firebase
- Uses modern iOS development best practices

---

**Repository**: https://github.com/sinchan1987/simpleApp
**Created**: November 2025
