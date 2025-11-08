/// Represents a single tuned story segment with emotion, pacing, and personalization
class TunedSegment {
  final String text;
  final String emotion;
  final double intensity; // Emotion intensity from 0.0 (subtle) to 1.0 (maximum)
  final String? pauseAfter;
  final String? voiceStyle;
  final double? emphasis;
  final String? customVoiceHint;
  final Map<String, dynamic>? metadata;

  TunedSegment({
    required this.text,
    required this.emotion,
    this.intensity = 1.0, // Default to full intensity
    this.pauseAfter,
    this.voiceStyle,
    this.emphasis,
    this.customVoiceHint,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'emotion': emotion,
      'intensity': intensity,
      if (pauseAfter != null) 'pause_after': pauseAfter,
      if (voiceStyle != null) 'voice_style': voiceStyle,
      if (emphasis != null) 'emphasis': emphasis,
      if (customVoiceHint != null) 'custom_voice_hint': customVoiceHint,
      if (metadata != null) 'metadata': metadata,
    };
  }

  factory TunedSegment.fromJson(Map<String, dynamic> json) {
    return TunedSegment(
      text: json['text'],
      emotion: json['emotion'],
      intensity: json['intensity']?.toDouble() ?? 1.0,
      pauseAfter: json['pause_after'],
      voiceStyle: json['voice_style'],
      emphasis: json['emphasis']?.toDouble(),
      customVoiceHint: json['custom_voice_hint'],
      metadata: json['metadata'],
    );
  }

  TunedSegment copyWith({
    String? text,
    String? emotion,
    double? intensity,
    String? pauseAfter,
    String? voiceStyle,
    double? emphasis,
    String? customVoiceHint,
    Map<String, dynamic>? metadata,
  }) {
    return TunedSegment(
      text: text ?? this.text,
      emotion: emotion ?? this.emotion,
      intensity: intensity ?? this.intensity,
      pauseAfter: pauseAfter ?? this.pauseAfter,
      voiceStyle: voiceStyle ?? this.voiceStyle,
      emphasis: emphasis ?? this.emphasis,
      customVoiceHint: customVoiceHint ?? this.customVoiceHint,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'TunedSegment(text: $text, emotion: $emotion, pauseAfter: $pauseAfter, voiceStyle: $voiceStyle)';
  }
}

