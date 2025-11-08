import 'package:flutter/foundation.dart';
import '../../config/environment.dart';

class ConfigurationValidator {
  static Future<void> validateConfiguration() async {
    if (kDebugMode) {
      print('🔍 Validating StoryHug Configuration...');
      print('');
      
      // Check Supabase
      _validateSupabase();
      
      // Check Stripe
      _validateStripe();
      
      // Check ElevenLabs
      _validateElevenLabs();
      
      // Check Environment
      _validateEnvironment();
      
      print('');
      if (Environment.isValid) {
        print('✅ All configurations are valid!');
      } else {
        print('❌ Some configurations need to be updated.');
        print('Please check the API_KEYS_SETUP_GUIDE.md for instructions.');
      }
    }
  }
  
  static void _validateSupabase() {
    print('📊 Supabase Configuration:');
    print('  URL: ${Environment.supabaseUrl}');
    print('  Anon Key: ${Environment.supabaseAnonKey.substring(0, 20)}...');
    print('  Valid: ${Environment.supabaseUrl.isNotEmpty ? '✅' : '❌'}');
    print('');
  }
  
  static void _validateStripe() {
    print('💳 Stripe Configuration:');
    print('  Publishable Key: ${Environment.stripePublishableKey.substring(0, 10)}...');
    print('  Secret Key: ${Environment.stripeSecretKey.substring(0, 10)}...');
    print('  Valid: ${Environment.stripePublishableKey != 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY' ? '✅' : '❌'}');
    print('');
  }
  
  static void _validateElevenLabs() {
    print('🎤 ElevenLabs Configuration:');
    print('  API Key: ${Environment.elevenLabsApiKey.substring(0, 10)}...');
    print('  Base URL: ${Environment.elevenLabsBaseUrl}');
    print('  Valid: ${Environment.elevenLabsApiKey.isNotEmpty ? '✅' : '❌'}');
    print('');
  }
  
  static void _validateEnvironment() {
    print('⚙️ Environment Configuration:');
    print('  App Name: ${Environment.appName}');
    print('  Version: ${Environment.appVersion}');
    print('  Bundle ID: ${Environment.bundleId}');
    print('  Production: ${Environment.isProduction ? 'Yes' : 'No'}');
    print('');
  }
  
  static Map<String, dynamic> getConfigurationSummary() {
    return {
      'supabase': {
        'url': Environment.supabaseUrl,
        'valid': Environment.supabaseUrl.isNotEmpty,
      },
      'stripe': {
        'publishableKey': Environment.stripePublishableKey.substring(0, 10) + '...',
        'valid': Environment.stripePublishableKey != 'pk_test_YOUR_STRIPE_PUBLISHABLE_KEY',
      },
      'elevenLabs': {
        'apiKey': Environment.elevenLabsApiKey.substring(0, 10) + '...',
        'baseUrl': Environment.elevenLabsBaseUrl,
        'valid': Environment.elevenLabsApiKey.isNotEmpty,
      },
      'app': {
        'name': Environment.appName,
        'version': Environment.appVersion,
        'bundleId': Environment.bundleId,
        'production': Environment.isProduction,
      },
      'overall': {
        'valid': Environment.isValid,
      },
    };
  }
}
