# 📚 StoryHug - Personalized Storytelling App

<div align="center">
  <img src="assets/icon/icon.png" alt="StoryHug Logo" width="200"/>
  
  **Your stories, in their voice. Sweet dreams every night.**
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.16.0-blue.svg)](https://flutter.dev/)
  [![Dart](https://img.shields.io/badge/Dart-3.2.0-blue.svg)](https://dart.dev/)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
  [![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)](https://flutter.dev/)
</div>

## 🌟 Overview

StoryHug is a revolutionary mobile application that transforms bedtime storytelling by allowing parents to create personalized voice models for their children. Using advanced AI voice cloning technology, parents can record their voice once and have it narrate unlimited stories, creating a magical and personalized experience for their little ones.

## ✨ Key Features

### 🎤 Voice Cloning Technology
- **One-Time Recording**: Record your voice once (15 seconds)
- **AI-Powered Cloning**: Advanced Coqui-TTS integration
- **Natural Storytelling**: Your voice narrates every story
- **Quality Validation**: Automatic audio quality checks

### 📚 Rich Story Library
- **Unlimited Stories**: Access to thousands of stories
- **Age-Appropriate Content**: Stories categorized by age groups
- **Multiple Categories**: Moral stories, Indian mythology, adventures, fairy tales
- **Regular Updates**: New stories added weekly

### 🎵 Professional Audio Player
- **Full Controls**: Play, pause, skip, repeat, sleep timer
- **Voice Selection**: Toggle between AI voice and parent's voice
- **Background Playback**: Continue listening while using other apps
- **Offline Support**: Download stories for offline listening

### 👶 Child Profile Management
- **Multiple Children**: Create profiles for each child
- **Age-Based Content**: Stories filtered by child's age
- **Progress Tracking**: Monitor listening history and preferences
- **Personalized Experience**: Customized content for each child

### 💳 Premium Subscription
- **Freemium Model**: Free stories with premium upgrades
- **Unlimited Access**: Premium subscribers get unlimited stories
- **Voice Cloning**: Premium feature for personalized voices
- **Offline Downloads**: Download stories for offline listening
- **Ad-Free Experience**: No interruptions during storytelling

### 📊 Parental Dashboard
- **Usage Analytics**: Track listening time and story completion
- **Activity Monitoring**: See what your child is listening to
- **Progress Reports**: Detailed insights into learning progress
- **Quick Actions**: Easy access to all app features

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter 3.16.0 with Dart 3.2.0
- **Backend**: Supabase (PostgreSQL, Auth, Storage)
- **Voice AI**: Coqui-TTS for voice cloning
- **Subscriptions**: RevenueCat for cross-platform subscription management
- **State Management**: Provider pattern
- **Navigation**: GoRouter for declarative routing
- **Audio**: AudioPlayers for media playback
- **Testing**: Flutter Test, Integration Test, Mockito

### Project Structure
```
lib/
├── core/
│   ├── theme/           # App theme and design system
│   ├── router/          # Navigation configuration
│   └── services/        # Core services (Supabase, etc.)
├── features/
│   ├── auth/            # Authentication pages and services
│   ├── profiles/        # Child profile management
│   ├── stories/         # Story browsing and management
│   ├── player/          # Audio player functionality
│   ├── voice_cloning/   # Voice recording and cloning
│   ├── subscription/    # Premium subscription management
│   ├── preferences/     # App settings and preferences
│   ├── reminders/       # Notification and reminder system
│   └── dashboard/       # Parental dashboard and analytics
├── shared/
│   └── models/          # Data models and DTOs
└── main.dart            # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio / Xcode for mobile development
- Supabase account for backend services
- RevenueCat account for subscription management
- Coqui-TTS server for voice cloning

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/storyhug_app.git
   cd storyhug_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**
   ```bash
   # Create environment configuration
   cp lib/config/environment.example.dart lib/config/environment.dart
   # Edit the file with your API keys and endpoints
   ```

4. **Set up Supabase**
   - Create a new Supabase project
   - Run the database migrations
   - Configure authentication providers
   - Set up storage buckets

5. **Configure RevenueCat**
   - Create a RevenueCat project
   - Set up subscription products
   - Configure entitlements

6. **Set up Coqui-TTS**
   - Deploy Coqui-TTS server
   - Configure API endpoints
   - Test voice cloning functionality

7. **Run the app**
   ```bash
   flutter run
   ```

## 🧪 Testing

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

### Test Coverage
- **Unit Tests**: 90%+ coverage for services and models
- **Widget Tests**: All major UI components tested
- **Integration Tests**: Complete user flows tested
- **Performance Tests**: Memory, CPU, and network usage

## 📱 Screenshots

<div align="center">
  <img src="screenshots/welcome.png" alt="Welcome Screen" width="200"/>
  <img src="screenshots/home.png" alt="Home Screen" width="200"/>
  <img src="screenshots/player.png" alt="Audio Player" width="200"/>
  <img src="screenshots/voice_cloning.png" alt="Voice Cloning" width="200"/>
  <img src="screenshots/subscription.png" alt="Subscription" width="200"/>
</div>

## 🔧 Configuration

### Environment Variables
```dart
// lib/config/environment.dart
class Environment {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
  static const String revenueCatApiKey = 'YOUR_REVENUECAT_API_KEY';
  static const String coquiTtsUrl = 'YOUR_COQUI_TTS_URL';
  static const bool isProduction = false;
}
```

### Supabase Configuration
```sql
-- Database schema
CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id),
  child_name TEXT NOT NULL,
  age_bucket INTEGER NOT NULL,
  avatar_url TEXT,
  nickname TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE stories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

## 🚀 Deployment

### Android
```bash
# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle --release
```

### iOS
```bash
# Build iOS app
flutter build ios --release

# Archive for App Store
flutter build ipa --release
```

### CI/CD Pipeline
- Automated testing on every commit
- Code quality checks with Flutter analyze
- Automated builds for both platforms
- Automated deployment to app stores

## 📊 Performance

### Optimization Features
- **Lazy Loading**: Stories loaded on demand
- **Image Caching**: Cached network images
- **Audio Preloading**: Next story preloaded
- **Memory Management**: Proper disposal of resources
- **Background Processing**: Voice cloning in background

### Performance Metrics
- **App Startup**: < 3 seconds
- **Memory Usage**: < 100MB
- **Battery Usage**: Optimized for long listening sessions
- **Network Usage**: Efficient data usage with caching

## 🔒 Security & Privacy

### Data Protection
- **Encryption**: All sensitive data encrypted
- **Secure Storage**: Secure local storage for user data
- **API Security**: HTTPS for all API communications
- **Authentication**: Secure user authentication with Supabase

### Privacy Compliance
- **GDPR Compliant**: European data protection compliance
- **COPPA Compliant**: Children's privacy protection
- **Data Minimization**: Only collect necessary data
- **User Control**: Users can delete their data anytime

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

### Code Style
- Follow Dart/Flutter style guidelines
- Use meaningful variable and function names
- Add comments for complex logic
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team**: For the amazing cross-platform framework
- **Supabase**: For the backend-as-a-service platform
- **RevenueCat**: For subscription management
- **Coqui-TTS**: For voice cloning technology
- **Open Source Community**: For the amazing packages and tools

## 📚 Complete Documentation

For comprehensive documentation covering all features, setup, deployment, and troubleshooting:

📖 **[COMPLETE_DOCUMENTATION.md](COMPLETE_DOCUMENTATION.md)** - Full project documentation including:
- Installation & Setup
- Branding & UI Guidelines
- Features Implementation
- Testing Guide
- Deployment Instructions
- Troubleshooting

🗄️ **[COMPLETE_DATABASE_SCHEMA.sql](COMPLETE_DATABASE_SCHEMA.sql)** - Complete database schema including:
- All tables, indexes, and policies
- Functions for favorites, voice management, and analytics
- Row Level Security (RLS) configurations
- Triggers and performance optimizations

## 📞 Support

- **Documentation**: See COMPLETE_DOCUMENTATION.md
- **Database**: See COMPLETE_DATABASE_SCHEMA.sql
- **Issues**: [GitHub Issues](https://github.com/yourusername/storyhug_app/issues)
- **Email**: support@storyhug.app

## 🗺️ Roadmap

### Version 2.0 (Q2 2024)
- [ ] Multi-language support
- [ ] Advanced voice customization
- [ ] Social sharing features
- [ ] Parent-child interaction features

### Version 2.1 (Q3 2024)
- [ ] AI story generation
- [ ] Interactive story elements
- [ ] Educational content integration
- [ ] Advanced analytics

### Version 3.0 (Q4 2024)
- [ ] Web application
- [ ] Smart speaker integration
- [ ] AR/VR story experiences
- [ ] Advanced parental controls

---

<div align="center">
  <p>Made with ❤️ for families everywhere</p>
  <p>© 2024 StoryHug. All rights reserved.</p>
</div>