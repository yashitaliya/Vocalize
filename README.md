<div align="center">
  <img src="assets/images/logo.png" alt="Vocalize Logo" width="110" />

  # 🎙️ Vocalize

  <h3>A Flutter app for real language practice through video calls, flashcards, tests, and progress tracking.</h3>

  <p>
    <img alt="Flutter" src="https://img.shields.io/badge/Flutter-3.10%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
    <img alt="Firebase" src="https://img.shields.io/badge/Firebase-Auth%20%7C%20Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
    <img alt="Agora" src="https://img.shields.io/badge/Agora-RTC-099DFD?style=for-the-badge" />
    <img alt="ML Kit" src="https://img.shields.io/badge/Google%20ML%20Kit-On--Device-4285F4?style=for-the-badge&logo=google&logoColor=white" />
  </p>
</div>

---

## ✨ Overview

**Vocalize** is a language-learning app we built to make speaking practice easier and more practical. Instead of only memorizing words, learners can connect with another learner, join a live video call, revise vocabulary, take tests, schedule sessions, and track their improvement from one place.

Most of the app is intentionally simple to run for demos and college evaluation. Core features use Flutter, Firebase Auth, Firestore, Agora, and on-device translation so the project can work without depending on expensive backend services.

---

## 📸 App Screens

The app has **24 user-facing screens** and **1 bottom-navigation shell** (`MainScreen`). These are the screenshots currently added to the project.

### Standard Screens

| Splash | Login | Sign Up |
| :---: | :---: | :---: |
| <img src="docs/screenshots/splash-screen.jpg" width="100%" alt="Splash Screen"> | <img src="docs/screenshots/auth-login.jpg" width="100%" alt="Login Screen"> | <img src="docs/screenshots/auth-signup.jpg" width="100%" alt="Sign Up Screen"> |

| Forgot Password | Onboarding Interests | Onboarding Language |
| :---: | :---: | :---: |
| <img src="docs/screenshots/auth-forgot-password.jpg" width="100%" alt="Forgot Password Screen"> | <img src="docs/screenshots/onboarding-interests.jpg" width="100%" alt="Onboarding Interests"> | <img src="docs/screenshots/onboarding-language.jpg" width="100%" alt="Onboarding Language"> |

| Match Found | Waiting for Match | Live Video Call |
| :---: | :---: | :---: |
| <img src="docs/screenshots/matchmaking-found.jpg" width="100%" alt="Match Found Screen"> | <img src="docs/screenshots/matchmaking-waiting.jpg" width="100%" alt="Waiting for Match Screen"> | <img src="docs/screenshots/live-video-call-translation.png" width="100%" alt="Live Video Call"> |

| Flashcard Front | Flashcard Answer | Favorites |
| :---: | :---: | :---: |
| <img src="docs/screenshots/flashcards-front.jpg" width="100%" alt="Flashcard Front"> | <img src="docs/screenshots/flashcards-answer.jpg" width="100%" alt="Flashcard Answer"> | <img src="docs/screenshots/vocab-favourite.jpg" width="100%" alt="Favorites"> |

| Vocabulary List | Test List | Test Taking |
| :---: | :---: | :---: |
| <img src="docs/screenshots/vocabulary-list.jpg" width="100%" alt="Vocabulary List"> | <img src="docs/screenshots/test-list.jpg" width="100%" alt="Test List"> | <img src="docs/screenshots/test-taking.jpg" width="100%" alt="Test Taking"> |

| Schedule Request | Scheduled Session | Profile |
| :---: | :---: | :---: |
| <img src="docs/screenshots/schedule-request.jpg" width="100%" alt="Schedule Request"> | <img src="docs/screenshots/schedule-session.jpg" width="100%" alt="Scheduled Session"> | <img src="docs/screenshots/profile.jpg" width="100%" alt="Profile"> |

| Achievements | Settings | Delete Account |
| :---: | :---: | :---: |
| <img src="docs/screenshots/achievements.jpg" width="100%" alt="Achievements"> | <img src="docs/screenshots/settings.jpg" width="100%" alt="Settings"> | <img src="docs/screenshots/delete-screen.jpg" width="100%" alt="Delete Account"> |

| Confirm Delete | | |
| :---: | :---: | :---: |
| <img src="docs/screenshots/confirm-delete.jpg" width="33%" alt="Confirm Delete"> | | |

### Scrollable Screens

| Home Dashboard | Call Summary | Test Result |
| :---: | :---: | :---: |
| <img src="docs/screenshots/home-dashboard.jpg" width="100%" alt="Home Dashboard"> | <img src="docs/screenshots/call-summary.jpg" width="100%" alt="Call Summary"> | <img src="docs/screenshots/test-result.jpg" width="100%" alt="Test Result"> |



---

## 🚀 Features

