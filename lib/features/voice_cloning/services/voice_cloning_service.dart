import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/environment.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_voice.dart';
import 'audio_mixing_service.dart';

class VoiceCloningService {
  static const String _baseUrl = Environment.elevenLabsBaseUrl;
  static const String _apiKey = Environment.elevenLabsApiKey;
  static const int _requiredDurationSeconds = Environment.maxRecordingDurationSeconds;

  // Default ElevenLabs voice IDs
  static const String _defaultMaleVoiceId = 'MV2lIGFO3SleI2bwL8Cp';
  static const String _defaultFemaleVoiceId = 'wlmwDR77ptH6bKHZui0l';
  
  final AudioMixingService _audioMixingService = AudioMixingService();

  /// Clone voice from audio file using ElevenLabs with custom name
  Future<String> cloneVoice(File audioFile, String userId, String voiceName, {String? voiceDescription}) async {
    try {
      // Validate audio quality first
      final isValid = await validateAudioQuality(audioFile);
      if (!isValid) {
        throw Exception('Audio quality is not suitable for voice cloning');
      }

      // Create voice using ElevenLabs API
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/voices/add'),
      );

      // Add API key to headers
      request.headers['xi-api-key'] = _apiKey;

      // Add audio file
      request.files.add(
        await http.MultipartFile.fromPath(
          'files',
          audioFile.path,
        ),
      );

      // Add voice metadata
      request.fields['name'] = '$voiceName - $userId';
      request.fields['description'] = voiceDescription ?? 'Personalized voice for StoryHug user $userId';

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        
        if (data['voice_id'] != null) {
          // Save voice with custom name to Supabase
          await _saveVoiceWithName(userId, data['voice_id'], voiceName, voiceDescription);
          return data['voice_id'];
        } else {
          throw Exception('Voice cloning failed: No voice ID returned');
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        
        // Handle specific API permission errors
        if (response.statusCode == 401) {
          try {
            final errorData = json.decode(errorBody);
            if (errorData['detail'] != null && 
                errorData['detail']['status'] == 'missing_permissions') {
              throw Exception('ElevenLabs API key missing permissions. Please check your API key has voices_write permission.');
            }
          } catch (e) {
            // If JSON parsing fails, use original error
          }
        }
        
        throw Exception('Voice cloning failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Voice cloning error: $e');
    }
  }

  /// Generate audio from text using cloned voice
  Future<String> generateAudioWithClonedVoice({
    required String voiceId,
    required String text,
    String? fileName,
    double speakingRate = 0.15, // Extremely slow speed for storytelling
  }) async {
    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/text-to-speech/$voiceId'),
      );

      request.headers['xi-api-key'] = _apiKey;
      request.headers['Content-Type'] = 'application/json';

      final requestBody = {
        'text': text,
        'model_id': 'eleven_multilingual_v2', // Best model for multiple languages
        'voice_settings': {
          'stability': 0.8, // Higher for more consistent storytelling
          'similarity_boost': 0.9, // Higher for better voice cloning
          'style': 0.05, // Very low style for natural storytelling
          'use_speaker_boost': true,
          'speaking_rate': speakingRate, // Much slower speed for storytelling
        },
      };

      request.body = json.encode(requestBody);

      final response = await request.send();
      
