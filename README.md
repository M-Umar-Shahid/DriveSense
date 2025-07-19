# DriveSense

## Introduction

DriveSense is a Flutter mobile application designed to enhance road safety by monitoring driver behavior in real-time. Leveraging on-device AI models and the device camera, it detects signs of drowsiness, distraction, and seatbelt usage, then provides visual and audio alerts to help prevent accidents. All user data is securely managed via Firebase services.

## Features

- **User Authentication**: Secure email/password sign-up and login powered by Firebase Authentication.
- **Real-time Monitoring**: Continuously analyze camera frames for drowsiness, distraction, and seatbelt usage.
- **Analytics Dashboard**: Overview of key metrics—total alerts, trip summaries, and focus percentage.
- **Detection Gallery**: Browse and filter saved snapshots, with full-screen image view.
- **Profile Management**: View and update your user profile information directly within the app.

## Prerequisites

- Flutter SDK 3.0 or later
- Dart SDK
- Android Studio (for Android) or Xcode (for iOS)
- A Firebase project with **Authentication** and **Firestore** enabled

## Installation

```bash
cd DriveSense
flutter pub get
