import '../story_tuning/models/emotion_tag.dart';

/// Mood presets that automatically configure emotion sequences and voice settings
enum MoodPreset {
  bedtime('Bedtime', 'Calm and soothing for sleep'),
  adventure('Adventure', 'Exciting and energetic'),
  learning('Learning', 'Clear and engaging for education');

  final String displayName;
  final String description;

  const MoodPreset(this.displayName, this.description);

  /// Get the dominant emotion tags for this mood
  List<EmotionTag> getEmotionSequence() {
    switch (this) {
      case MoodPreset.bedtime:
        return [
          EmotionTag.calm,
          EmotionTag.loving,
          EmotionTag.gentle,
          EmotionTag.whisper,
        ];
      case MoodPreset.adventure:
        return [
          EmotionTag.excited,
          EmotionTag.curious,
          EmotionTag.dramatic,
          EmotionTag.joyful,
        ];
      case MoodPreset.learning:
        return [
          EmotionTag.neutral,
          EmotionTag.curious,
          EmotionTag.thoughtful,
          EmotionTag.joyful,
        ];
    }
  }

  /// Get voice modulation settings for this mood
  Map<String, dynamic> getVoiceModulation() {
    switch (this) {
      case MoodPreset.bedtime:
        return {
          'pitch': 0.95,
          'speed': 0.85,
          'volume': 0.75,
          'stability': 0.6,
          'similarity_boost': 0.85,
          'style_exaggeration': 0.5,
          'rate': 0.9,
        };
      case MoodPreset.adventure:
        return {
          'pitch': 1.08,
          'speed': 1.1,
          'volume': 1.0,
          'stability': 0.35,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.8,
          'rate': 1.05,
        };
      case MoodPreset.learning:
        return {
          'pitch': 1.0,
          'speed': 0.95,
          'volume': 0.95,
          'stability': 0.5,
          'similarity_boost': 0.85,
          'style_exaggeration': 0.6,
          'rate': 1.0,
        };
    }
  }

  /// Get recommended background music category for this mood
  String getBackgroundMusicCategory() {
    switch (this) {
      case MoodPreset.bedtime:
        return 'night';
      case MoodPreset.adventure:
        return 'forest';
      case MoodPreset.learning:
        return 'calm';
    }
  }

  /// Get narration pacing for this mood (words per minute)
  int getNarrationPacing() {
    switch (this) {
      case MoodPreset.bedtime:
        return 110; // Slow, soothing pace
      case MoodPreset.adventure:
        return 150; // Fast, exciting pace
      case MoodPreset.learning:
        return 130; // Moderate, clear pace
    }
  }

  /// Get emphasis level (0.0 - 1.0)
  double getEmphasisLevel() {
    switch (this) {
      case MoodPreset.bedtime:
        return 0.4; // Minimal emphasis
      case MoodPreset.adventure:
        return 0.9; // High emphasis
      case MoodPreset.learning:
        return 0.6; // Moderate emphasis
    }
  }

  /// Get pause duration multiplier
  double getPauseMultiplier() {
    switch (this) {
      case MoodPreset.bedtime:
        return 1.5; // Longer pauses for relaxation
      case MoodPreset.adventure:
        return 0.8; // Shorter pauses for excitement
      case MoodPreset.learning:
        return 1.0; // Standard pauses
    }
  }

  /// Convert to metadata map
  Map<String, dynamic> toMetadata() {
    return {
      'preset_name': name,
      'display_name': displayName,
      'description': description,
      'emotion_sequence': getEmotionSequence().map((e) => e.value).toList(),
      'voice_modulation': getVoiceModulation(),
      'background_music_category': getBackgroundMusicCategory(),
      'narration_pacing_wpm': getNarrationPacing(),
      'emphasis_level': getEmphasisLevel(),
      'pause_multiplier': getPauseMultiplier(),
    };
  }

  /// Create from string name
  static MoodPreset fromString(String name) {
    switch (name.toLowerCase()) {
      case 'bedtime':
        return MoodPreset.bedtime;
      case 'adventure':
        return MoodPreset.adventure;
      case 'learning':
        return MoodPreset.learning;
      default:
        return MoodPreset.bedtime;
    }
  }
}

/// Service to manage mood presets
class MoodPresetService {
  static final MoodPresetService _instance = MoodPresetService._internal();
  factory MoodPresetService() => _instance;
  MoodPresetService._internal();

  /// Apply mood preset to story configuration
  Map<String, dynamic> applyMoodPreset(MoodPreset mood, String storyText) {
    return {
      'mood': mood.name,
      'metadata': mood.toMetadata(),
      'estimated_duration_minutes': _estimateDuration(
        storyText,
        mood.getNarrationPacing(),
      ),
      'suggested_time_of_day': _getSuggestedTimeOfDay(mood),
    };
  }

  /// Estimate story duration based on text and pacing
  int _estimateDuration(String text, int wordsPerMinute) {
    final wordCount = text.split(' ').length;
    final minutes = (wordCount / wordsPerMinute).ceil();
    return minutes.clamp(1, 30);
  }

  /// Get suggested time of day for mood
  List<String> _getSuggestedTimeOfDay(MoodPreset mood) {
    switch (mood) {
      case MoodPreset.bedtime:
        return ['evening', 'night'];
      case MoodPreset.adventure:
        return ['morning', 'afternoon'];
      case MoodPreset.learning:
        return ['morning', 'afternoon'];
    }
  }

  /// Get all available moods
  List<MoodPreset> getAllMoods() {
    return MoodPreset.values;
  }

  /// Get recommended mood based on time of day
  MoodPreset getRecommendedMood() {
    final hour = DateTime.now().hour;
    
    if (hour >= 19 || hour < 6) {
      return MoodPreset.bedtime;
    } else if (hour >= 6 && hour < 12) {
      return MoodPreset.learning;
    } else {
      return MoodPreset.adventure;
    }
  }
}

