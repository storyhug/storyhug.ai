/// Pacing and rhythm cues for narration
class PacingCue {
  final PacingType type;
  final String? duration;
  final double? strength;

  PacingCue({
    required this.type,
    this.duration,
    this.strength,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      if (duration != null) 'duration': duration,
      if (strength != null) 'strength': strength,
    };
  }

  factory PacingCue.fromJson(Map<String, dynamic> json) {
    return PacingCue(
      type: PacingType.fromString(json['type']),
      duration: json['duration'],
      strength: json['strength']?.toDouble(),
    );
  }

  /// Convert to SSML-like tag
  String toSSML() {
    switch (type) {
      case PacingType.pause:
        return '<break time="${duration ?? '0.5s'}"/>';
      case PacingType.emphasis:
        final level = strength != null && strength! > 0.7 ? 'strong' : 'moderate';
        return '<emphasis level="$level">';
      case PacingType.endEmphasis:
        return '</emphasis>';
      case PacingType.speedUp:
        return '<prosody rate="fast">';
      case PacingType.slowDown:
        return '<prosody rate="slow">';
      case PacingType.endProsody:
        return '</prosody>';
      case PacingType.breathe:
        return '<break strength="weak"/>';
    }
  }
}

/// Types of pacing modifications
enum PacingType {
  pause('pause'),
  emphasis('emphasis'),
  endEmphasis('end_emphasis'),
  speedUp('speed_up'),
  slowDown('slow_down'),
  endProsody('end_prosody'),
  breathe('breathe');

  final String value;
  const PacingType(this.value);

  @override
  String toString() => value;

  static PacingType fromString(String value) {
    return PacingType.values.firstWhere(
      (e) => e.value == value.toLowerCase(),
      orElse: () => PacingType.pause,
    );
  }
}

