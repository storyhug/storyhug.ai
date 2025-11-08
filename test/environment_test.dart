import 'package:flutter_test/flutter_test.dart';
import 'package:storyhug_app/config/environment.dart';

void main() {
  group('Environment Validation Tests', () {
    test('should validate current configuration', () {
      // Test that the validation logic works
      expect(Environment.isValid, isA<bool>());
      
      // Test that Supabase URL is configured
      expect(Environment.supabaseUrl, isNotEmpty);
      expect(Environment.supabaseUrl, contains('supabase.co'));
      
      // Test that Supabase Anon Key is configured
      expect(Environment.supabaseAnonKey, isNotEmpty);
      expect(Environment.supabaseAnonKey, startsWith('eyJ'));
      
      // Test that Stripe keys are still placeholders
      expect(Environment.stripePublishableKey, equals('pk_test_YOUR_STRIPE_PUBLISHABLE_KEY'));
      expect(Environment.stripeSecretKey, equals('sk_test_YOUR_STRIPE_SECRET_KEY'));
      
      // Test that ElevenLabs API key is configured
      expect(Environment.elevenLabsApiKey, isNotEmpty);
      expect(Environment.elevenLabsApiKey, startsWith('sk_'));
      
      // Test that ElevenLabs base URL is configured
      expect(Environment.elevenLabsBaseUrl, equals('https://api.elevenlabs.io/v1'));
    });
    
    test('should provide configuration summary', () {
      final config = Environment.config;
      
      expect(config, isA<Map<String, dynamic>>());
      expect(config['supabaseUrl'], isNotEmpty);
      expect(config['stripePublishableKey'], isA<String>());
      expect(config['elevenLabsApiKey'], isA<String>());
      expect(config['elevenLabsBaseUrl'], isA<String>());
      expect(config['isProduction'], isA<bool>());
      expect(config['isValid'], isA<bool>());
    });
  });
}