- 🔐 **Authentication**: Email/password login, sign up, forgot password, and Google Sign-In.
- 🧭 **Personalized onboarding**: Interest and target-language selection before entering the main app.
- 🎥 **Live practice calls**: Peer-to-peer video/audio sessions powered by Agora RTC.
- 🔎 **Matchmaking**: Firestore-based waiting queue and match creation.
- 🧠 **Vocabulary learning**: Flashcards, vocabulary lists, favorites, and progress tracking.
- 📝 **Language tests**: Test list, test-taking flow, score calculation, and result storage.
- 📅 **Scheduling**: Create, accept, decline, and track scheduled speaking sessions.
- 📊 **Session analysis**: Post-call feedback for speaking performance and improvement.
- 🏆 **Achievements**: Rank, streak-style progress, and learning milestones.
- 🌍 **Translation support**: On-device speech recognition and ML Kit translation fallback.
- 🔔 **Notifications**: Local reminders and optional Firebase Cloud Messaging integration.
- ⚙️ **Account settings**: Profile management, preferences, and account deletion flow.

---

## 🧱 Tech Stack

| Layer | Technology |
| :--- | :--- |
| 📱 App | Flutter, Dart, Material Design |
| 🔥 Backend | Firebase Auth, Cloud Firestore, Firebase Storage |
| 🎥 Calling | Agora RTC Engine |
| 🌍 Translation | Speech-to-Text, Google ML Kit Translation |
| 🔔 Notifications | Firebase Messaging, flutter_local_notifications |
| 🧪 Testing & Quality | flutter_lints, Flutter test tooling |
| ☁️ Optional Server | Firebase Cloud Functions for Agora STT and FCM automation |

---

## 🗂️ Project Structure

```text
lib/
├── core/
│   └── theme/                 # App colors and Material theme
├── models/                    # User, call, schedule, test, vocabulary models
├── screens/                   # 24 user-facing app screens + navigation shell
│   ├── auth/
│   ├── call/
│   ├── flashcards/
│   ├── home/
│   ├── onboarding/
│   ├── profile/
│   ├── schedule/
│   ├── session_analysis/
│   ├── settings/
│   ├── setup/
│   └── test/
├── services/                  # Firebase, Agora, scheduling, tests, vocabulary
├── utils/                     # Helper utilities
├── widgets/                   # Shared reusable UI widgets
└── main.dart                  # App entry point
```

Generated files, Firebase config files, build output, IDE files, and package caches are not shown here because they are not useful for understanding the app structure.

---

## 🔄 App Flow

```mermaid
graph LR
    Splash --> Auth{Authenticated?}
    Auth -- No --> Login
    Login --> Signup
    Login --> ForgotPassword
    Auth -- Yes --> Onboarding{Profile Complete?}
    Onboarding -- No --> InterestLanguage
    InterestLanguage --> VocabularySetup
    Onboarding -- Yes --> Home
    Home --> Matchmaking
    Matchmaking --> VideoCall
    VideoCall --> CallSummary
    CallSummary --> SessionAnalysis
    Home --> Flashcards
    Home --> Schedule
    Home --> Tests
    Home --> Profile
```

---

## 🧩 Core Modules

| Module | Purpose |
| :--- | :--- |
| `AuthService` | Firebase Auth, Google Sign-In, password reset, account deletion |
| `FirestoreService` | User profiles, tests, test results, vocabulary, session analysis |
| `MatchmakingService` | Waiting queue and peer match creation with Firestore |
| `AgoraService` | Video/audio engine setup, join/leave channel, camera/mic controls |
| `TranslationService` | Device speech recognition and on-device ML Kit translation |
| `ScheduleService` | Scheduled session CRUD, accept/decline workflows |
| `VocabularyService` | User vocabulary progress and favorite words |
| `AchievementService` | Achievement and rank calculation |
| `NotificationService` | FCM token handling and local scheduled notifications |

---

## 🗄️ Firestore Collections

```text
users
waiting_users
matches
scheduled_sessions
session_analysis
tests
test_results
vocabulary
transcriptions
notification_queue
users/{uid}/vocabulary
users/{uid}/favorite_words
```

---

## ⚙️ Setup

### Prerequisites

- Flutter SDK `3.10.4` or newer
- Firebase project with Authentication and Firestore enabled
- Agora App ID for video calling
- Android Studio or Xcode for device builds

### Installation

```bash
git clone https://github.com/YOUR_USERNAME/vocalize.git
cd vocalize
flutter pub get
flutter run --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
```

### Firebase Configuration

Add your Firebase configuration files locally. These files are required to run the app on your machine, but they should not be uploaded publicly.

```text
android/app/google-services.json
ios/Runner/GoogleService-Info.plist
macos/Runner/GoogleService-Info.plist
lib/firebase_options.dart
```

Generate `firebase_options.dart` with FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

### Agora Configuration

Agora is loaded through Dart defines so the App ID is not stored directly in source code:

```bash
flutter run --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
```

For release builds:

```bash
flutter build apk --release --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
```

---

## 🧪 Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
flutter build apk --release --dart-define=AGORA_APP_ID=YOUR_AGORA_APP_ID
```

## 📚 Documentation

- [`vocalize_diagrams.md`](vocalize_diagrams.md) - Workflow, DFD, use case, and ER diagrams.

---

## 👥 Team

Built as a Semester 6 Computer Engineering project by:

- **Yash Italiya**
- **Joshi Vedant**
- **Yug Kalathiya**

---

<div align="center">

### ⭐ If this project helped you, consider starring the repository.

Made with Flutter, Firebase, Agora, and a lot of speaking practice.

</div>