      if (response.statusCode == 200) {
      // Save audio file locally
      final audioBytes = await response.stream.toBytes();
      final finalFileName = fileName ?? 'story_${DateTime.now().millisecondsSinceEpoch}.mp3';
      final audioFile = await _saveAudioFile(audioBytes, finalFileName);
        return audioFile.path;
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Audio generation failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      throw Exception('Audio generation error: $e');
    }
  }

  /// Generate audio with cloned voice - handles both audio and text-only stories
  Future<String> generatePersonalizedAudio({
    required String voiceId,
    required String storyText,
    String? originalAudioUrl,
    String? fileName,
    bool preferBackgroundMusic = true,
  }) async {
    try {
      // Check if we have original audio and user wants background music
      if (originalAudioUrl != null && 
          originalAudioUrl.isNotEmpty && 
          preferBackgroundMusic) {
        
        // Mode 1: Audio + Text (with background music)
        return await generateAudioWithBackgroundMusic(
          voiceId: voiceId,
          text: storyText,
          originalAudioPath: originalAudioUrl,
          fileName: fileName,
        );
      } else {
        // Mode 2: Text-only (voice-only generation)
        return await generateAudioWithClonedVoice(
          voiceId: voiceId,
          text: storyText,
          fileName: fileName,
          speakingRate: 0.15, // Extremely slow speed for storytelling
        );
      }
    } catch (e) {
      throw Exception('Failed to generate personalized audio: $e');
    }
  }

  /// Detect if story has audio or is text-only
  bool hasAudioContent(String? audioUrl) {
    return audioUrl != null && 
           audioUrl.isNotEmpty && 
           audioUrl != 'null' &&
           !audioUrl.contains('placeholder') &&
           audioUrl.startsWith('http');
  }

  /// Get optimal audio generation strategy based on story content
  Future<String> getOptimalAudioStrategy({
    required String voiceId,
    required String storyText,
    String? originalAudioUrl,
    String? fileName,
  }) async {
    try {
      // Check if story has audio content
      final hasAudio = hasAudioContent(originalAudioUrl);
      
      if (hasAudio) {
        // Strategy 1: Mix cloned voice with original background music
        print('Using audio mixing strategy: Voice + BGM');
        return await generateAudioWithBackgroundMusic(
          voiceId: voiceId,
          text: storyText,
          originalAudioPath: originalAudioUrl!,
          fileName: fileName,
        );
      } else {
        // Strategy 2: Generate voice-only audio
        print('Using voice-only strategy: Text-to-Speech');
        return await generateAudioWithClonedVoice(
          voiceId: voiceId,
          text: storyText,
          fileName: fileName,
          speakingRate: 0.15, // Extremely slow speed for storytelling
        );
      }
    } catch (e) {
      throw Exception('Failed to determine optimal audio strategy: $e');
    }
  }

  /// Generate audio with cloned voice and background music
  Future<String> generateAudioWithBackgroundMusic({
    required String voiceId,
    required String text,
    required String originalAudioPath,
    String? fileName,
  }) async {
    try {
      // First generate voice-only audio
      final voiceOnlyPath = await generateAudioWithClonedVoice(
        voiceId: voiceId,
        text: text,
        fileName: fileName ?? 'voice_only_${DateTime.now().millisecondsSinceEpoch}.mp3',
        speakingRate: 0.15, // Extremely slow speed for storytelling
      );

      // Then mix with background music
      final mixedAudioPath = await _audioMixingService.mixVoiceWithBGM(
        clonedVoicePath: voiceOnlyPath,
        originalAudioPath: originalAudioPath,
        outputFileName: fileName ?? 'mixed_${DateTime.now().millisecondsSinceEpoch}.mp3',
      );

      return mixedAudioPath;
    } catch (e) {
      throw Exception('Failed to generate audio with background music: $e');
    }
  }

  /// Check if user has a cloned voice
  Future<bool> hasClonedVoice(String userId) async {
    try {
      final voiceId = await getVoiceId(userId);
      return voiceId != null && voiceId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get voice ID for user (legacy method - gets default voice)
  Future<String?> getVoiceId(String userId) async {
    try {
      // First check Supabase for default voice
      final response = await SupabaseService.client
          .from('user_voices')
          .select('voice_id')
          .eq('user_id', userId)
          .eq('is_default', true)
          .eq('is_active', true)
          .single();

      return response['voice_id'] as String?;
    } catch (e) {
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final localVoiceId = prefs.getString('voice_id_$userId');
      
      if (localVoiceId != null && localVoiceId.isNotEmpty) {
        return localVoiceId;
      }
      
      // NO automatic fallback - return null if no default voice is set
      print('No default voice set for user: $e');
      return null;
    }
  }

  /// Get default ElevenLabs voices for UI display
  List<Map<String, String>> getDefaultVoices() {
    return [
      {
        'id': _defaultMaleVoiceId,
        'name': 'AI Male Voice',
        'description': 'Default male voice from ElevenLabs',
      },
      {
        'id': _defaultFemaleVoiceId,
        'name': 'AI Female Voice',
        'description': 'Default female voice from ElevenLabs',
      },
    ];
  }

  /// Get all voices for a user
  Future<List<UserVoice>> getUserVoices(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('user_voices')
          .select('*')
          .eq('user_id', userId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((voice) => UserVoice.fromJson(voice))
          .toList();
    } catch (e) {
      print('Error getting user voices: $e');
      return [];
    }
  }

  /// Get default voice for a user
  Future<UserVoice?> getDefaultVoice(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('user_voices')
          .select('*')
          .eq('user_id', userId)
          .eq('is_default', true)
          .eq('is_active', true)
          .single();
      
      return UserVoice.fromJson(response);
    } catch (e) {
      print('Error getting default voice: $e');
      return null;
    }
  }

  /// Set a voice as default
  Future<void> setDefaultVoice(String userId, String voiceId) async {
    try {
      // First, unset all default voices for this user
      await SupabaseService.client
          .from('user_voices')
          .update({'is_default': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('is_default', true);
      
      // Then set the specified voice as default
      await SupabaseService.client
          .from('user_voices')
          .update({'is_default': true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('voice_id', voiceId);
    } catch (e) {
      throw Exception('Failed to set default voice: $e');
    }
  }

  /// Delete a voice (soft delete - marks as inactive)
  Future<void> deleteVoice(String userId, String voiceId) async {
    try {
      await SupabaseService.client
          .from('user_voices')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('user_id', userId)
          .eq('voice_id', voiceId);
    } catch (e) {
      throw Exception('Failed to delete voice: $e');
    }
  }

  /// Permanently delete a voice (hard delete - removes from database)
  Future<void> permanentlyDeleteVoice(String userId, String voiceId) async {
    try {
      await SupabaseService.client
          .from('user_voices')
          .delete()
          .eq('user_id', userId)
          .eq('voice_id', voiceId);
    } catch (e) {
      throw Exception('Failed to permanently delete voice: $e');
    }
  }

  /// Clean up all inactive voices for a user (hard delete all soft-deleted voices)
  Future<void> cleanupInactiveVoices(String userId) async {
    try {
      await SupabaseService.client
          .from('user_voices')
          .delete()
          .eq('user_id', userId)
          .eq('is_active', false);
    } catch (e) {
      throw Exception('Failed to cleanup inactive voices: $e');
    }
  }

  /// Update voice name and description
  Future<void> updateVoice(String userId, String voiceId, String voiceName, {String? voiceDescription}) async {
    try {
      await SupabaseService.client
          .from('user_voices')
          .update({
            'voice_name': voiceName,
            'voice_description': voiceDescription,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('voice_id', voiceId);
    } catch (e) {
      throw Exception('Failed to update voice: $e');
    }
  }

  /// Save voice with custom name to Supabase
  Future<void> _saveVoiceWithName(String userId, String voiceId, String voiceName, String? voiceDescription) async {
    try {
      // NO automatic default setting - user must manually set default
      
      // Save to Supabase
      await SupabaseService.client
          .from('user_voices')
          .insert({
            'user_id': userId,
            'voice_id': voiceId,
            'voice_name': voiceName,
            'voice_description': voiceDescription,
            'is_default': false, // Never auto-set as default
            'is_active': true,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Save to local storage as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_id_$userId', voiceId);
      await prefs.setString('voice_name_$userId', voiceName);
    } catch (e) {
      // If Supabase fails, at least save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_id_$userId', voiceId);
      await prefs.setString('voice_name_$userId', voiceName);
      throw Exception('Failed to save voice to database: $e');
    }
  }

  /// Save voice ID to Supabase and local storage (legacy method)
  Future<void> _saveVoiceId(String userId, String voiceId) async {
    try {
      // Save to Supabase
      await SupabaseService.client
          .from('user_voices')
          .upsert({
            'user_id': userId,
            'voice_id': voiceId,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

      // Save to local storage as backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_id_$userId', voiceId);
    } catch (e) {
      // If Supabase fails, at least save locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('voice_id_$userId', voiceId);
      throw Exception('Failed to save voice ID to database: $e');
    }
  }

  /// Save generated audio file
  Future<File> _saveAudioFile(List<int> audioBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final audioDir = Directory('${directory.path}/generated_audio');
    
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    
    final file = File('${audioDir.path}/$fileName');
    await file.writeAsBytes(audioBytes);
    return file;
  }

  /// Validate audio quality for voice cloning
  Future<bool> validateAudioQuality(File audioFile) async {
    try {
      if (!await audioFile.exists()) return false;

      final fileSize = await audioFile.length();
      // More lenient file size requirements
      if (fileSize < 10000 || fileSize > 10000000) return false; // 10KB to 10MB

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get optimal recording settings
  Map<String, dynamic> getOptimalRecordingSettings() {
    return {
      'sampleRate': 44100,
      'bitRate': 128000,
      'channels': 1,
      'format': 'wav',
      'duration': _requiredDurationSeconds,
    };
  }

  /// Get recording instructions
  List<String> getRecordingInstructions() {
    return [
      'Find a quiet room with minimal background noise',
      'Speak clearly and at a normal pace',
      'Hold the device 6-8 inches from your mouth',
      'Record for at least 10-15 seconds',
      'Read the provided text naturally',
      'Avoid background music or other voices',
    ];
  }

  /// Get sample recording text
  String getSampleRecordingText() {
    return '''
Hello! This is my voice sample for StoryHug. I'm recording this to create a personalized storytelling experience for my children. I want them to hear my voice when they listen to their favorite stories. This recording will help create a custom voice that sounds like me, making story time even more special and personal.
''';
  }

  /// Delete cloned voice
  Future<void> deleteClonedVoice(String userId) async {
    try {
      final voiceId = await getVoiceId(userId);
      if (voiceId != null) {
        // Delete from ElevenLabs
      final request = http.Request(
          'DELETE',
          Uri.parse('$_baseUrl/voices/$voiceId'),
      );
      request.headers['xi-api-key'] = _apiKey;
        
        await request.send();
        
        // Remove from Supabase
        await SupabaseService.client
            .from('user_voices')
            .delete()
            .eq('user_id', userId);
        
        // Remove from local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('voice_id_$userId');
      }
    } catch (e) {
      throw Exception('Failed to delete cloned voice: $e');
    }
  }

  /// Check microphone permission
  Future<bool> checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status == PermissionStatus.granted;
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  /// Get temporary file path for recording
  Future<String> getTemporaryFilePath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${directory.path}/voice_recording_$timestamp.wav';
  }

  /// Clean up temporary files
  Future<void> cleanupTemporaryFiles() async {
    try {
      final directory = await getTemporaryDirectory();
      final files = directory.listSync();
      
      for (final file in files) {
        if (file.path.contains('voice_recording_') && file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      // Ignore cleanup errors
    }
  }

  /// Legacy methods for backward compatibility
  Future<void> saveVoiceModelUrl(String userId, String voiceModelUrl) async {
    // This method is kept for backward compatibility
    // The new implementation uses voice IDs instead
    await _saveVoiceId(userId, voiceModelUrl);
  }

  Future<String?> getVoiceModelUrl(String userId) async {
    // This method is kept for backward compatibility
    return await getVoiceId(userId);
  }

  Future<void> deleteVoiceModel(String userId) async {
    // This method is kept for backward compatibility
    await deleteClonedVoice(userId);
  }

  Future<String> generateStoryAudio(String storyText, String voiceId) async {
    // This method is kept for backward compatibility
    return await generateAudioWithClonedVoice(
      voiceId: voiceId,
      text: storyText,
      speakingRate: 0.15, // Extremely slow speed for storytelling
    );
  }
}