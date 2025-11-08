import '../../../shared/models/story.dart';
import '../../../features/voice_cloning/services/voice_cloning_service.dart';
import '../story_tuning_service.dart';
import '../models/tuned_segment.dart';

/// Helper class to integrate StoryTuning with Voice Cloning and Audio Player services
class AudioIntegrationHelper {
  static final AudioIntegrationHelper _instance = AudioIntegrationHelper._internal();
  factory AudioIntegrationHelper() => _instance;
  AudioIntegrationHelper._internal();

  final _storyTuningService = StoryTuningService();
  final _voiceCloningService = VoiceCloningService();

  /// Process a story and generate personalized audio with emotion and pacing
  Future<String> generatePersonalizedStoryAudio({
    required Story story,
    required String userId,
    String? voiceId,
    String? childName,
    String? parentName,
    bool useStoryTuning = true,
  }) async {
    try {
      print('🎯 Generating personalized story audio with tuning...');
      
      if (!useStoryTuning) {
        // Fallback to existing voice cloning without tuning
        return await _generateSimpleAudio(story, userId, voiceId);
      }

      // Step 1: Tune the story
      print('📝 Tuning story: ${story.title}');
      final tunedSegments = await _storyTuningService.tuneStory(
        storyText: story.body,
        userId: userId,
        childName: childName,
        parentName: parentName,
        enableExpansion: true,
        enablePersonalization: true,
        enablePacing: true,
      );

      // Step 2: Generate TTS script
      print('🎵 Generating TTS script...');
      final ttsScript = _storyTuningService.scriptEmitter.exportForTTS(
        segments: tunedSegments,
        engine: 'elevenlabs',
        voiceId: voiceId,
      );

      // Step 3: Get the enhanced text with SSML
      final enhancedText = _storyTuningService.scriptEmitter.generateSSML(
        tunedSegments,
        voiceName: 'en-US-Neural2-A',
      );

      // Step 4: Generate audio using voice cloning service
      print('🎤 Generating audio with cloned voice...');
      
      // Determine the voice to use
      final effectiveVoiceId = voiceId ?? await _voiceCloningService.getVoiceId(userId);
      
      if (effectiveVoiceId == null) {
        throw Exception('No voice ID available for user');
      }

      // Generate audio with expressive narration
      final audioUrl = await _generateTunedAudio(
        voiceId: effectiveVoiceId,
        tunedSegments: tunedSegments,
        story: story,
      );

      print('✅ Audio generation complete: $audioUrl');
      return audioUrl;

    } catch (e) {
      print('❌ Error generating personalized audio: $e');
      // Fallback to simple audio generation
      return await _generateSimpleAudio(story, userId, voiceId);
    }
  }

  /// Generate audio from tuned segments
  Future<String> _generateTunedAudio({
    required String voiceId,
    required List<TunedSegment> tunedSegments,
    required Story story,
  }) async {
    // Combine all tuned segments into enhanced text
    final combinedText = tunedSegments.map((s) => s.text).join(' ');
    
    // Clean SSML tags for basic TTS (if engine doesn't support SSML)
    final cleanText = _storyTuningService.pacingFormatter.cleanSSMLTags(combinedText);

    // Generate audio using voice cloning service
    return await _voiceCloningService.generateAudioWithClonedVoice(
      voiceId: voiceId,
      text: cleanText,
      fileName: 'tuned_${story.id}_${DateTime.now().millisecondsSinceEpoch}.mp3',
      speakingRate: 0.15, // Slow speed for storytelling
    );
  }

  /// Simple audio generation without tuning (fallback)
  Future<String> _generateSimpleAudio(Story story, String userId, String? voiceId) async {
    print('⚠️ Using simple audio generation (no tuning)');
    
    final effectiveVoiceId = voiceId ?? await _voiceCloningService.getVoiceId(userId);
    
    if (effectiveVoiceId == null) {
      throw Exception('No voice ID available for user');
    }

    return await _voiceCloningService.generateAudioWithClonedVoice(
      voiceId: effectiveVoiceId,
      text: story.body,
      fileName: 'story_${story.id}.mp3',
      speakingRate: 0.15,
    );
  }

  /// Generate audio segments separately (for fine-grained control)
  Future<List<String>> generateSegmentedAudio({
    required List<TunedSegment> segments,
    required String voiceId,
  }) async {
    final audioUrls = <String>[];

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final cleanText = _storyTuningService.pacingFormatter.cleanSSMLTags(segment.text);
      
      try {
        final audioUrl = await _voiceCloningService.generateAudioWithClonedVoice(
          voiceId: voiceId,
          text: cleanText,
          fileName: 'segment_${i}_${DateTime.now().millisecondsSinceEpoch}.mp3',
          speakingRate: 0.15,
        );
        
        audioUrls.add(audioUrl);
      } catch (e) {
        print('⚠️ Error generating segment $i: $e');
        // Continue with other segments
      }
    }

    return audioUrls;
  }

  /// Quick preview of tuned story (first 3 sentences only)
  Future<String> generateQuickPreview({
    required Story story,
    required String userId,
    String? voiceId,
  }) async {
    // Get first few sentences only
    final sentences = story.body.split(RegExp(r'[.!?]'));
    final previewText = sentences.take(3).join('. ') + '.';

    // Quick tune (minimal processing)
    final segments = await _storyTuningService.quickTune(previewText);
    
    final combinedText = segments.map((s) => s.text).join(' ');
    final cleanText = _storyTuningService.pacingFormatter.cleanSSMLTags(combinedText);

    final effectiveVoiceId = voiceId ?? await _voiceCloningService.getVoiceId(userId);
    
    if (effectiveVoiceId == null) {
      throw Exception('No voice ID available for preview');
    }

    return await _voiceCloningService.generateAudioWithClonedVoice(
      voiceId: effectiveVoiceId,
      text: cleanText,
      fileName: 'preview_${story.id}.mp3',
      speakingRate: 0.15,
    );
  }

  /// Get emotion-based audio settings
  Map<String, dynamic> getEmotionBasedSettings(String emotion) {
    final emotionTag = _storyTuningService.emotionMapper.analyzeEmotion(emotion);
    return emotionTag.getVoiceModulation();
  }

  /// Validate that story is ready for tuned audio generation
  bool isStoryReadyForTuning(Story story) {
    if (story.body.isEmpty) return false;
    if (story.body.length < 50) return false; // Too short
    
    // Check if story has enough content
    final sentences = story.body.split(RegExp(r'[.!?]'));
    return sentences.length >= 3;
  }

  /// Estimate audio duration after tuning
  Future<int> estimateTunedAudioDuration(String storyText) async {
    final segments = await _storyTuningService.quickTune(storyText);
    final stats = _storyTuningService.getTuningStatistics(segments);
    return stats['estimated_duration_seconds'] as int;
  }

  /// Cache management
  void clearAllCaches() {
    _storyTuningService.clearCaches();
  }

  Map<String, dynamic> getCacheStats() {
    return _storyTuningService.getCacheStatistics();
  }
}

