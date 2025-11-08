import 'dart:convert';
import '../models/tuned_segment.dart';
import '../models/emotion_tag.dart';
import 'elevenlabs_voice_mapper.dart';

/// Service to combine all tuning outputs into final metadata-rich script
class ScriptEmitterService {
  static final ScriptEmitterService _instance = ScriptEmitterService._internal();
  factory ScriptEmitterService() => _instance;
  ScriptEmitterService._internal();

  final _elevenLabsMapper = ElevenLabsVoiceMapper();

  /// Generate final script from tuned segments
  List<Map<String, dynamic>> generateFinalScript(List<TunedSegment> segments) {
    final script = <Map<String, dynamic>>[];
    
    for (final segment in segments) {
      script.add(segment.toJson());
    }
    
    return script;
  }

  /// Generate script with additional metadata
  Map<String, dynamic> generateEnhancedScript({
    required List<TunedSegment> segments,
    required String storyId,
    required String storyTitle,
    String? userId,
    String? voiceId,
    Map<String, dynamic>? additionalMetadata,
  }) {
    return {
      'story_id': storyId,
      'story_title': storyTitle,
      'user_id': userId,
      'voice_id': voiceId,
      'generated_at': DateTime.now().toIso8601String(),
      'total_segments': segments.length,
      'estimated_duration_seconds': _estimateTotalDuration(segments),
      'emotion_distribution': _getEmotionDistribution(segments),
      'segments': segments.map((s) => s.toJson()).toList(),
      if (additionalMetadata != null) 'metadata': additionalMetadata,
    };
  }

  /// Export script as JSON string
  String exportAsJson(List<TunedSegment> segments, {bool pretty = true}) {
    final script = generateFinalScript(segments);
    
    if (pretty) {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(script);
    } else {
      return jsonEncode(script);
    }
  }

  /// Export script for TTS engines (ElevenLabs, Coqui, etc.)
  Map<String, dynamic> exportForTTS({
    required List<TunedSegment> segments,
    required String engine,
    String? voiceId,
  }) {
    switch (engine.toLowerCase()) {
      case 'elevenlabs':
        return _exportForElevenLabs(segments, voiceId);
      case 'coqui':
        return _exportForCoqui(segments, voiceId);
      case 'google':
        return _exportForGoogleTTS(segments);
      default:
        return _exportGeneric(segments);
    }
  }

  /// Export for ElevenLabs API with emotion-based voice settings
  Map<String, dynamic> _exportForElevenLabs(
    List<TunedSegment> segments,
    String? voiceId,
  ) {
    // For single emotion, use that emotion's settings
    // For multiple, use weighted average or dominant emotion
    final dominantEmotion = _getDominantEmotion(segments);
    final averageIntensity = _getAverageIntensity(segments);
    
    // Get optimized voice settings for dominant emotion
    final voiceSettings = _elevenLabsMapper.getApiVoiceSettings(
      dominantEmotion,
      intensity: averageIntensity,
    );
    
    // Combine text with emotional markers
    final combinedText = segments.map((s) => s.text).join(' ');
    
    return {
      'text': combinedText,
      'voice_id': voiceId,
      'model_id': 'eleven_multilingual_v2',
      'voice_settings': {
        'stability': voiceSettings['stability'],
        'similarity_boost': voiceSettings['similarity_boost'],
        'style': voiceSettings['style_exaggeration'], // ElevenLabs uses 'style' in API
        'use_speaker_boost': true,
      },
      'metadata': {
        'dominant_emotion': dominantEmotion,
        'average_intensity': averageIntensity,
        'playback_rate': voiceSettings['rate'],
      },
      'segments': segments.map((s) {
        // Get emotion-specific settings for each segment
        final segmentSettings = _elevenLabsMapper.getApiVoiceSettings(
          s.emotion,
          intensity: s.intensity,
        );
        return {
          'text': s.text,
          'emotion': s.emotion,
          'intensity': s.intensity,
          'pause_after': s.pauseAfter,
          'voice_settings': {
            'stability': segmentSettings['stability'],
            'similarity_boost': segmentSettings['similarity_boost'],
            'style_exaggeration': segmentSettings['style_exaggeration'],
            'rate': segmentSettings['rate'],
          },
        };
      }).toList(),
    };
  }

  /// Get dominant emotion from segments
  String _getDominantEmotion(List<TunedSegment> segments) {
    if (segments.isEmpty) return 'neutral';
    
    final emotionCounts = <String, int>{};
    for (final segment in segments) {
      emotionCounts[segment.emotion] = (emotionCounts[segment.emotion] ?? 0) + 1;
    }
    
    final sorted = emotionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.first.key;
  }

  /// Get average intensity from segments
  double _getAverageIntensity(List<TunedSegment> segments) {
    if (segments.isEmpty) return 1.0;
    
    final totalIntensity = segments.fold<double>(
      0.0,
      (sum, segment) => sum + segment.intensity,
    );
    
    return totalIntensity / segments.length;
  }

  /// Export for Coqui TTS
  Map<String, dynamic> _exportForCoqui(
    List<TunedSegment> segments,
    String? voiceId,
  ) {
    return {
      'text': segments.map((s) => s.text).join(' '),
      'speaker_id': voiceId,
      'segments': segments.map((s) => {
        'text': s.text,
        'emotion': s.emotion,
        'speed': _getSpeedFromEmotion(s.emotion),
      }).toList(),
    };
  }

