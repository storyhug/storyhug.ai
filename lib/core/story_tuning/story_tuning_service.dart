import 'models/tuned_segment.dart';
import 'models/emotion_tag.dart';
import 'services/emotion_mapper_service.dart';
import 'services/descriptive_expander_service.dart';
import 'services/pacing_formatter_service.dart';
import 'services/personalizer_service.dart';
import 'services/script_emitter_service.dart';

/// Main orchestrator for story tuning pipeline
/// Combines emotion mapping, descriptive expansion, pacing, and personalization
class StoryTuningService {
  static final StoryTuningService _instance = StoryTuningService._internal();
  factory StoryTuningService() => _instance;
  StoryTuningService._internal();

  final _emotionMapper = EmotionMapperService();
  final _descriptiveExpander = DescriptiveExpanderService();
  final _pacingFormatter = PacingFormatterService();
  final _personalizer = PersonalizerService();
  final _scriptEmitter = ScriptEmitterService();

  /// Process a story through the complete tuning pipeline
  Future<List<TunedSegment>> tuneStory({
    required String storyText,
    String? userId,
    String? childName,
    String? parentName,
    bool enableExpansion = true,
    bool enablePersonalization = true,
    bool enablePacing = true,
  }) async {
    try {
      print('🎯 Starting story tuning pipeline...');
      
      // Step 1: Personalize the story text
      String processedText = storyText;
      if (enablePersonalization) {
        print('👤 Personalizing story...');
        processedText = await _personalizer.personalizeText(
          storyText,
          userId: userId,
          childName: childName,
          parentName: parentName,
        );
      }
      
      // Step 2: Expand descriptions (if enabled)
      if (enableExpansion) {
        print('📝 Expanding descriptions...');
        processedText = await _descriptiveExpander.expandText(processedText);
      }
      
      // Step 3: Split into sentences and analyze emotions with intensity
      print('🎭 Analyzing emotions and intensity...');
      final emotionAnalysis = _emotionMapper.analyzeText(processedText);
      
      // Step 4: Create tuned segments
      print('🎵 Creating tuned segments...');
      final segments = <TunedSegment>[];
      
      for (final analysis in emotionAnalysis) {
        final sentence = analysis['sentence'] as String;
        final emotionTag = analysis['emotion_tag'] as EmotionTag;
        final modulation = analysis['modulation'] as Map<String, dynamic>;
        
        // Calculate emotion intensity
        final intensityAnalysis = _emotionMapper.analyzeEmotionWithIntensity(sentence);
        final intensity = intensityAnalysis['intensity'] as double;
        
        // Apply pacing if enabled
        String tunedText = sentence;
        if (enablePacing) {
          tunedText = _pacingFormatter.addPacingCues(
            sentence,
            emotion: emotionTag,
          );
        }
        
        // Create tuned segment with intensity
        final segment = TunedSegment(
          text: tunedText,
          emotion: emotionTag.value,
          intensity: intensity,
          pauseAfter: _determinePauseAfter(sentence),
          voiceStyle: _determineVoiceStyle(emotionTag),
          emphasis: _determineEmphasis(sentence, emotionTag),
          metadata: {
            'modulation': modulation,
            'word_count': sentence.split(' ').length,
            'intensity': intensity,
          },
        );
        
        segments.add(segment);
      }
      
      print('✅ Story tuning complete! Generated ${segments.length} segments');
      return segments;
      
    } catch (e) {
      print('❌ Error tuning story: $e');
      rethrow;
    }
  }

  /// Tune story and generate final script
  Future<Map<String, dynamic>> tuneStoryWithScript({
    required String storyId,
    required String storyTitle,
    required String storyText,
    String? userId,
    String? childName,
    String? parentName,
    String? voiceId,
    bool enableExpansion = true,
    bool enablePersonalization = true,
    bool enablePacing = true,
  }) async {
    final segments = await tuneStory(
      storyText: storyText,
      userId: userId,
      childName: childName,
      parentName: parentName,
      enableExpansion: enableExpansion,
      enablePersonalization: enablePersonalization,
      enablePacing: enablePacing,
    );
    
    final script = _scriptEmitter.generateEnhancedScript(
      segments: segments,
      storyId: storyId,
      storyTitle: storyTitle,
      userId: userId,
      voiceId: voiceId,
    );
    
    return script;
  }

