<div align="center">

# 🏋️ Get Fit

### Your Complete Fitness & Wellness Companion

*Connect with professional trainers. Train smarter. Live healthier.*

[![Flutter](https://img.shields.io/badge/Flutter-3.3.1-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A53.3.1-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)](https://supabase.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)](#)
[![License](https://img.shields.io/badge/License-Private-red?style=for-the-badge)](#)

[Features](#-features) • [Tech Stack](#%EF%B8%8F-tech-stack) • [Getting Started](#-getting-started) • [Project Structure](#-project-structure) • [Author](#-author)

</div>

---

## 📖 Overview

**Get Fit** is a full-featured fitness and wellness mobile application built with **Flutter**. It bridges the gap between users and professional fitness trainers — offering guided gym and yoga workouts, weekly fitness challenges, live video coaching, and seamless appointment booking, all wrapped in a polished, modern experience.

Whether you're booking a one-on-one session, following a structured gym program, or joining a live video call with your trainer, Get Fit brings the personal training studio to your pocket.

---

## ✨ Features

### 🏠 Home & Onboarding
- Elegant 3-screen onboarding flow for new users
- Modern home dashboard with quick-access shortcuts and motivational content
- Animated launch/splash experience

### 💪 Fitness Trainers
- Discover and browse verified professional trainers
- Detailed trainer profiles with ratings and reviews
- Book personalized 1-on-1 training sessions

### 🏋️ Gym Workouts
- Exercise library organized by muscle group — **Chest · Back · Arms · Legs · Shoulders · Core**
- Step-by-step exercise detail pages with guided instructions

### 🧘 Yoga & Challenges
- Yoga courses, instructor-led classes, and flexible scheduling
- Motivational content and curated course cards
- **Weekly fitness challenges** with landing pages, progress tracking, and success milestones

### 📅 Appointment Booking
- Effortless trainer appointment booking
- Booking confirmations and full booking history
- Smart push notification reminders

### 💳 Payments
- Secure, PCI-compliant payments powered by **Stripe**
- Save, edit, and manage payment cards
- Streamlined checkout for bookings and yoga sessions

### 📞 Live Video Calls
- Real-time video calling between users and trainers via **Agora**
- Full-screen incoming/outgoing call UI
- **CallKit** integration — works in background, locked, or killed app states
- Native ringtone and call notification handling

### 🔔 Notifications
- **Firebase Cloud Messaging (FCM)** push notifications
- Full-screen CallKit takeover for incoming calls
- Appointment reminder banners and local notifications

### 👤 User Account
- Complete auth flow — register, login, forgot password, OTP verification
- Editable user profiles
- In-app settings, privacy policy, and help/FAQ center
- Built-in AI assistant chat

### 📰 Community
- Social newsfeed with posts and detail views
- Ratings & reviews system
- Favorites and bookmarking

### 🏃 Activity Tracking
- Runner module with live activity tracking and history
- Calorie, step count, and workout clock widgets

---

## 🛠️ Tech Stack

| Category | Technology |
|---|---|
| **Framework** | Flutter / Dart |
| **Backend & Database** | Supabase (PostgreSQL, Auth, Realtime) |
| **Payments** | Stripe (`flutter_stripe`) |
| **Video Calls** | Agora (`agora_rtc_engine`) |
| **Push Notifications** | Firebase Cloud Messaging |
| **Call Handling** | `flutter_callkit_incoming` |
| **Local Notifications** | `flutter_local_notifications` + `timezone` |
| **State / Env** | `flutter_dotenv`, `shared_preferences` |
| **Media** | `image_picker`, `video_player`, `audioplayers` |
| **Documents** | `pdf`, `share_plus`, `path_provider` |
| **UI Components** | `flutter_svg`, `pin_code_fields`, `vertical_card_pager`, `animated_weight_picker`, `omni_datetime_picker`, `payment_card` |

---

## 📁 Project Structure

```
lib/
├── main.dart                       # App entry point (init, FCM, Stripe, Supabase)
│
├── Domain/
│   └── models/                     # Data models (e.g., onboarding)
│
├── Presentation/
│   ├── pages/                      # All UI screens
│   │   ├── auth/                   # Login, register, verification, password flows
│   │   ├── booking/                # Appointment booking & history
│   │   ├── call/                   # Incoming / outgoing / video call pages
│   │   ├── fitnes_trainer/         # Trainer listings & details
│   │   ├── gym/                    # Gym exercises by muscle group
│   │   ├── home/                   # Home dashboard
│   │   ├── launch/                 # Launch / splash screen
│   │   ├── newsfeed/               # Community posts
│   │   ├── onboarding/             # Getting started screens
│   │   ├── payment/                # Stripe payment & saved cards
│   │   ├── review/                 # Reviews & ratings
│   │   ├── runner/                 # Activity tracking
│   │   ├── setting/                # Profile, settings, help, assistant
│   │   ├── setup/                  # Setup flow
│   │   └── yoga/                   # Yoga courses & challenges
│   └── widgets/                    # Reusable UI components
│
├── Services/                       # Business logic & integrations
│   ├── agora_service.dart          # Agora video call engine
│   ├── call_service.dart           # Call management & Supabase realtime
│   ├── supabase_service.dart       # Supabase client & FCM token
│   ├── notification_service.dart   # FCM & local notifications
│   ├── call_notification_service.dart
│   └── appointment_notification_service.dart
│
└── Utils/
    └── constants.dart              # Theme & app-wide constants
```

---

## 🚀 Getting Started

### Prerequisites

Make sure you have the following set up before installing:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) `≥ 3.3.1`
- A configured Flutter development environment
- A [Supabase](https://supabase.com) project (URL + anon key)
- A [Stripe](https://stripe.com) account (publishable key)
- A [Firebase](https://firebase.google.com) project (for FCM)
- An [Agora](https://www.agora.io) project (App ID)

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/AAbdullahRajput/Get-Fit-Mobile-Application-User-.git
cd Get-Fit-Mobile-Application-User-
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Configure environment variables**

Create a `.env` file in the project root:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
```

**4. Set up Firebase**
- Add `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS)
- Enable Firebase Cloud Messaging for push notifications

**5. Run the app**
```bash
flutter run
```

### Build for Release

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

App icons are generated via `flutter_launcher_icons`:

```bash
dart run flutter_launcher_icons
```

- **Source image:** `assets/icons/app_icon.png`
- Configured for both **Android** and **iOS**

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| `supabase_flutter` | Backend, auth, and realtime database |
| `flutter_stripe` | Payment processing |
| `agora_rtc_engine` | Video calling |
| `firebase_core` / `firebase_messaging` | Push notifications |
| `flutter_callkit_incoming` | Native call handling (CallKit) |
| `flutter_local_notifications` | Local notifications |
| `flutter_dotenv` | Environment configuration |
| `shared_preferences` | Local persistence |
| `image_picker` | Media selection |
| `video_player` / `audioplayers` | Audio & video playback |
| `pdf` / `share_plus` | Document generation & sharing |

---

## 🗺️ Roadmap

- [ ] Wearable device integration (steps, heart rate sync)
- [ ] In-app group challenges & leaderboards
- [ ] Trainer availability calendar sync
- [ ] Offline workout mode

---

## 📄 License

This project is **private and proprietary** to the repository owner. Unauthorized copying, distribution, or use is strictly prohibited.

---

## 👤 Author

<div align="center">

**Ahmad Abdullah** (AAbdullahRajput)

[![GitHub](https://img.shields.io/badge/GitHub-AAbdullahRajput-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/AAbdullahRajput)

Made with 💙 using Flutter

</div>
