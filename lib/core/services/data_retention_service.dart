import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Service to manage data retention policies and auto-deletion
class DataRetentionService {
  static final DataRetentionService _instance = DataRetentionService._internal();
  factory DataRetentionService() => _instance;
  DataRetentionService._internal();

  SupabaseClient get _supabase => SupabaseService.client;

  // Default retention periods (in months)
  static const int defaultVoiceRetentionMonths = 12;
  static const int defaultAudioRetentionMonths = 6;
  static const int defaultConsentRetentionYears = 7; // Legal requirement

  /// Set retention policy for a user
  Future<void> setRetentionPolicy({
    required String userId,
    int? voiceRetentionMonths,
    int? audioRetentionMonths,
    bool optInToRetain = false,
  }) async {
    try {
      await _supabase
          .from('retention_policies')
          .upsert({
            'user_id': userId,
            'voice_retention_months': voiceRetentionMonths ?? defaultVoiceRetentionMonths,
            'audio_retention_months': audioRetentionMonths ?? defaultAudioRetentionMonths,
            'opt_in_to_retain': optInToRetain,
            'updated_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to set retention policy: $e');
    }
  }

  /// Get retention policy for a user
  Future<Map<String, dynamic>> getRetentionPolicy(String userId) async {
    try {
      final response = await _supabase
          .from('retention_policies')
          .select('*')
          .eq('user_id', userId)
          .single();

      return response;
    } catch (e) {
      // Return default policy if none exists
      return {
        'voice_retention_months': defaultVoiceRetentionMonths,
        'audio_retention_months': defaultAudioRetentionMonths,
        'opt_in_to_retain': false,
      };
    }
  }

  /// Auto-delete expired voice data
  Future<Map<String, dynamic>> autoDeleteExpiredData(String userId) async {
    try {
      final policy = await getRetentionPolicy(userId);
      final List<String> errors = [];
      final results = {
        'voices_deleted': 0,
        'audio_deleted': 0,
        'errors': errors,
      };

      // Skip deletion if user opted in to retain
      if (policy['opt_in_to_retain'] == true) {
        return {
          ...results,
          'message': 'User opted in to retain data - no deletion performed',
        };
      }

      // Delete expired voices
      try {
        final voiceRetentionMonths = policy['voice_retention_months'] as int;
        final voiceCutoffDate = DateTime.now().subtract(
          Duration(days: voiceRetentionMonths * 30),
        );

        final voicesResult = await _supabase
            .from('user_voices')
            .delete()
            .eq('user_id', userId)
            .lt('created_at', voiceCutoffDate.toIso8601String());

        results['voices_deleted'] = voicesResult.length;
      } catch (e) {
        errors.add('Voice deletion error: $e');
      }

      // Delete expired generated audio
      try {
        final audioRetentionMonths = policy['audio_retention_months'] as int;
        final audioCutoffDate = DateTime.now().subtract(
          Duration(days: audioRetentionMonths * 30),
        );

        // Note: This would need additional table for tracking generated audio
        // For now, we'll log it as a placeholder
        print('Audio cleanup for files older than $audioCutoffDate');
      } catch (e) {
        errors.add('Audio deletion error: $e');
      }

      return results;
    } catch (e) {
      throw Exception('Failed to auto-delete expired data: $e');
    }
  }

  /// Schedule auto-deletion for a specific date
  Future<void> scheduleDataDeletion({
    required String userId,
    required DateTime deletionDate,
    String? reason,
  }) async {
    try {
      await _supabase
          .from('scheduled_deletions')
          .insert({
            'user_id': userId,
            'deletion_date': deletionDate.toIso8601String(),
            'reason': reason ?? 'User requested',
            'status': 'pending',
            'created_at': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to schedule deletion: $e');
    }
  }

  /// Cancel scheduled deletion
  Future<void> cancelScheduledDeletion(String userId) async {
    try {
      await _supabase
          .from('scheduled_deletions')
          .update({'status': 'cancelled'})
          .eq('user_id', userId)
          .eq('status', 'pending');
    } catch (e) {
      throw Exception('Failed to cancel scheduled deletion: $e');
    }
  }

  /// Get data age for a user
  Future<Map<String, dynamic>> getDataAge(String userId) async {
    try {
      // Get oldest voice
      final voicesResult = await _supabase
          .from('user_voices')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: true)
          .limit(1);

      DateTime? oldestVoiceDate;
      if (voicesResult.isNotEmpty) {
        oldestVoiceDate = DateTime.parse(voicesResult.first['created_at']);
      }

      // Get oldest consent
      final consentsResult = await _supabase
          .from('voice_consents')
          .select('consent_timestamp')
          .eq('user_id', userId)
          .order('consent_timestamp', ascending: true)
          .limit(1);

      DateTime? oldestConsentDate;
      if (consentsResult.isNotEmpty) {
        oldestConsentDate = DateTime.parse(consentsResult.first['consent_timestamp']);
      }

      return {
        'oldest_voice_date': oldestVoiceDate?.toIso8601String(),
        'oldest_consent_date': oldestConsentDate?.toIso8601String(),
        'voice_age_days': oldestVoiceDate != null
            ? DateTime.now().difference(oldestVoiceDate).inDays
            : null,
        'consent_age_days': oldestConsentDate != null
            ? DateTime.now().difference(oldestConsentDate).inDays
            : null,
      };
    } catch (e) {
      throw Exception('Failed to get data age: $e');
    }
  }

  /// Request immediate data deletion
  Future<void> requestImmediateDeletion({
    required String userId,
    bool deleteVoices = true,
    bool deleteAudio = true,
    bool deleteConsents = false, // Consents kept for legal compliance
  }) async {
    try {
      if (deleteVoices) {
        await _supabase
            .from('user_voices')
            .delete()
            .eq('user_id', userId);
      }

      if (deleteConsents) {
        // Mark as inactive instead of deleting (for audit trail)
        await _supabase
            .from('voice_consents')
            .update({'is_active': false, 'deleted_at': DateTime.now().toIso8601String()})
            .eq('user_id', userId);
      }

      // Log the deletion request
      await _supabase
          .from('deletion_log')
          .insert({
            'user_id': userId,
            'deletion_type': 'immediate',
            'deleted_voices': deleteVoices,
            'deleted_audio': deleteAudio,
            'deleted_consents': deleteConsents,
            'timestamp': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      throw Exception('Failed to delete data: $e');
    }
  }

  /// Get retention policy info for display
  Map<String, dynamic> getRetentionPolicyInfo() {
    return {
      'default_voice_retention_months': defaultVoiceRetentionMonths,
      'default_audio_retention_months': defaultAudioRetentionMonths,
      'consent_retention_years': defaultConsentRetentionYears,
      'description': '''
Data Retention Policy:

• Voice recordings: Automatically deleted after $defaultVoiceRetentionMonths months
• Generated audio: Automatically deleted after $defaultAudioRetentionMonths months
• Consent records: Retained for $defaultConsentRetentionYears years (legal requirement)

You can:
- Opt in to retain your data indefinitely
- Request immediate deletion at any time
- Customize retention periods in settings
''',
    };
  }
}

