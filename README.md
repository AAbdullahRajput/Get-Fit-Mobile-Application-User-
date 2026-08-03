# 💪 Get Fit

A comprehensive fitness & wellness mobile application built with **Flutter**. Get Fit brings gym workouts, yoga classes, personal trainers, video calls, and more into a single, modern cross-platform app with a dark & light theme.

---

## ✨ Features

### 🧘 Wellness & Fitness
- **Gym Exercises** — Browse structured workout routines by category (Arms, Back, Chest, Core, Legs, Shoulders) with step-by-step exercise details, sets, reps, and rest guidance.
- **Per-Set Workout Logging** — Track each set, reps completed, duration, and calories burned; record daily gym activity.
- **Yoga Classes** — Explore yoga courses, view class steps, and follow instructor-led sessions.
- **Instructor Paid Classes** — Purchase premium yoga/instructor classes and access them from your library.
- **Weekly Challenges** — Personalized weekly fitness challenges based on your goal (e.g., Lose Weight, Build Muscle, Stay Fit) with daily rounds and exercises.
- **Streak Tracking** — Maintains and tracks your current and longest workout streaks.

### 🏋️ Personal Trainers
- **Trainer Directory** — Browse and search fitness trainers sorted by rating.
- **Trainer Details** — View experience, training type, reviews, and ratings.
- **Appointment Booking** — Book trainer sessions through a slot-based calendar system (with weekly templates and virtual slots).
- **Reviews & Ratings** — Write, edit, and delete reviews; vote "helpful" on other users' reviews.
- **Video Calls** — 1-on-1 video calls with your trainer powered by **Agora RTC**, with incoming/outgoing call UI, mute, camera toggle, and camera switching.

### 🏃 Activity & Progress
- **Activity Stats** — Visual charts of calories and workout time across challenge, gym, and yoga activities (7/30/90-day views).
- **Workout History** — Full daily breakdown of challenge rounds, gym sessions, and yoga classes.
- **PDF Export** — Download your activity history and bookings as PDF documents.
- **Saved Favorites** — Bookmark your favorite exercises for quick access.

### 💳 Payments
- **Secure Payments** — Integrated with **Stripe** for booking trainers and purchasing classes.
- **Saved Cards** — Add, edit, and delete payment cards (uses Stripe Payment Methods).
- **Payment Intents** — Server-side payment intent creation via Supabase Edge Functions.

### 📰 Newsfeed
- **Newsfeed** — Browse fitness articles and news with category filtering and search.
- **Saved Items** — Save newsfeed articles to revisit later.

### 👤 User Account
- **Authentication** — Email/password signup, login, email verification (OTP), password reset, and new password setup.
- **Profile & Setup** — Personal onboarding profile (weight, age, height, goal) and editable profile with avatar upload.
- **Settings** — Theme toggle (dark/light), notification preferences, privacy, help & FAQ, and password management.
- **Account Management** — Accept terms, delete account (with server-side cleanup).

### 🔔 Notifications
- **Local Notifications** — Customizable notification preferences (general, sound, vibrate, DND, reminders).
- **Appointment Reminders** — Automatic notifications 1 day, 2 hours, and 5 minutes before a trainer session.
- **Data Retention Reminders** — Reminds you before your oldest activity/booking history is cleared.

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter (Dart) |
| **Backend / Database** | Supabase (PostgreSQL, Auth, Realtime, Storage) |
| **Video Calls** | Agora RTC Engine |
| **Payments** | Stripe (via `flutter_stripe`) |
| **Edge Functions** | Supabase Edge Functions (Deno/TypeScript) |
| **Local Storage** | SharedPreferences |
| **State Management** | Native Flutter (`ValueNotifier`, `ChangeNotifier`) |
| **PDF** | `pdf` + `share_plus` |

---

## 📂 Project Structure

