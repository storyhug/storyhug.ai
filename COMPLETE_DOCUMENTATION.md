# 📚 StoryHug - Complete Documentation

<div align="center">
  <img src="assets/branding/storyhug_logo.png" alt="StoryHug Logo" width="200"/>
  
  **Your stories, in their voice. Sweet dreams every night.**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.16.0-blue.svg)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.2.0-blue.svg)](https://dart.dev/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/)
</div>

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Key Features](#key-features)
3. [Installation & Setup](#installation--setup)
4. [Branding & UI](#branding--ui)
5. [Database Schema](#database-schema)
6. [Features Implementation](#features-implementation)
7. [Testing Guide](#testing-guide)
8. [Deployment](#deployment)
9. [Troubleshooting](#troubleshooting)

---

## 🌟 Overview

StoryHug is a revolutionary mobile application that transforms bedtime storytelling by allowing parents to create personalized voice models for their children. Using advanced AI voice cloning technology, parents can record their voice once and have it narrate unlimited stories, creating a magical and personalized experience for their little ones.

**App Name:** StoryHug  
**Package:** com.storyhug.ai  
**Version:** 1.0.0  
**Platform:** Android & iOS  
**Framework:** Flutter 3.16.0  

---

## ✨ Key Features

### 🎤 Voice Cloning Technology
- **Multi-Voice Management**: Store multiple family member voices (Mom, Dad, Grandma, etc.)
- **One-Time Recording**: Record voice once (15 seconds minimum)
- **AI-Powered Cloning**: Advanced ElevenLabs integration
- **Natural Storytelling**: Your voice narrates every story
- **Quality Validation**: Automatic audio quality checks
- **Voice Diagnostics**: Real-time audio analysis

### 📚 Rich Story Library
- **Unlimited Stories**: Access to thousands of stories
- **Age-Appropriate Content**: Stories categorized by age groups (3-5, 6-8, 9-12)
- **Multiple Categories**: Moral stories, Indian mythology, adventures, fairy tales
- **Favorites System**: Save and organize favorite stories
- **Real-Time Sync**: Favorites sync across all screens
- **Search & Filter**: Advanced story discovery

### 🎵 Professional Audio Player
- **Full Controls**: Play, pause, skip, repeat, sleep timer
- **Voice Selection**: Toggle between different family voices
- **Background Playback**: Continue listening while using other apps
- **Offline Support**: Download stories for offline listening
- **Music Integration**: Ambient music library support

### 👶 Child Profile Management
- **Multiple Children**: Create profiles for each child
- **Age-Based Content**: Stories filtered by child's age
- **Progress Tracking**: Monitor listening history and preferences
- **Personalized Experience**: Customized content for each child
- **Avatar Customization**: Colorful avatars for each profile

### 💳 Premium Subscription
- **Freemium Model**: Free stories with premium upgrades
- **Unlimited Access**: Premium subscribers get unlimited stories
- **Voice Cloning**: Premium feature for personalized voices
- **Offline Downloads**: Download stories for offline listening
- **Ad-Free Experience**: No interruptions during storytelling

### 📊 Parental Dashboard
- **Dynamic Statistics**: Real-time data on listening habits
- **Stories Listened**: Track completed stories
- **Listening Time**: Monitor total listening duration
- **Favorite Category**: Quick access to favorited stories
- **Active Children**: Manage child profiles
- **My Voices**: Manage recorded family voices
- **Analytics**: Detailed insights with charts
- **Quick Actions**: Easy access to all app features

### 🔒 Security & Compliance
- **Voice Consent Management**: COPPA/GDPR compliant
- **Data Retention Policies**: Automated data cleanup
- **Content Safety Filter**: AI-powered inappropriate content detection
- **Privacy Policy**: Comprehensive privacy documentation
- **Secure Authentication**: Supabase auth with Google/Apple sign-in
- **Account Deletion**: Permanent data erasure on request

---

## 🚀 Installation & Setup

### Prerequisites
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode for mobile development
- Supabase account for backend services
- ElevenLabs API key for voice cloning

### Quick Install

#### Option 1: Install Pre-Built APK (Android)

```bash
# Navigate to project directory
cd /Users/DK19/Downloads/StoryHug

# Uninstall old version (if exists)
adb uninstall com.storyhug.ai

# Install new version
adb install build/app/outputs/flutter-apk/StoryHug-release.apk
```

**APK Details:**
- **File:** `StoryHug-release.apk`
- **Size:** ~59 MB
- **Package:** com.storyhug.ai
- **App Name:** StoryHug

#### Option 2: Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/storyhug.git
cd storyhug

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build release APK
flutter build apk --release
```

### Environment Configuration

1. **Create environment file:**
   ```bash
   cp lib/config/environment.example.dart lib/config/environment.dart
   ```

2. **Add your API keys:**
   ```dart
   class Environment {
     static const String supabaseUrl = 'YOUR_SUPABASE_URL';
     static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
     static const String elevenLabsApiKey = 'YOUR_ELEVENLABS_API_KEY';
   }
   ```

3. **Set up Supabase:**
   - Create a new Supabase project
   - Run the database schema (see `COMPLETE_DATABASE_SCHEMA.sql`)
   - Configure authentication providers
   - Set up storage buckets

---

## 🎨 Branding & UI

### Brand Identity

**App Name:** StoryHug  
**Tagline:** Your stories, in their voice  

**Brand Colors:**
```
Primary Yellow:    #FFD85A
Secondary Pink:    #FF8CB3
Background Start:  #FCE4EC (light pink)
Background End:    #E3F2FD (light blue)
Icon Background:   #F7CFEA (pink tint)
Splash Gradient:   #5BA5C1 → #2C5F7A (blue)
Text Primary:      White
Text Secondary:    White70 (70% opacity)
```

### Logo Implementation

#### Splash Screen
- **Format:** Circular with frosted glass effect
- **Size:** 160dp diameter circle
- **Logo Size:** 120dp (75% of circle)
- **Padding:** 20dp breathing room
- **Background:** Blue gradient (#5BA5C1 → #2C5F7A)
- **Effect:** Frosted glass (40% white opacity)
- **Border:** 2dp white at 30% opacity
- **Shadow:** 16dp blur, 8dp offset
- **Animation:** Scale-up (0.8 → 1.0) + Fade-in over 1.5s

#### Logo Locations
1. ✅ **Splash/Launch Screen** (200x200 circular, animated)
2. ✅ **Welcome Page** (200x200, top center)
3. ✅ **Login/Signup** (120x120, above form)
4. ✅ **Home Header** (40x40, navigation bar)
5. ✅ **Settings Page** (80x80, page header)
6. ✅ **App Icon** (all densities)

#### App Icon Files
```
Android:
├── mipmap-mdpi/ic_launcher.png (48x48)
├── mipmap-hdpi/ic_launcher.png (72x72)
├── mipmap-xhdpi/ic_launcher.png (96x96)
├── mipmap-xxhdpi/ic_launcher.png (144x144)
└── mipmap-xxxhdpi/ic_launcher.png (192x192)

iOS:
└── AppIcon.appiconset/ (all required sizes)
```

### Theme Configuration

**Gradient Backgrounds:**
```dart
static const LinearGradient backgroundGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFCE4EC), // Light pink
    Color(0xFFE3F2FD), // Light blue
  ],
);
```

**Border Radius Hierarchy:**
```
Extra Large:  20dp (Splash, Welcome)
Large:        16dp (Auth pages)
Medium:       12dp (Settings)
Small:        8dp (Toolbar)
```

---

## 🗄️ Database Schema

The complete database schema is available in `COMPLETE_DATABASE_SCHEMA.sql`.

### Key Tables

#### 1. user_voices
Stores multiple recorded voices per user.
```sql
CREATE TABLE user_voices (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  voice_id TEXT NOT NULL,
  voice_name TEXT NOT NULL,
  voice_description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 2. favorite_stories
Tracks user's favorite stories.
```sql
CREATE TABLE favorite_stories (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  story_id TEXT NOT NULL,
  story_title TEXT,
  added_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, story_id)
);
```

#### 3. profiles (Child Profiles)
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id),
  child_name TEXT NOT NULL,
  age_bucket INTEGER NOT NULL,
  avatar_url TEXT,
  nickname TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

#### 4. stories
```sql
CREATE TABLE stories (
  id UUID PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  category TEXT NOT NULL,
  min_age INTEGER NOT NULL,
  max_age INTEGER NOT NULL,
  audio_default_url TEXT NOT NULL,
  duration_minutes INTEGER DEFAULT 5,
  thumbnail_url TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Database Functions

**Favorites Management:**
- `is_story_favorited(user_uuid, story_uuid)` - Check if story is favorited
- `toggle_favorite_story(user_uuid, story_uuid, story_title)` - Add/remove favorite
- `get_favorites_count(user_uuid)` - Get count of favorited stories
- `get_favorite_stories(user_uuid)` - Fetch all favorite stories

**Voice Management:**
- `get_user_voices(user_uuid)` - Fetch all active voices for user

**Dashboard Analytics:**
- `get_stories_listened_count(user_uuid)` - Get stories listened count
- `get_listening_time(user_uuid)` - Get total listening time
- `get_active_children_count(user_uuid)` - Get active children count

---

## ⚙️ Features Implementation

### Favorites System

**Implementation:**
1. Heart icon on each story card
2. Real-time state synchronization using Riverpod
3. Persistent storage in Supabase
4. Dynamic count in Parental Dashboard
5. Favorites detail page with all favorited stories

**Files:**
- `lib/features/stories/services/favorites_service.dart`
- `lib/features/stories/providers/favorites_provider.dart`
- `lib/features/stories/widgets/animated_favorite_button.dart`
- `lib/features/dashboard/pages/favorites_detail_page.dart`

**Usage:**
```dart
// Add to favorites
await favoritesService.addFavorite(storyId, storyTitle);

// Remove from favorites
await favoritesService.removeFavorite(storyId);

// Toggle favorite
await favoritesService.toggleFavorite(storyId, storyTitle);

// Check if favorited
bool isFavorited = await favoritesService.isFavorited(storyId);
```

### Voice Cloning

**Implementation:**
1. Multi-voice management (Mom, Dad, Grandma, etc.)
2. ElevenLabs API integration
3. Audio quality validation
4. Voice diagnostics
5. Custom voice names

**Files:**
- `lib/features/voice_cloning/services/voice_cloning_service.dart`
- `lib/features/voice_cloning/pages/voice_cloning_page.dart`
- `lib/features/voice_cloning/pages/voice_diagnostics_page.dart`

**Key Features:**
- Record voice (15 seconds minimum)
- Automatic quality check
- Clone voice using ElevenLabs
- Manage multiple voices per user
- Delete voices

### Parental Dashboard

**Implementation:**
1. Real-time statistics
2. Dynamic data fetching
3. Interactive cards
4. Detail pages for each metric
5. Shimmer loading states

**Files:**
- `lib/features/dashboard/pages/enhanced_parental_dashboard.dart`
- `lib/features/dashboard/services/dashboard_analytics_service.dart`
- `lib/features/dashboard/providers/dashboard_providers.dart`

**Features:**
- Stories listened count
- Listening time tracking
- Favorites count
- Active children count
- My Voices management
- Logout and account deletion

### Authentication

**Providers:**
- Email/Password
- Google Sign-In
- Apple Sign-In

**Features:**
- Secure session management
- Password reset
- Email verification
- Automatic session persistence

**Files:**
- `lib/features/auth/services/auth_service.dart`
- `lib/features/auth/pages/auth_page.dart`
- `lib/features/auth/pages/welcome_page.dart`

---

## 🧪 Testing Guide

### Running Tests

```bash
# Unit tests
flutter test

# Widget tests
flutter test test/widget_test.dart

# Integration tests
flutter test integration_test/

# Test coverage
flutter test --coverage
```

### Test Favorites System

1. **Add to Favorites:**
   - Browse stories
   - Tap heart icon
   - Verify icon turns red
   - Check Parental Dashboard favorites count increases

2. **Remove from Favorites:**
   - Tap red heart icon
   - Verify icon turns white
   - Check favorites count decreases

3. **Favorites Detail Page:**
   - Navigate to Parental Dashboard
   - Tap "Favorite Category" card
   - Verify all favorited stories appear
   - Remove a story
   - Verify real-time update

### Test Voice Cloning

1. **Record Voice:**
   - Go to Voice Cloning page
   - Tap "Record Voice"
   - Record for 15+ seconds
   - Save with custom name

2. **Manage Voices:**
   - View all recorded voices
   - Edit voice name/description
   - Delete voice
   - Verify updates in dashboard

### Test Dashboard

1. **View Statistics:**
   - Open Parental Dashboard
   - Verify all cards show correct data
   - Tap each card to view details

2. **Logout:**
   - Tap menu icon
   - Select "Logout"
   - Verify redirect to login

3. **Delete Account:**
   - Tap menu icon
   - Select "Delete Account"
   - Confirm deletion
   - Verify all data removed

---

## 🚀 Deployment

### Android Build

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Output location:
# build/app/outputs/flutter-apk/app-release.apk

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS Build

```bash
# Build iOS app
flutter build ios --release

# Archive for App Store
flutter build ipa --release

# Output location:
# build/ios/ipa/
```

### App Signing

**Android:**
1. Create keystore
2. Configure `android/key.properties`
3. Update `android/app/build.gradle`

**iOS:**
1. Configure signing in Xcode
2. Create distribution certificate
3. Create provisioning profile

### Play Store Submission

1. Build App Bundle
2. Create Play Store listing
3. Upload screenshots
4. Set pricing and distribution
5. Submit for review

### App Store Submission

1. Build IPA
2. Upload to App Store Connect
3. Create App Store listing
4. Add screenshots
5. Submit for review

---

## 🔧 Troubleshooting

### Installation Issues

**Problem:** APK not installing
**Solution:**
```bash
# Uninstall old version
adb uninstall com.storyhug.ai

# Clear ADB cache
adb kill-server
adb start-server

# Reinstall
adb install StoryHug-release.apk
```

**Problem:** Logo not showing on splash screen
**Solution:**
1. Uninstall app completely
2. Restart device (clears Android icon cache)
3. Reinstall from new APK

**Problem:** Favorites not syncing
**Solution:**
1. Check internet connection
2. Verify Supabase credentials
3. Check RLS policies are enabled
4. Clear app data and re-login

### Build Issues

**Problem:** Flutter build fails
**Solution:**
```bash
flutter clean
flutter pub get
flutter pub upgrade
flutter build apk --release
```

**Problem:** Gradle build fails
**Solution:**
```bash
cd android
./gradlew clean
./gradlew build
cd ..
```

### Runtime Issues

**Problem:** Voice cloning fails
**Solution:**
1. Check ElevenLabs API key
2. Verify internet connection
3. Check audio recording permissions
4. Ensure minimum 15 seconds recording

**Problem:** Stories not loading
**Solution:**
1. Check Supabase connection
2. Verify story data exists
3. Check internet connection
4. Clear app cache

### Database Issues

**Problem:** Favorites not saving
**Solution:**
1. Run `COMPLETE_DATABASE_SCHEMA.sql`
2. Verify `favorite_stories` table exists
3. Check RLS policies enabled
4. Verify user authentication

**Problem:** Voice data not saving
**Solution:**
1. Verify `user_voices` table exists
2. Check unique constraint on voice_name
3. Ensure user is authenticated
4. Check Supabase logs

---

## 📊 Performance Optimization

### Best Practices

1. **Image Optimization:**
   - Use cached network images
   - Compress thumbnails
   - Lazy load images

2. **State Management:**
   - Use Riverpod for efficient state updates
   - Minimize rebuilds
   - Use const constructors

3. **Database Queries:**
   - Use indexed columns
   - Limit query results
   - Cache frequent queries

4. **Audio Playback:**
   - Preload next story
   - Use efficient codecs
   - Implement proper disposal

### Performance Metrics

- **App Startup:** < 3 seconds
- **Memory Usage:** < 100MB
- **Splash Screen:** 2 seconds
- **Story Load:** < 1 second
- **Voice Clone:** 5-10 seconds

---

## 📱 App Architecture

### Project Structure

```
lib/
├── core/
│   ├── theme/                    # App theme and branding
│   │   ├── app_theme.dart
│   │   └── storyhug_branding.dart
│   ├── router/                   # Navigation
│   │   └── app_router.dart
│   └── services/                 # Core services
│       ├── supabase_service.dart
│       ├── slogan_service.dart
│       └── various safety/UX services
├── features/
│   ├── auth/                     # Authentication
│   ├── profiles/                 # Child profiles
│   ├── stories/                  # Story management
│   │   ├── services/
│   │   │   ├── favorites_service.dart
│   │   │   └── story_service.dart
│   │   ├── providers/
│   │   │   ├── favorites_provider.dart
│   │   │   └── story_provider.dart
│   │   └── pages/
│   │       ├── home_page.dart
│   │       └── search_page.dart
│   ├── player/                   # Audio player
│   ├── voice_cloning/            # Voice recording & cloning
│   ├── subscription/             # Premium features
│   ├── dashboard/                # Parental dashboard
│   │   ├── pages/
│   │   │   ├── enhanced_parental_dashboard.dart
│   │   │   ├── favorites_detail_page.dart
│   │   │   └── stories_detail_page.dart
│   │   ├── services/
│   │   │   └── dashboard_analytics_service.dart
│   │   └── providers/
│   │       └── dashboard_providers.dart
│   ├── preferences/              # Settings
│   ├── reminders/                # Notifications
│   ├── splash/                   # Splash screen
│   └── legal/                    # Privacy policy
├── shared/
│   ├── models/                   # Data models
│   │   ├── story.dart
│   │   ├── child_profile.dart
│   │   └── user_voice.dart
│   └── widgets/                  # Reusable widgets
│       └── storyhug_logo.dart
└── main.dart                     # App entry point
```

### Tech Stack

- **Frontend:** Flutter 3.16.0 + Dart 3.2.0
- **Backend:** Supabase (PostgreSQL, Auth, Storage)
- **Voice AI:** ElevenLabs API
- **State Management:** Riverpod
- **Navigation:** GoRouter
- **Audio:** AudioPlayers + just_audio
- **Charts:** fl_chart
- **Local Storage:** shared_preferences
- **HTTP:** http package

---

## 🔒 Security & Privacy

### Data Protection

- **Encryption:** All sensitive data encrypted at rest
- **Secure Storage:** Secure local storage for user data
- **HTTPS:** All API communications over HTTPS
- **Authentication:** Secure JWT-based authentication
- **RLS:** Row Level Security in Supabase

### Privacy Compliance

- **GDPR Compliant:** European data protection
- **COPPA Compliant:** Children's privacy protection
- **Data Minimization:** Only collect necessary data
- **User Control:** Users can delete data anytime
- **Voice Consent:** Explicit consent for voice recording
- **Data Retention:** Automated cleanup policies

### Privacy Policy

Comprehensive privacy policy available at:
- In-app: Settings → Privacy Policy
- Web: https://storyhug.ai/privacy

---

## 🤝 Support & Contact

### Documentation
- **Complete Docs:** This file
- **Database Schema:** `COMPLETE_DATABASE_SCHEMA.sql`

### Issues & Bugs
- **GitHub Issues:** [Report bugs](https://github.com/yourusername/storyhug/issues)
- **Email:** support@storyhug.ai

### Contributing
We welcome contributions! To contribute:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- **Flutter Team:** For the amazing framework
- **Supabase:** For the backend platform
- **ElevenLabs:** For voice cloning technology
- **Open Source Community:** For amazing packages

---

<div align="center">
  <p><strong>Made with ❤️ for families everywhere</strong></p>
  <p>© 2025 StoryHug. All rights reserved.</p>
  <p><strong>Version 1.0.0 | Build Date: October 25, 2025</strong></p>
</div>

