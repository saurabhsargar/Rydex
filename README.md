# 🚗 Rydex – Car Sharing App

Rydex is a Flutter-based car-sharing application that allows users to **publish rides**, **search and book rides**, and **manage ride history** — all in one place.  
The app uses **Firebase** for authentication and real-time data storage, and **Google Maps API** for location-based features.

---

## ✨ Features

- 🔑 **User Authentication** with Firebase (Sign up / Login)
- 🚘 **Publish Ride** with location picker using Google Places API
- 🔍 **Search Rides** based on source and destination
- 📍 **Map Preview** with routes between locations
- 🗂 **Ride History** tracking
- 💬 **In-App Chat** between ride publisher and passengers (real-time with Firebase Firestore)
- 📱 **Responsive UI** for all devices
- 🌐 **Real-time updates** using Firebase Firestore

---

## 📦 Tech Stack

- **Flutter** (Dart)
- **Firebase** (Authentication, Firestore)
- **Provider** for State Management
- **Google Maps API** & **Google Places API**
- **Shared Preferences** for local storage

---

## 📥 Installation

### 1️⃣ Clone the repository

```bash
git clone https://github.com/saurabhsargar/Rydex.git
cd Rydex
```

### 2️⃣ Install dependencies

```bash
flutter pub get
```

---

## 🔥 Firebase Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)

2. Create a new project (or select an existing one)

3. Add your Flutter app to Firebase:
   - **For Android**: Register your package name and download `google-services.json`, then place it in `android/app/`
   - **For iOS**: Register your bundle ID and download `GoogleService-Info.plist`, then place it in `ios/Runner/`

4. Install FlutterFire CLI (if not already installed):
   ```bash
   dart pub global activate flutterfire_cli
   ```
   Make sure the `pub-cache/bin` folder is in your system PATH.

5. Generate `firebase_options.dart` using FlutterFire CLI:
   ```bash
   flutterfire configure
   ```
   - Select your Firebase project
   - Select the platforms you want to configure
   - The CLI will automatically generate `lib/firebase_options.dart`

---

## ▶️ Running the App

### For Android:
```bash
flutter run
```

### For iOS:
```bash
flutter run
```

---

## 📱 App Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
├── providers/                # State management
├── screens/                  # UI screens
├── services/                 # Firebase & API services
├── widgets/                  # Reusable UI components
└── utils/                    # Helper functions
```
