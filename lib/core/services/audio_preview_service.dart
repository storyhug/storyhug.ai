import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../features/voice_cloning/services/voice_cloning_service.dart';

/// Service to generate quick audio previews (15-30 seconds)
class AudioPreviewService {
  static final AudioPreviewService _instance = AudioPreviewService._internal();
  factory AudioPreviewService() => _instance;
  AudioPreviewService._internal();

  final VoiceCloningService _voiceCloningService = VoiceCloningService();

  static const int previewDurationSeconds = 20;
  static const int previewWordCount = 50; // Approximate words for 20 seconds

  /// Generate a preview of a story using default voice
  Future<String> generatePreview({
    required String storyText,
    String? voiceId,
    int? customDurationSeconds,
  }) async {
    try {
      // Extract preview text (first portion of story)
      final previewText = _extractPreviewText(
        storyText,
        customDurationSeconds ?? previewDurationSeconds,
      );

      // Use default ElevenLabs voice if no voice ID provided
      final effectiveVoiceId = voiceId ?? _getDefaultPreviewVoice();

      // Generate audio for preview
      final audioPath = await _voiceCloningService.generateAudioWithClonedVoice(
        voiceId: effectiveVoiceId,
        text: previewText,
        fileName: 'preview_${DateTime.now().millisecondsSinceEpoch}.mp3',
        speakingRate: 0.15,
      );

      return audioPath;
    } catch (e) {
      throw Exception('Failed to generate preview: $e');
    }
  }

  /// Extract preview text from full story
  String _extractPreviewText(String fullText, int durationSeconds) {
    // Estimate words based on average speaking rate (150 words per minute)
    final targetWordCount = (durationSeconds / 60 * 150).round();
    
    final words = fullText.split(' ');
    
    if (words.length <= targetWordCount) {
      return fullText;
    }

    // Take first N words and find natural sentence break
    final previewWords = words.take(targetWordCount).toList();
    String preview = previewWords.join(' ');

    // Try to end on a sentence boundary
    final lastPeriod = preview.lastIndexOf('.');
    final lastQuestion = preview.lastIndexOf('?');
    final lastExclamation = preview.lastIndexOf('!');

    final lastSentenceEnd = [lastPeriod, lastQuestion, lastExclamation]
        .reduce((a, b) => a > b ? a : b);

    if (lastSentenceEnd > preview.length * 0.7) {
      // Cut at sentence boundary if it's not too short
      preview = preview.substring(0, lastSentenceEnd + 1);
    }

    // Add preview indicator
    preview += '\n\n[Preview - Full story available after generation]';

    return preview;
  }

  /// Get default preview voice ID (using ElevenLabs default)
  String _getDefaultPreviewVoice() {
    // This should be a pre-configured, child-friendly default voice
    // For now, returning a placeholder that should be replaced with actual voice ID
    return 'EXAVITQu4vr4xnSDxMaL'; // ElevenLabs "Sarah" voice (example)
  }

  /// Generate preview with mood preset
  Future<String> generatePreviewWithMood({
    required String storyText,
    required String moodPreset,
    String? voiceId,
  }) async {
    // Import mood preset service dynamically
    // For now, use standard preview
    return await generatePreview(
      storyText: storyText,
      voiceId: voiceId,
    );
  }

  /// Check if preview is cached
  Future<String?> getCachedPreview(String storyId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final previewDir = Directory('${directory.path}/previews');
      
      if (!await previewDir.exists()) {
        return null;
      }

      final previewFile = File('${previewDir.path}/preview_$storyId.mp3');
      
      if (await previewFile.exists()) {
        // Check if file is older than 7 days
        final stat = await previewFile.stat();
        final age = DateTime.now().difference(stat.modified);
        
        if (age.inDays < 7) {
          return previewFile.path;
        } else {
          // Delete old preview
          await previewFile.delete();
          return null;
        }
      }
      
      return null;
    } catch (e) {
      print('Error checking cached preview: $e');
      return null;
    }
  }

  /// Save preview to cache
  Future<void> cachePreview(String storyId, String audioPath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final previewDir = Directory('${directory.path}/previews');
      
      if (!await previewDir.exists()) {
        await previewDir.create(recursive: true);
      }

      final sourceFile = File(audioPath);
      final targetFile = File('${previewDir.path}/preview_$storyId.mp3');
      
      await sourceFile.copy(targetFile.path);
    } catch (e) {
      print('Error caching preview: $e');
    }
  }

  /// Clear all cached previews
  Future<void> clearPreviewCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final previewDir = Directory('${directory.path}/previews');
      
      if (await previewDir.exists()) {
        await previewDir.delete(recursive: true);
      }
    } catch (e) {
      print('Error clearing preview cache: $e');
    }
  }

  /// Get preview info
  Map<String, dynamic> getPreviewInfo({required String storyText}) {
    final previewText = _extractPreviewText(storyText, previewDurationSeconds);
    final wordCount = previewText.split(' ').length;
    final estimatedDuration = (wordCount / 2.5).round(); // ~150 wpm = 2.5 words per second

    return {
      'preview_text': previewText,
      'word_count': wordCount,
      'estimated_duration_seconds': estimatedDuration,
      'full_story_word_count': storyText.split(' ').length,
    };
  }
}

