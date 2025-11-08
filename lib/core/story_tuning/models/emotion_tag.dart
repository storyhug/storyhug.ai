/// Emotion tags that can be assigned to story segments
enum EmotionTag {
  happy('happy'),
  sad('sad'),
  excited('excited'),
  calm('calm'),
  fearful('fearful'),
  angry('angry'),
  surprised('surprised'),
  neutral('neutral'),
  mysterious('mysterious'),
  joyful('joyful'),
  thoughtful('thoughtful'),
  urgent('urgent'),
  gentle('gentle'),
  dramatic('dramatic'),
  playful('playful'),
  loving('loving'),
  curious('curious'),
  whisper('whisper');

  final String value;
  const EmotionTag(this.value);

  @override
  String toString() => value;

  /// Convert string to EmotionTag
  static EmotionTag fromString(String value) {
    return EmotionTag.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => EmotionTag.neutral,
    );
  }

  /// Get voice modulation parameters for this emotion
  Map<String, dynamic> getVoiceModulation() {
    switch (this) {
      case EmotionTag.happy:
      case EmotionTag.joyful:
        return {'pitch': 1.1, 'speed': 1.05, 'volume': 1.0};
      case EmotionTag.sad:
        return {'pitch': 0.9, 'speed': 0.9, 'volume': 0.85};
      case EmotionTag.excited:
      case EmotionTag.playful:
        return {'pitch': 1.15, 'speed': 1.1, 'volume': 1.05};
      case EmotionTag.calm:
      case EmotionTag.gentle:
        return {'pitch': 1.0, 'speed': 0.95, 'volume': 0.9};
      case EmotionTag.fearful:
        return {'pitch': 1.05, 'speed': 1.0, 'volume': 0.95};
      case EmotionTag.angry:
        return {'pitch': 0.95, 'speed': 1.05, 'volume': 1.1};
      case EmotionTag.surprised:
        return {'pitch': 1.2, 'speed': 1.15, 'volume': 1.0};
      case EmotionTag.mysterious:
        return {'pitch': 0.92, 'speed': 0.88, 'volume': 0.88};
      case EmotionTag.thoughtful:
        return {'pitch': 0.98, 'speed': 0.92, 'volume': 0.92};
      case EmotionTag.urgent:
        return {'pitch': 1.08, 'speed': 1.12, 'volume': 1.05};
      case EmotionTag.dramatic:
        return {'pitch': 0.97, 'speed': 0.95, 'volume': 1.0};
      case EmotionTag.loving:
        return {'pitch': 1.02, 'speed': 0.95, 'volume': 0.95};
      case EmotionTag.curious:
        return {'pitch': 1.08, 'speed': 1.0, 'volume': 1.0};
      case EmotionTag.whisper:
        return {'pitch': 0.95, 'speed': 0.85, 'volume': 0.7};
      case EmotionTag.neutral:
      default:
        return {'pitch': 1.0, 'speed': 1.0, 'volume': 1.0};
    }
  }
}

