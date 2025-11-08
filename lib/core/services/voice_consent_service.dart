import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service to manage voice cloning consent with audit trails
class VoiceConsentService {
  static final VoiceConsentService _instance = VoiceConsentService._internal();
  factory VoiceConsentService() => _instance;
  VoiceConsentService._internal();

  SupabaseClient get _supabase => SupabaseService.client;

  /// Record voice consent with timestamp and metadata
  Future<String> recordConsent({
    required String userId,
    required String consentText,
    required String voiceName,
    String? ipAddress,
    String? deviceInfo,
  }) async {
    try {
      final consentData = {
        'user_id': userId,
        'consent_text': consentText,
        'voice_name': voiceName,
        'consent_timestamp': DateTime.now().toIso8601String(),
        'ip_address': ipAddress,
        'device_info': deviceInfo,
        'consent_version': '1.0',
        'is_active': true,
      };

      final response = await _supabase
          .from('voice_consents')
          .insert(consentData)
          .select('id')
          .single();

      return response['id'];
    } catch (e) {
      throw Exception('Failed to record consent: $e');
    }
  }

  /// Get all consents for a user
  Future<List<Map<String, dynamic>>> getUserConsents(String userId) async {
    try {
      final response = await _supabase
          .from('voice_consents')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('consent_timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get consents: $e');
    }
  }

  /// Check if user has given consent for voice cloning
  Future<bool> hasValidConsent(String userId, String voiceName) async {
    try {
      final response = await _supabase
          .from('voice_consents')
          .select('id')
          .eq('user_id', userId)
          .eq('voice_name', voiceName)
          .eq('is_active', true)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Error checking consent: $e');
      return false;
    }
  }

  /// Revoke consent for a specific voice
  Future<void> revokeConsent(String userId, String voiceName) async {
    try {
      await _supabase
          .from('voice_consents')
          .update({
            'is_active': false,
            'revoked_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('voice_name', voiceName);
    } catch (e) {
      throw Exception('Failed to revoke consent: $e');
    }
  }

  /// Get consent form text
  String getConsentFormText() {
    return '''
VOICE CLONING CONSENT AGREEMENT

I hereby grant permission to StoryHug to:
1. Record and process my voice for the purpose of creating personalized story narrations
2. Generate synthetic voice content using AI/ML technology based on my voice recording
3. Store my voice data securely and encrypted for use within the StoryHug app

I understand that:
- My voice will only be used for generating personalized story content for my family
- I can request deletion of my voice data at any time
- My voice data will be stored securely and encrypted
- StoryHug will not share my voice data with third parties without my explicit consent

I have read and understood this consent agreement and agree to the terms stated above.

Date: ${DateTime.now().toLocal().toString().split(' ')[0]}
''';
  }

  /// Validate consent before voice cloning
  Future<bool> validateConsentBeforeCloning({
    required String userId,
    required String voiceName,
  }) async {
    final hasConsent = await hasValidConsent(userId, voiceName);
    
    if (!hasConsent) {
      throw Exception(
        'Voice cloning requires explicit consent. Please review and accept the consent form.',
      );
    }
    
    return true;
  }

  /// Get consent audit log for a user
  Future<List<Map<String, dynamic>>> getConsentAuditLog(String userId) async {
    try {
      final response = await _supabase
          .from('voice_consents')
          .select('*')
          .eq('user_id', userId)
          .order('consent_timestamp', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get consent audit log: $e');
    }
  }
}

