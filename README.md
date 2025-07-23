# PlaceMe

A smart seating arrangement system for events, based on participant preferences and venue features.  
Developed in **Flutter** with a **Firebase** backend.

---

## Table of Contents

- [Features](#features)
- [Getting Started](#getting-started)
- [Project Structure](#project-structure)
- [How It Works](#how-it-works)
- [Testing](#testing)
- [Authors](#authors)

---

## Features

- Create and manage different types of events (classroom, family, conference, etc.)
- Interactive graphical seating editor: add/move/delete tables, chairs, and venue features (like board, AC, entrance, window, stage, etc.)
- Participant preference management: who to sit with, who to avoid, and desired seat features
- Automatic smart seating arrangement using a Simulated Annealing optimization algorithm
- View the seating plan visually and export to CSV
- Firebase Authentication, Firestore Database, and Storage integration
- Admin/manager and participant roles
- Full support for Android, iOS, and desktop (Windows/Mac/Linux)
- Extensive integration and unit test suite



---

## Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install)
- [Dart](https://dart.dev/get-dart)
- [Firebase project](https://console.firebase.google.com/) (enable Firestore, Auth, and Storage)
- Android Studio / VSCode

### Setup Instructions

1. **Clone this repository**
   ```bash
   git clone https://github.com/nativlevi/place_me.git
   cd place_me
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) from Firebase Console.
   - Place them in the appropriate folders:
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`
   - Make sure Firebase is enabled for Auth, Firestore, and Storage.

4. **(Optional) For scripts:**  
   Place your `serviceAccount.json` file in the project root for admin scripts.

5. **Run the app**
   ```bash
   flutter run
   ```

---

## Project Structure

```
place_me/
├── lib/
│   ├── general/            # Main app logic, navigation, auth
│   ├── manager/            # Admin/manager screens and event editing
│   ├── participant/        # Participant screens and preferences
│   ├── logic/              # Seating optimization and algorithm
│   └── ...                 # Shared utilities and widgets
├── integration_test/        # Integration tests
├── test/                    # Unit tests
├── assets/                  # Images and other assets
└── ...
```

---

## How It Works

- **Event Creation**:  
  Managers create events, design the room graphically, and add seating and features.  
  Participants are invited by phone or via CSV upload.

- **Preference Collection**:  
  Each participant chooses people they want to sit with or avoid, and marks desired seating features (near board, AC, window, etc.) based on event type.

- **Smart Arrangement**:  
  When registration closes, the Simulated Annealing algorithm generates a seating map maximizing social and positional satisfaction.  
  Scoring considers friends together, avoided people apart, and matching seat features.

- **Results**:  
  Each participant sees their assigned seat on the map. Admins can export seating and scores as CSV.

---

## Testing

To run all tests:

```bash
flutter test
flutter test integration_test/
```

---

## Authors

- Neria Atias  
- Nativ Levi

---



