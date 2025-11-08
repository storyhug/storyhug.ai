/// ElevenLabs API voice settings mapper for emotion-based TTS
/// Maps emotions to exact ElevenLabs API parameters
class ElevenLabsVoiceMapper {
  static final ElevenLabsVoiceMapper _instance = ElevenLabsVoiceMapper._internal();
  factory ElevenLabsVoiceMapper() => _instance;
  ElevenLabsVoiceMapper._internal();

  /// Get ElevenLabs voice settings for a specific emotion
  /// Uses exact API field names: stability, similarity_boost, style_exaggeration, rate
  Map<String, dynamic> getVoiceSettings(String emotion, {double? intensity}) {
    final baseSettings = _getEmotionPreset(emotion.toLowerCase());
    
    // Apply intensity modifier if provided (0.0 - 1.0)
    if (intensity != null && intensity >= 0.0 && intensity <= 1.0) {
      return _applyIntensity(baseSettings, intensity);
    }
    
    return baseSettings;
  }

  /// Get emotion-specific preset with exact ElevenLabs API parameters
  Map<String, dynamic> _getEmotionPreset(String emotion) {
    switch (emotion) {
      case 'calm':
        return {
          'stability': 0.6,
          'similarity_boost': 0.85,
          'style_exaggeration': 0.5,
          'rate': 0.9,
          'note': 'bedtime, slow',
        };

      case 'loving':
        return {
          'stability': 0.5,
          'similarity_boost': 0.9,
          'style_exaggeration': 0.6,
          'rate': 0.95,
          'note': 'warm emphasis',
        };

      case 'excited':
        return {
          'stability': 0.35,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.8,
          'rate': 1.05,
          'note': 'active lines',
        };

      case 'curious':
        return {
          'stability': 0.4,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.7,
          'rate': 1.0,
          'note': 'inquisitive',
        };

      case 'mysterious':
        return {
          'stability': 0.45,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.7,
          'rate': 0.95,
          'note': 'slow, breathy',
        };

      case 'whisper':
        return {
          'stability': 0.7,
          'similarity_boost': 0.9,
          'style_exaggeration': 0.4,
          'rate': 0.85,
          'note': 'speak-soft',
        };

      case 'sad':
        return {
          'stability': 0.6,
          'similarity_boost': 0.85,
          'style_exaggeration': 0.45,
          'rate': 0.9,
          'note': 'gentle tone',
        };

      case 'happy':
      case 'joyful':
        return {
          'stability': 0.45,
          'similarity_boost': 0.85,
          'style_exaggeration': 0.65,
          'rate': 1.0,
          'note': 'cheerful',
        };

      case 'fearful':
        return {
          'stability': 0.55,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.6,
          'rate': 1.05,
          'note': 'tense',
        };

      case 'angry':
        return {
          'stability': 0.4,
          'similarity_boost': 0.75,
          'style_exaggeration': 0.75,
          'rate': 1.1,
          'note': 'intense',
        };

      case 'surprised':
        return {
          'stability': 0.35,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.8,
          'rate': 1.1,
          'note': 'sudden',
        };

      case 'thoughtful':
        return {
          'stability': 0.65,
          'similarity_boost': 0.85,
          'style_exaggeration': 0.5,
          'rate': 0.92,
          'note': 'reflective',
        };

      case 'urgent':
        return {
          'stability': 0.3,
          'similarity_boost': 0.75,
          'style_exaggeration': 0.75,
          'rate': 1.15,
          'note': 'quick',
        };

      case 'dramatic':
        return {
          'stability': 0.5,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.8,
          'rate': 0.95,
          'note': 'theatrical',
        };

      case 'gentle':
        return {
          'stability': 0.65,
          'similarity_boost': 0.9,
          'style_exaggeration': 0.5,
          'rate': 0.93,
          'note': 'soft',
        };

      case 'playful':
        return {
          'stability': 0.4,
          'similarity_boost': 0.8,
          'style_exaggeration': 0.7,
          'rate': 1.05,
          'note': 'fun',
        };

      case 'neutral':
      default:
        return {
          'stability': 0.5,
          'similarity_boost': 0.75,
          'style_exaggeration': 0.5,
          'rate': 1.0,
          'note': 'default',
        };
    }
  }

