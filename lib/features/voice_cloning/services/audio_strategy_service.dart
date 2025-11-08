import 'dart:io';
import 'voice_cloning_service.dart';
import '../../../shared/models/story.dart';

/// Service to handle different audio generation strategies
class AudioStrategyService {
  static final AudioStrategyService _instance = AudioStrategyService._internal();
  factory AudioStrategyService() => _instance;
  AudioStrategyService._internal();

  final VoiceCloningService _voiceCloningService = VoiceCloningService();

  /// Generate personalized audio based on story type
  Future<String> generatePersonalizedAudio({
    required Story story,
    required String userId,
    required String voiceId,
    bool preferBackgroundMusic = true,
  }) async {
    try {
      // Determine the best strategy based on story content
      if (story.hasAudioContent && preferBackgroundMusic) {
        // Strategy 1: Audio + Text (with background music)
        return await _generateAudioWithBGM(
          story: story,
          voiceId: voiceId,
          userId: userId,
        );
      } else {
        // Strategy 2: Text-only (voice-only generation)
        return await _generateVoiceOnly(
          story: story,
          voiceId: voiceId,
          userId: userId,
        );
      }
    } catch (e) {
      throw Exception('Failed to generate personalized audio: $e');
    }
  }

  /// Generate audio with background music (for stories with audio)
  Future<String> _generateAudioWithBGM({
    required Story story,
    required String voiceId,
    required String userId,
  }) async {
    try {
      print('🎵 Generating audio with background music for: ${story.title}');
      
      return await _voiceCloningService.generateAudioWithBackgroundMusic(
        voiceId: voiceId,
        text: story.body,
        originalAudioPath: story.audioDefaultUrl,
        fileName: 'story_${story.id}_${userId}_with_bgm.mp3',
      );
    } catch (e) {
      print('⚠️ BGM generation failed, falling back to voice-only: $e');
      return await _generateVoiceOnly(
        story: story,
        voiceId: voiceId,
        userId: userId,
      );
    }
  }

  /// Generate voice-only audio (for text-only stories)
  Future<String> _generateVoiceOnly({
    required Story story,
    required String voiceId,
    required String userId,
  }) async {
    try {
      print('🎤 Generating voice-only audio for: ${story.title}');
      
      return await _voiceCloningService.generateAudioWithClonedVoice(
        voiceId: voiceId,
        text: story.body,
        fileName: 'story_${story.id}_${userId}_voice_only.mp3',
        speakingRate: 0.15, // Extremely slow speed for storytelling
      );
    } catch (e) {
      throw Exception('Failed to generate voice-only audio: $e');
    }
  }

  /// Get audio generation strategy info
  Map<String, dynamic> getStrategyInfo(Story story) {
    return {
      'storyId': story.id,
      'title': story.title,
      'hasAudioContent': story.hasAudioContent,
      'isTextOnly': story.isTextOnly,
      'contentType': story.contentType,
      'audioUrl': story.audioDefaultUrl,
      'textLength': story.body.length,
      'recommendedStrategy': story.hasAudioContent ? 'Audio + BGM' : 'Voice Only',
    };
  }

  /// Check if personalized audio already exists
  Future<bool> hasPersonalizedAudio(String storyId, String userId) async {
    try {
      final appDir = await Directory.systemTemp;
      final audioDir = Directory('${appDir.path}/personalized_audio');
      
      // Check for both BGM and voice-only versions
      final bgmFile = File('${audioDir.path}/story_${storyId}_${userId}_with_bgm.mp3');
      final voiceOnlyFile = File('${audioDir.path}/story_${storyId}_${userId}_voice_only.mp3');
      
      return await bgmFile.exists() || await voiceOnlyFile.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get existing personalized audio path
  Future<String?> getPersonalizedAudioPath(String storyId, String userId) async {
    try {
      final appDir = await Directory.systemTemp;
      final audioDir = Directory('${appDir.path}/personalized_audio');
      
      // Check for BGM version first
      final bgmFile = File('${audioDir.path}/story_${storyId}_${userId}_with_bgm.mp3');
      if (await bgmFile.exists()) {
        return bgmFile.path;
      }
      
      // Check for voice-only version
      final voiceOnlyFile = File('${audioDir.path}/story_${storyId}_${userId}_voice_only.mp3');
      if (await voiceOnlyFile.exists()) {
        return voiceOnlyFile.path;
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clean up old personalized audio files
  Future<void> cleanupOldFiles({int maxAgeDays = 7}) async {
    try {
      final appDir = await Directory.systemTemp;
      final audioDir = Directory('${appDir.path}/personalized_audio');
      
      if (await audioDir.exists()) {
        final files = await audioDir.list().toList();
        final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
        
        for (final file in files) {
          if (file is File) {
            final stat = await file.stat();
            if (stat.modified.isBefore(cutoffDate)) {
              await file.delete();
              print('🗑️ Cleaned up old audio file: ${file.path}');
            }
          }
        }
      }
    } catch (e) {
      print('⚠️ Failed to cleanup old files: $e');
    }
  }

  /// Get audio generation statistics
  Future<Map<String, dynamic>> getGenerationStats() async {
    try {
      final appDir = await Directory.systemTemp;
      final audioDir = Directory('${appDir.path}/personalized_audio');
      
      int totalFiles = 0;
      int bgmFiles = 0;
      int voiceOnlyFiles = 0;
      int totalSizeBytes = 0;
      
      if (await audioDir.exists()) {
        final files = await audioDir.list().toList();
        
        for (final file in files) {
          if (file is File) {
            totalFiles++;
            totalSizeBytes += await file.length();
            
            if (file.path.contains('with_bgm')) {
              bgmFiles++;
            } else if (file.path.contains('voice_only')) {
              voiceOnlyFiles++;
            }
          }
        }
      }
      
      return {
        'totalFiles': totalFiles,
        'bgmFiles': bgmFiles,
        'voiceOnlyFiles': voiceOnlyFiles,
        'totalSizeMB': (totalSizeBytes / (1024 * 1024)).toStringAsFixed(2),
        'lastCleanup': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'totalFiles': 0,
        'bgmFiles': 0,
        'voiceOnlyFiles': 0,
        'totalSizeMB': '0.00',
      };
    }
  }
}
