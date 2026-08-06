# 🏋️ Get Fit — Mobile Application

**Get Fit** is a comprehensive fitness and wellness mobile application built with **Flutter**. It connects users with professional fitness trainers, provides guided gym and yoga workouts, weekly fitness challenges, and allows users to book appointments, manage payments, and participate in live video calls with their trainers.

![Flutter](https://img.shields.io/badge/Flutter-3.3.1-blueviolet?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-≥3.3.1-blue?logo=dart&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)
![License](https://img.shields.io/badge/License-Private-informational)

---

## ✨ Features

The app is a full-featured fitness platform with a wide range of modules:

### 🏠 Home & Onboarding
- Beautiful onboarding flow with 3 introduction screens
- Modern home dashboard with quick-access containers and motivational content
- Launch page with animated startup experience

### 💪 Fitness Trainers
- Browse and discover professional fitness trainers
- Detailed trainer profiles with ratings and reviews
- Book personalized training sessions

### 🏋️ Gym Workouts
- Comprehensive exercise library organized by muscle group:
  - **Chest**, **Back**, **Arms**, **Legs**, **Shoulders**, and **Core**
- Exercise detail pages with guides and instructions

### 🧘 Yoga & Challenges
- Yoga courses, instructor classes, and schedules
- Motivational yoga content and course cards
- **Weekly fitness challenges** with landing pages, details, and success tracking

### 📅 Appointment Booking
- Book appointments with trainers
- Booking confirmation and booking history management
- Appointment reminders via push notifications

### 💳 Payments
- Secure in-app payments powered by **Stripe**
- Add, edit, and manage saved payment cards
- Payment flows for bookings and yoga sessions

### 📞 Video Calls
- Live video calling between users and trainers powered by **Agora**
- Incoming/outgoing call pages with full-screen call UI
- CallKit integration for background/locked/killed device states
- Ringtone and call notification handling

### 🔔 Notifications
- **Firebase Cloud Messaging (FCM)** for push notifications
- Incoming call notifications with CallKit full-screen takeover
- Appointment reminder banners
- Local notifications support

### 👤 User Account
- Full authentication flow (register, login, forgot password, OTP verification, new password)
- User profile management
- In-app settings, password management, privacy policy, and help/FAQ
- AI assistant chat within settings

### 📰 Community
- Newsfeed with posts and detail views
- Reviews and ratings system
- Favorites tracking

### 🏃 Activity Tracking
- Runner module with activity tracking and history
- Calorie, steps, and clock tracking widgets

---

## 🛠️ Tech Stack

| Category          | Technology |
|-------------------|------------|
| **Framework**     | Flutter / Dart |
| **Backend / DB**  | Supabase (PostgreSQL, Auth, Realtime) |
| **Payments**      | Stripe (`flutter_stripe`) |
| **Video Calls**   | Agora (`agora_rtc_engine`) |
| **Push Notifications** | Firebase Cloud Messaging |
| **Call Handling** | `flutter_callkit_incoming` |
| **Local Notifications** | `flutter_local_notifications` + `timezone` |
| **State / Env**   | `flutter_dotenv`, `shared_preferences` |
| **Media**        | `image_picker`, `video_player`, `audioplayers` |
| **Documents**    | `pdf`, `share_plus`, `path_provider` |
| **UI**           | `flutter_svg`, `pin_code_fields`, `vertical_card_pager`, `animated_weight_picker`, `omni_datetime_picker`, `payment_card` |

---

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point (init, FCM, Stripe, Supabase)
├── Domain/
│   └── models/               # Data models (e.g., onboarding)
├── Presentation/
│   ├── pages/                # All UI screens
│   │   ├── auth/             # Login, register, verification, password flows
│   │   ├── booking/          # Appointment booking & history
│   │   ├── call/             # Incoming/outgoing/video call pages
│   │   ├── fitnes_trainer/   # Trainer listings & details
│   │   ├── gym/              # Gym exercises by muscle group
│   │   ├── home/             # Home dashboard
│   │   ├── launch/           # Launch/splash screen
│   │   ├── newsfeed/         # Community posts
│   │   ├── onboarding/       # Getting started screens
│   │   ├── payment/          # Stripe payment & cards
│   │   ├── review/           # Reviews & ratings
│   │   ├── runner/           # Activity tracking
│   │   ├── setting/          # Profile, settings, help, assistant
│   │   ├── setup/            # Setup flow
│   │   └── yoga/             # Yoga courses & challenges
│   └── widgets/              # Reusable UI components
├── Services/                 # Business logic & integrations
│   ├── agora_service.dart    # Agora video call engine
│   ├── call_service.dart     # Call management & Supabase realtime
│   ├── supabase_service.dart # Supabase client & FCM token
│   ├── notification_service.dart   # FCM & local notifications
│   ├── call_notification_service.dart
│   └── appointment_notification_service.dart
└── Utils/
    └── constants.dart        # Theme, app-wide constants
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (≥ 3.3.1)
- A configured `flutter` development environment
- Supabase project (URL + anon key)
- Stripe account (publishable key)
- Firebase project (for FCM)
- Agora project (App ID)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/AAbdullahRajput/Get-Fit-Mobile-Application-User-.git
   cd Get-Fit-Mobile-Application-User-
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Create a `.env` file in the project root with your keys:
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
   ```

4. **Set up Firebase**
   - Add your platform-specific `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) files
   - Enable Firebase Cloud Messaging for push notifications

5. **Run the app**
   ```bash
   flutter run
   ```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

---

## ⚙️ App Icon

The app icon is configured via `flutter_launcher_icons`:
```bash
dart run flutter_launcher_icons
```
- **Source image:** `assets/icons/app_icon.png`
- Configured for both **Android** and **iOS**

---

## 📦 Dependencies Overview

Key packages used in this project:

- `supabase_flutter` — Backend, auth, and realtime database
- `flutter_stripe` — Payment processing
- `agora_rtc_engine` — Video calling
- `firebase_core` / `firebase_messaging` — Push notifications
- `flutter_callkit_incoming` — Native call handling (CallKit)
- `flutter_local_notifications` — Local notifications
- `flutter_dotenv` — Environment configuration
- `shared_preferences` — Local persistence
- `image_picker` — Media selection
- `video_player` / `audioplayers` — Audio & video playback
- `pdf` / `share_plus` — Document generation & sharing

---

## 📄 License

This project is **private** and proprietary to the repository owner. Unauthorized copying, distribution, or use is prohibited.

---

## 👤 Author

**AAbdullahRajput**

- GitHub: [@AAbdullahRajput](https://github.com/AAbdullahRajput)

---

Made with 💙 using Flutter