  /// Apply intensity modifier to voice settings
  /// Intensity ranges from 0.0 (subtle) to 1.0 (maximum)
  Map<String, dynamic> _applyIntensity(Map<String, dynamic> baseSettings, double intensity) {
    final settings = Map<String, dynamic>.from(baseSettings);
    
    // Intensity affects style_exaggeration primarily
    final baseExaggeration = settings['style_exaggeration'] as double;
    final baseRate = settings['rate'] as double;
    
    // Scale exaggeration based on intensity
    settings['style_exaggeration'] = baseExaggeration * (0.5 + (intensity * 0.5));
    
    // Slightly adjust rate based on intensity for emotional impact
    if (baseRate > 1.0) {
      // For fast emotions, intensity increases speed slightly
      settings['rate'] = baseRate + (intensity * 0.1);
    } else if (baseRate < 1.0) {
      // For slow emotions, intensity decreases speed slightly
      settings['rate'] = baseRate - (intensity * 0.05);
    }
    
    // Clamp values to safe ranges
    settings['stability'] = (settings['stability'] as double).clamp(0.0, 1.0);
    settings['similarity_boost'] = (settings['similarity_boost'] as double).clamp(0.0, 1.0);
    settings['style_exaggeration'] = (settings['style_exaggeration'] as double).clamp(0.0, 1.0);
    settings['rate'] = (settings['rate'] as double).clamp(0.5, 2.0);
    
    return settings;
  }

  /// Get clean voice settings for API request (without 'note' field)
  Map<String, dynamic> getApiVoiceSettings(String emotion, {double? intensity}) {
    final settings = getVoiceSettings(emotion, intensity: intensity);
    settings.remove('note'); // Remove documentation field
    return settings;
  }

  /// Format settings for ElevenLabs API payload
  Map<String, dynamic> formatForElevenLabs({
    required String text,
    required String voiceId,
    required String emotion,
    double? intensity,
    String? modelId,
  }) {
    final voiceSettings = getApiVoiceSettings(emotion, intensity: intensity);
    
    return {
      'text': text,
      'voice_id': voiceId,
      'model_id': modelId ?? 'eleven_multilingual_v2',
      'voice_settings': {
        'stability': voiceSettings['stability'],
        'similarity_boost': voiceSettings['similarity_boost'],
        'style': voiceSettings['style_exaggeration'], // ElevenLabs uses 'style' in API
        'use_speaker_boost': true,
      },
      // Store full settings in metadata for reference
      'metadata': {
        'emotion': emotion,
        'intensity': intensity ?? 1.0,
        'rate': voiceSettings['rate'],
      },
    };
  }

  /// Get all available emotion presets
  List<String> getAvailableEmotions() {
    return [
      'calm',
      'loving',
      'excited',
      'curious',
      'mysterious',
      'whisper',
      'sad',
      'happy',
      'joyful',
      'fearful',
      'angry',
      'surprised',
      'thoughtful',
      'urgent',
      'dramatic',
      'gentle',
      'playful',
      'neutral',
    ];
  }

  /// Get preset documentation
  String getPresetDocumentation(String emotion) {
    final settings = getVoiceSettings(emotion);
    return '''
Emotion: $emotion
Stability: ${settings['stability']}
Similarity Boost: ${settings['similarity_boost']}
Style Exaggeration: ${settings['style_exaggeration']}
Playback Rate: ${settings['rate']}
Note: ${settings['note']}
''';
  }

  /// Validate emotion exists
  bool isValidEmotion(String emotion) {
    return getAvailableEmotions().contains(emotion.toLowerCase());
  }

  /// Get recommended emotion for text analysis
  String getRecommendedEmotion(String text) {
    // Simple keyword-based recommendation
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('love') || lowerText.contains('hug')) return 'loving';
    if (lowerText.contains('quiet') || lowerText.contains('sleep')) return 'calm';
    if (lowerText.contains('excited') || lowerText.contains('yay')) return 'excited';
    if (lowerText.contains('wonder') || lowerText.contains('curious')) return 'curious';
    if (lowerText.contains('mystery') || lowerText.contains('secret')) return 'mysterious';
    if (lowerText.contains('whisper') || lowerText.contains('shh')) return 'whisper';
    if (lowerText.contains('sad') || lowerText.contains('cry')) return 'sad';
    
    return 'neutral';
  }
}

