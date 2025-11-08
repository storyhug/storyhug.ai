import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'voice_consent_service.dart';

/// Service to handle short parent-recorded audio snippets (10-20 seconds)
/// These can be inserted at specific points in stories
class ParentSnippetsService {
  static final ParentSnippetsService _instance = ParentSnippetsService._internal();
  factory ParentSnippetsService() => _instance;
  ParentSnippetsService._internal();

  final AudioRecorder _recorder = AudioRecorder();
  final VoiceConsentService _consentService = VoiceConsentService();
  SupabaseClient get _supabase => SupabaseService.client;

  static const int minSnippetDurationSeconds = 5;
  static const int maxSnippetDurationSeconds = 30;
  static const int optimalSnippetDurationSeconds = 15;

  /// Snippet types for different story moments
  static const List<String> snippetTypes = [
    'intro', // Opening greeting
    'hug_line', // Special loving message
    'goodnight', // Ending/closing
    'encouragement', // Mid-story encouragement
    'custom', // User-defined
  ];

  /// Start recording a snippet
  Future<bool> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        print('⚠️ Microphone permission not granted');
        return false;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/snippet_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 44100,
          bitRate: 128000,
        ),
        path: path,
      );

      print('🎤 Recording snippet started: $path');
      return true;
    } catch (e) {
      print('❌ Failed to start recording: $e');
      return false;
    }
  }

  /// Stop recording and get the file path
  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      print('🛑 Recording stopped: $path');
      return path;
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      return null;
    }
  }

  /// Validate snippet duration and quality
  Future<Map<String, dynamic>> validateSnippet(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        return {
          'is_valid': false,
          'error': 'File does not exist',
        };
      }

      final fileSize = await file.length();
      
      // Basic validation
      if (fileSize < 10000) { // Less than 10KB is likely too short
        return {
          'is_valid': false,
          'error': 'Recording is too short',
        };
      }

      if (fileSize > 5000000) { // More than 5MB is likely too long
        return {
          'is_valid': false,
          'error': 'Recording is too long',
        };
      }

      return {
        'is_valid': true,
        'file_size': fileSize,
        'file_path': filePath,
      };
    } catch (e) {
      return {
        'is_valid': false,
        'error': 'Validation failed: $e',
      };
    }
  }

  /// Save snippet with metadata
  Future<String> saveSnippet({
    required String userId,
    required String filePath,
    required String snippetType,
    String? snippetName,
    String? description,
  }) async {
    try {
      // Validate consent first
      final hasConsent = await _consentService.hasValidConsent(
        userId,
        snippetName ?? 'Parent Snippet',
      );

      if (!hasConsent) {
        throw Exception(
          'Please accept the voice consent agreement before recording snippets',
        );
      }

      // Validate snippet
      final validation = await validateSnippet(filePath);
      if (!validation['is_valid']) {
        throw Exception(validation['error']);
      }

      // TODO: Upload to Supabase Storage
      // For now, keep local path
      final file = File(filePath);
      final directory = await getApplicationDocumentsDirectory();
      final snippetsDir = Directory('${directory.path}/snippets');
      
      if (!await snippetsDir.exists()) {
        await snippetsDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final savedPath = '${snippetsDir.path}/${userId}_${snippetType}_$timestamp.m4a';
      await file.copy(savedPath);

      // Save metadata to database
      final result = await _supabase
          .from('parent_snippets')
          .insert({
            'user_id': userId,
            'snippet_type': snippetType,
            'snippet_name': snippetName ?? snippetType,
            'description': description,
            'file_path': savedPath,
            'duration_seconds': optimalSnippetDurationSeconds, // Estimate for now
            'is_encrypted': true,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      return result['id'];
    } catch (e) {
      throw Exception('Failed to save snippet: $e');
    }
  }

  /// Get all snippets for a user
  Future<List<Map<String, dynamic>>> getUserSnippets(String userId) async {
    try {
      final response = await _supabase
          .from('parent_snippets')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get snippets: $e');
    }
  }

  /// Get snippets by type
  Future<List<Map<String, dynamic>>> getSnippetsByType({
    required String userId,
    required String snippetType,
  }) async {
    try {
      final response = await _supabase
          .from('parent_snippets')
          .select('*')
          .eq('user_id', userId)
          .eq('snippet_type', snippetType)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get snippets by type: $e');
    }
  }

  /// Delete a snippet
  Future<void> deleteSnippet(String snippetId, String userId) async {
    try {
      // Get snippet info first to delete file
      final snippet = await _supabase
          .from('parent_snippets')
          .select('file_path')
          .eq('id', snippetId)
          .eq('user_id', userId)
          .single();

      final filePath = snippet['file_path'];
      
      // Delete file
      if (filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
      }

      // Delete database record
      await _supabase
          .from('parent_snippets')
          .delete()
          .eq('id', snippetId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to delete snippet: $e');
    }
  }

  /// Get insertion points in a story where snippets can be added
  List<Map<String, dynamic>> getInsertionPoints(String storyText) {
    final points = <Map<String, dynamic>>[];

    // Beginning (intro)
    points.add({
      'position': 0,
      'type': 'intro',
      'description': 'Story opening (before first sentence)',
      'recommended_snippet_type': 'intro',
    });

    // Middle (hug line)
    final midPoint = (storyText.length / 2).round();
    points.add({
      'position': midPoint,
      'type': 'hug_line',
      'description': 'Mid-story encouragement',
      'recommended_snippet_type': 'hug_line',
    });

    // End (goodnight)
    points.add({
      'position': storyText.length,
      'type': 'goodnight',
      'description': 'Story ending (after last sentence)',
      'recommended_snippet_type': 'goodnight',
    });

    return points;
  }

  /// Embed snippet into story audio (placeholder for actual implementation)
  Future<String> embedSnippetInStory({
    required String storyAudioPath,
    required String snippetAudioPath,
    required int insertionPosition, // 0 = start, 1 = middle, 2 = end
  }) async {
    try {
      // TODO: Implement actual audio mixing with FFmpeg
      // For now, return story audio path unchanged
      print('📎 Embedding snippet at position $insertionPosition');
      return storyAudioPath;
    } catch (e) {
      throw Exception('Failed to embed snippet: $e');
    }
  }

  /// Get suggested snippet text for each type
  Map<String, String> getSuggestedText() {
    return {
      'intro': 'Hi sweetheart! I have a wonderful story for you tonight...',
      'hug_line': 'You are so loved, my dear. Remember that always...',
      'goodnight': 'Sweet dreams, my precious one. I love you so much...',
      'encouragement': 'You\'re doing amazing! Keep listening...',
      'custom': '[Your personal message here]',
    };
  }

  /// Dispose recorder
  Future<void> dispose() async {
    await _recorder.dispose();
  }
}

