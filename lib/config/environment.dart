// Environment Configuration
// Copy this file to lib/config/environment.dart and replace with your actual values

class Environment {
  // Supabase Configuration
  static const String supabaseUrl = 'https://glqthbevuzituddwgpev.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdscXRoYmV2dXppdHVkZHdncGV2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxNDA0MDUsImV4cCI6MjA3NTcxNjQwNX0.xSjPaSaJI5hnFWzOShQftTOUCS2IJMt7UbyWfppEkvw';
  
  // Stripe Configuration
  static const String stripePublishableKey = 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY';
  static const String stripeSecretKey = 'sk_test_YOUR_STRIPE_SECRET_KEY';
  static const String stripeWebhookSecret = 'whsec_YOUR_WEBHOOK_SECRET';
  
  // ElevenLabs Configuration
  static const String elevenLabsApiKey = 'sk_34865333c21059a6d9fc3156821575ccb76ce80bae25b30a';
  static const String elevenLabsBaseUrl = 'https://api.elevenlabs.io/v1';
  
  // App Configuration
  static const String appName = 'StoryHug';
  static const String appVersion = '1.0.0';
  static const String bundleId = 'com.storyhug.app';
  
  // Environment
  static const bool isProduction = false; // Set to true for production builds
  
  // Limits
  static const int maxRecordingDurationSeconds = 15;
  static const int minRecordingDurationSeconds = 10;
  static const int maxStoriesPerDay = 3; // Free users
  static const int maxVoiceCloningAttempts = 1; // Free users
  
  // Validation
  static bool get isValid {
    return supabaseUrl.isNotEmpty &&
           supabaseAnonKey.isNotEmpty &&
           stripePublishableKey != 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY' &&
           stripeSecretKey != 'sk_test_YOUR_STRIPE_SECRET_KEY' &&
           elevenLabsApiKey.isNotEmpty &&
           elevenLabsBaseUrl.isNotEmpty;
  }
  
  // Get configuration summary (for debugging)
  static Map<String, dynamic> get config {
    return {
      'supabaseUrl': supabaseUrl,
      'stripePublishableKey': stripePublishableKey.length > 8 
          ? '${stripePublishableKey.substring(0, 8)}...' 
          : 'Not configured',
      'elevenLabsApiKey': elevenLabsApiKey.length > 8 
          ? '${elevenLabsApiKey.substring(0, 8)}...' 
          : 'Not configured',
      'elevenLabsBaseUrl': elevenLabsBaseUrl,
      'isProduction': isProduction,
      'isValid': isValid,
    };
  }
}