  /// Export for Google Cloud TTS
  Map<String, dynamic> _exportForGoogleTTS(List<TunedSegment> segments) {
    final ssmlParts = <String>[];
    
    for (final segment in segments) {
      final emotion = EmotionTag.fromString(segment.emotion);
      final modulation = emotion.getVoiceModulation();
      
      final pitch = (((modulation['pitch'] as double) - 1.0) * 10).toStringAsFixed(1);
      final speed = (modulation['speed'] as double).toStringAsFixed(2);
      
      String ssml = '<prosody rate="$speed" pitch="${pitch}st">${segment.text}</prosody>';
      
      if (segment.pauseAfter != null) {
        ssml += '<break time="${segment.pauseAfter}"/>';
      }
      
      ssmlParts.add(ssml);
    }
    
    return {
      'input': {
        'ssml': '<speak>${ssmlParts.join(' ')}</speak>',
      },
      'voice': {
        'languageCode': 'en-US',
        'name': 'en-US-Neural2-A',
      },
      'audioConfig': {
        'audioEncoding': 'MP3',
      },
    };
  }

  /// Generic export format
  Map<String, dynamic> _exportGeneric(List<TunedSegment> segments) {
    return {
      'text': segments.map((s) => s.text).join(' '),
      'segments': segments.map((s) => s.toJson()).toList(),
    };
  }

  /// Generate SSML-formatted output
  String generateSSML(List<TunedSegment> segments, {String? voiceName}) {
    final buffer = StringBuffer();
    buffer.writeln('<speak>');
    
    if (voiceName != null) {
      buffer.writeln('  <voice name="$voiceName">');
    }
    
    for (final segment in segments) {
      final emotion = EmotionTag.fromString(segment.emotion);
      final modulation = emotion.getVoiceModulation();
      
      final speed = (modulation['speed'] as double).toStringAsFixed(2);
      final pitch = (((modulation['pitch'] as double) - 1.0) * 10).toStringAsFixed(1);
      
      buffer.write('    <prosody rate="$speed" pitch="${pitch}st">');
      
      if (segment.emphasis != null && segment.emphasis! > 0.5) {
        buffer.write('<emphasis level="strong">');
      }
      
      buffer.write(segment.text);
      
      if (segment.emphasis != null && segment.emphasis! > 0.5) {
        buffer.write('</emphasis>');
      }
      
      buffer.write('</prosody>');
      
      if (segment.pauseAfter != null) {
        buffer.write('<break time="${segment.pauseAfter}"/>');
      }
      
      buffer.writeln();
    }
    
    if (voiceName != null) {
      buffer.writeln('  </voice>');
    }
    
    buffer.writeln('</speak>');
    
    return buffer.toString();
  }

  /// Generate plain text (without markup)
  String generatePlainText(List<TunedSegment> segments) {
    return segments.map((s) => s.text).join(' ');
  }

  /// Estimate total duration in seconds
  int _estimateTotalDuration(List<TunedSegment> segments) {
    int totalSeconds = 0;
    
    for (final segment in segments) {
      // Estimate based on word count (average 150 words per minute)
      final wordCount = segment.text.split(' ').length;
      final secondsForText = (wordCount / 150 * 60).ceil();
      
      totalSeconds += secondsForText;
      
      // Add pause time if specified
      if (segment.pauseAfter != null) {
        final pause = _parsePauseDuration(segment.pauseAfter!);
        totalSeconds += pause;
      }
    }
    
    return totalSeconds;
  }

  /// Parse pause duration string to seconds
  int _parsePauseDuration(String pauseStr) {
    final match = RegExp(r'(\d+\.?\d*)s').firstMatch(pauseStr);
    if (match != null) {
      return double.parse(match.group(1)!).ceil();
    }
    return 0;
  }

  /// Get emotion distribution in script
  Map<String, int> _getEmotionDistribution(List<TunedSegment> segments) {
    final distribution = <String, int>{};
    
    for (final segment in segments) {
      distribution[segment.emotion] = (distribution[segment.emotion] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Get speed multiplier from emotion
  double _getSpeedFromEmotion(String emotion) {
    final tag = EmotionTag.fromString(emotion);
    final modulation = tag.getVoiceModulation();
    return modulation['speed'] as double;
  }

  /// Validate script segments
  bool validateScript(List<TunedSegment> segments) {
    if (segments.isEmpty) return false;
    
    for (final segment in segments) {
      if (segment.text.trim().isEmpty) return false;
      if (segment.emotion.isEmpty) return false;
    }
    
    return true;
  }

  /// Get script statistics
  Map<String, dynamic> getScriptStatistics(List<TunedSegment> segments) {
    final totalWords = segments.fold<int>(
      0,
      (sum, s) => sum + s.text.split(' ').length,
    );
    
    final uniqueEmotions = segments.map((s) => s.emotion).toSet();
    
    return {
      'total_segments': segments.length,
      'total_words': totalWords,
      'unique_emotions': uniqueEmotions.length,
      'emotion_list': uniqueEmotions.toList(),
      'estimated_duration_seconds': _estimateTotalDuration(segments),
      'estimated_duration_minutes': (_estimateTotalDuration(segments) / 60).ceil(),
      'average_words_per_segment': (totalWords / segments.length).round(),
    };
  }
}