  /// Generate audio-ready script for TTS engine
  Future<Map<String, dynamic>> generateTTSScript({
    required String storyText,
    required String engine,
    String? userId,
    String? childName,
    String? parentName,
    String? voiceId,
  }) async {
    final segments = await tuneStory(
      storyText: storyText,
      userId: userId,
      childName: childName,
      parentName: parentName,
    );
    
    return _scriptEmitter.exportForTTS(
      segments: segments,
      engine: engine,
      voiceId: voiceId,
    );
  }

  /// Quick tune with minimal processing (for preview)
  Future<List<TunedSegment>> quickTune(String storyText) async {
    return await tuneStory(
      storyText: storyText,
      enableExpansion: false,
      enablePersonalization: false,
      enablePacing: true,
    );
  }

  /// Get emotion analysis only (no tuning)
  List<Map<String, dynamic>> analyzeEmotions(String storyText) {
    return _emotionMapper.analyzeText(storyText);
  }

  /// Get pacing metadata only
  List<Map<String, dynamic>> analyzePacing(String storyText) {
    return _pacingFormatter.generatePacingMetadata(storyText);
  }

  /// Generate SSML output
  Future<String> generateSSML({
    required String storyText,
    String? userId,
    String? childName,
    String? parentName,
    String? voiceName,
  }) async {
    final segments = await tuneStory(
      storyText: storyText,
      userId: userId,
      childName: childName,
      parentName: parentName,
    );
    
    return _scriptEmitter.generateSSML(segments, voiceName: voiceName);
  }

  /// Validate tuned segments
  bool validateTunedSegments(List<TunedSegment> segments) {
    return _scriptEmitter.validateScript(segments);
  }

  /// Get tuning statistics
  Map<String, dynamic> getTuningStatistics(List<TunedSegment> segments) {
    return _scriptEmitter.getScriptStatistics(segments);
  }

  /// Export tuned story as JSON
  String exportAsJson(List<TunedSegment> segments, {bool pretty = true}) {
    return _scriptEmitter.exportAsJson(segments, pretty: pretty);
  }

  /// Determine pause duration after sentence
  String _determinePauseAfter(String sentence) {
    if (sentence.trim().endsWith('?')) return '0.7s';
    if (sentence.trim().endsWith('!')) return '0.6s';
    if (sentence.contains('...')) return '0.8s';
    return '0.4s';
  }

  /// Determine voice style based on emotion
  String _determineVoiceStyle(EmotionTag emotion) {
    switch (emotion) {
      case EmotionTag.excited:
      case EmotionTag.joyful:
        return 'enthusiastic';
      case EmotionTag.calm:
      case EmotionTag.gentle:
        return 'soothing';
      case EmotionTag.sad:
        return 'melancholic';
      case EmotionTag.fearful:
        return 'tense';
      case EmotionTag.angry:
        return 'intense';
      case EmotionTag.mysterious:
        return 'whispered';
      case EmotionTag.dramatic:
        return 'theatrical';
      default:
        return 'narrative';
    }
  }

  /// Determine emphasis level for sentence
  double _determineEmphasis(String sentence, EmotionTag emotion) {
    // Check for emphasis keywords
    final emphasisKeywords = [
      'never', 'always', 'must', 'incredible', 'amazing',
      'terrible', 'suddenly', 'finally', 'victory', 'defeat'
    ];
    
    final lowerSentence = sentence.toLowerCase();
    final hasEmphasisWord = emphasisKeywords.any(
      (word) => lowerSentence.contains(word),
    );
    
    if (hasEmphasisWord) return 1.0;
    
    // Emotional emphasis
    switch (emotion) {
      case EmotionTag.excited:
      case EmotionTag.angry:
      case EmotionTag.surprised:
        return 0.8;
      case EmotionTag.dramatic:
      case EmotionTag.urgent:
        return 0.7;
      default:
        return 0.3;
    }
  }

  /// Clear all caches
  void clearCaches() {
    _descriptiveExpander.clearCache();
    print('✅ All caches cleared');
  }

  /// Get cache statistics
  Map<String, dynamic> getCacheStatistics() {
    return {
      'expansion_cache_size': _descriptiveExpander.getCacheSize(),
    };
  }

  // Expose individual services for advanced usage
  EmotionMapperService get emotionMapper => _emotionMapper;
  DescriptiveExpanderService get descriptiveExpander => _descriptiveExpander;
  PacingFormatterService get pacingFormatter => _pacingFormatter;
  PersonalizerService get personalizer => _personalizer;
  ScriptEmitterService get scriptEmitter => _scriptEmitter;
}