```
get_fit/
├── android/                       # Android platform config & Gradle
├── ios/                           # iOS platform config
├── lib/
│   ├── main.dart                  # App entry point (Supabase, Stripe, notifications init)
│   ├── Domain/
│   │   └── models/                # Data models (e.g., onboarding)
│   ├── Presentation/
│   │   ├── pages/                 # All screens
│   │   │   ├── auth/              # Login, register, verification, password reset
│   │   │   ├── booking/           # Appointment booking & confirmation
│   │   │   ├── call/              # Incoming/outgoing/video call screens
│   │   │   ├── fitnes_trainer/    # Trainer directory & details
│   │   │   ├── gym/               # Gym exercises (by body part)
│   │   │   ├── home/              # Home dashboard
│   │   │   ├── launch/            # Splash/launch screen
│   │   │   ├── newsfeed/          # Newsfeed & detail
│   │   │   ├── onboarding/        # Onboarding flow
│   │   │   ├── payment/           # Payment & card management
│   │   │   ├── review/            # Trainer reviews
│   │   │   ├── runner/            # Activity stats & history
│   │   │   ├── setting/           # Profile, notifications, help, privacy
│   │   │   ├── setup/             # User setup/profile
│   │   │   └── yoga/              # Yoga classes, challenges, booking
│   │   └── widgets/               # Reusable UI components
│   ├── Services/                  # Business logic & API layers
│   │   ├── supabase_service.dart  # All Supabase queries & mutations
│   │   ├── call_service.dart      # Call signaling (Supabase Realtime)
│   │   ├── agora_service.dart     # Agora video engine wrapper
│   │   ├── notification_service.dart # Local notifications & reminders
│   │   └── beep_service.dart      # Synthesized call ringtones/beeps
│   └── Utils/
│       └── constants.dart         # Themes, colors, helpers
├── supabase/
│   └── functions/                 # Supabase Edge Functions
│       ├── create-payment-intent/ # Stripe payment intent creation
│       ├── attach-payment-method/ # Attach Stripe payment method
│       ├── generate-agora-token/  # Agora RTC token generation
│       └── fetch-newsfeed/        # Newsfeed fetching
├── assets/                        # Images, icons, onboarding assets
├── pubspec.yaml                   # Dependencies & assets config
└── .env                           # Environment variables (API keys)
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** (3.x, Dart 3.3+)
- **Android Studio** / Xcode (for iOS)
- **Java 17+** (for Android Gradle)
- A **Supabase** project
- An **Agora** account (App ID + Certificate)
- A **Stripe** account (publishable + secret keys)

### 1. Clone & Install Dependencies
```bash
git clone <your-repo-url>
cd get_fit
flutter pub get
```

### 2. Configure Environment Variables
Create a `.env` file in the project root with your keys:
```env
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
AGORA_APP_ID=your_agora_app_id
```

### 3. Configure Supabase Edge Functions
Set the following secrets in your Supabase project:
```bash
supabase secrets set SUPABASE_URL=...
supabase secrets set SUPABASE_ANON_KEY=...
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=...
supabase secrets set STRIPE_SECRET_KEY=...
supabase secrets set AGORA_APP_ID=...
supabase secrets set AGORA_APP_CERTIFICATE=...
```

Deploy the functions:
```bash
supabase functions deploy create-payment-intent
supabase functions deploy attach-payment-method
supabase functions deploy generate-agora-token
supabase functions deploy fetch-newsfeed
```

### 4. Run the App
```bash
flutter run
```

---

## 📱 Build & Release

### Android App Bundle (for Google Play)
```bash
flutter build appbundle
```
The output AAB is generated at:
```
build/app/outputs/bundle/release/app-release.aab
```

### Android APK
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ipa
```

### Release Signing
The Android release build uses `android/key.properties` for signing. Ensure it contains:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=your_key_alias
storeFile=path/to/your/keystore.jks
```

---

## 🗄️ Key Supabase Tables

The app interacts with the following tables (via `SupabaseService`):

- `users` — user profiles & auth metadata
- `user_setup` — fitness goals, weight, age, height, streaks
- `gym_exercises` — gym exercise catalog
- `gym_exercise_steps` — step-by-step exercise instructions
- `gym_workout_logs` — per-set workout logging
- `workout_sessions` — workout session summaries
- `fitness_trainers` — trainer profiles
- `trainer_slots` — trainer appointment slots/calendar
- `trainer_appointments` — booked appointments
- `trainer_reviews` — reviews & ratings
- `review_helpful_votes` — helpful votes on reviews
- `yoga_classes` — yoga class catalog
- `yoga_class_steps` — yoga class steps
- `instructor_paid_classes` — premium paid classes
- `instructor_class_steps` — paid class steps
- `instructor_class_logs` — completed instructor class sessions
- `user_class_purchases` — purchased classes
- `user_feed_classes` — user's saved feed classes
- `weekly_challenges` — weekly challenge definitions
- `challenge_days` — challenge daily plans
- `challenge_rounds` — challenge rounds per day
- `challenge_exercises` — exercises per round
- `challenge_user_progress` — user challenge exercise progress
- `favorites` — saved favorite exercises
- `user_cards` — saved payment cards
- `call_sessions` — video call session records
- `newsfeed_items` — newsfeed articles
- `saved_newsfeed_items` — saved newsfeed articles

---

## 🔧 Troubleshooting

### Build fails with "Could not read workspace metadata"
This is a **corrupted Gradle cache** issue (common on Windows). Fix it by clearing the cache:
```bash
cd android
.\gradlew.bat --stop
Remove-Item -Recurse -Force "$env:USERPROFILE\.gradle\caches"
cd ..
flutter build appbundle
```

### "Release app bundle failed to strip debug symbols"
This is caused by conflicting `packagingOptions { doNotStrip "**/*.so" }` in `android/app/build.gradle`. Remove that block — the release build type already handles stripping via `ndk { debugSymbolLevel 'none' }`.

### Video calls not working
- Ensure your Agora App ID and App Certificate are correctly set in `.env` and Supabase secrets.
- Verify the `generate-agora-token` Edge Function is deployed.
- Grant camera & microphone permissions on your device.

---

## 📄 License

This project is for demonstration/development purposes. All assets, icons, and third-party services are owned by their respective authors.

---

