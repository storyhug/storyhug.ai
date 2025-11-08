import '../models/pacing_cue.dart';
import '../models/emotion_tag.dart';

/// Service to add pacing tags, pauses, and SSML-like cues for natural narration
class PacingFormatterService {
  static final PacingFormatterService _instance = PacingFormatterService._internal();
  factory PacingFormatterService() => _instance;
  PacingFormatterService._internal();

  /// Add pacing cues to text based on emotion and structure
  String addPacingCues(String text, {EmotionTag? emotion}) {
    final sentences = _splitIntoSentences(text);
    final processedSentences = <String>[];
    
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final isLastSentence = i == sentences.length - 1;
      
      // Process individual sentence
      String processed = _processSentence(sentence, emotion: emotion);
      
      // Add pauses between sentences
      if (!isLastSentence) {
        final pauseDuration = _determinePauseDuration(sentence, sentences[i + 1]);
        processed += ' <break time="$pauseDuration"/>';
      }
      
      processedSentences.add(processed);
    }
    
    return processedSentences.join(' ');
  }

  /// Process individual sentence for pacing
  String _processSentence(String sentence, {EmotionTag? emotion}) {
    String processed = sentence;
    
    // Add emphasis to important words
    processed = _addEmphasis(processed, emotion: emotion);
    
    // Add pauses for dramatic effect
    processed = _addDramaticPauses(processed);
    
    // Add breathing pauses for long sentences
    processed = _addBreathingPauses(processed);
    
    // Adjust speed based on emotion
    if (emotion != null) {
      processed = _applyEmotionalPacing(processed, emotion);
    }
    
    return processed;
  }

  /// Add emphasis to important words
  String _addEmphasis(String text, {EmotionTag? emotion}) {
    final importantWords = [
      'never', 'always', 'must', 'impossible', 'amazing', 'terrible',
      'wonderful', 'horrible', 'incredible', 'unbelievable', 'forever',
      'finally', 'suddenly', 'immediately', 'now', 'victory', 'defeat',
      'triumph', 'disaster', 'hero', 'villain', 'magic', 'sacred',
      'divine', 'powerful', 'mighty', 'legendary'
    ];
    
    String emphasized = text;
    for (final word in importantWords) {
      final pattern = RegExp(r'\b' + word + r'\b', caseSensitive: false);
      if (pattern.hasMatch(emphasized)) {
        emphasized = emphasized.replaceFirst(
          pattern,
          '<emphasis level="strong">$word</emphasis>',
        );
      }
    }
    
    return emphasized;
  }

  /// Add dramatic pauses using ellipsis and punctuation
  String _addDramaticPauses(String text) {
    String processed = text;
    
    // Add pause after ellipsis
    processed = processed.replaceAll('...', '... <break time="0.8s"/>');
    
    // Add pause after em dashes
    processed = processed.replaceAll(' - ', ' <break time="0.3s"/> - <break time="0.3s"/>');
    
    // Add pause after colons
    processed = processed.replaceAll(':', ': <break time="0.5s"/>');
    
    // Add pause after commas (for natural breathing)
    processed = processed.replaceAll(',', ', <break time="0.2s"/>');
    
    return processed;
  }

  /// Add breathing pauses for long sentences
  String _addBreathingPauses(String text) {
    final words = text.split(' ');
    
    // If sentence is too long, add breathing pauses
    if (words.length > 15) {
      final buffer = StringBuffer();
      for (int i = 0; i < words.length; i++) {
        buffer.write(words[i]);
        
        // Add breathing pause every 10-12 words
        if (i > 0 && i % 11 == 0 && i < words.length - 1) {
          buffer.write(' <break strength="weak"/>');
        }
        
        if (i < words.length - 1) {
          buffer.write(' ');
        }
      }
      return buffer.toString();
    }
    
    return text;
  }

  /// Apply emotional pacing adjustments
  String _applyEmotionalPacing(String text, EmotionTag emotion) {
    switch (emotion) {
      case EmotionTag.excited:
      case EmotionTag.urgent:
        return '<prosody rate="fast">$text</prosody>';
      
      case EmotionTag.calm:
      case EmotionTag.gentle:
      case EmotionTag.thoughtful:
        return '<prosody rate="slow">$text</prosody>';
      
      case EmotionTag.mysterious:
      case EmotionTag.dramatic:
        return '<prosody rate="x-slow">$text</prosody>';
      
      case EmotionTag.sad:
        return '<prosody rate="slow" pitch="-10%">$text</prosody>';
      
      case EmotionTag.happy:
      case EmotionTag.joyful:
        return '<prosody rate="medium" pitch="+5%">$text</prosody>';
      
      default:
        return text;
    }
  }

  /// Determine pause duration between sentences
  String _determinePauseDuration(String currentSentence, String nextSentence) {
    // Longer pause after questions
    if (currentSentence.trim().endsWith('?')) {
      return '0.7s';
    }
    
    // Longer pause after exclamations
    if (currentSentence.trim().endsWith('!')) {
      return '0.6s';
    }
    
    // Longer pause before dialogue
    if (nextSentence.trim().startsWith('"') || nextSentence.trim().startsWith("'")) {
      return '0.5s';
    }
    
    // Standard pause
    return '0.4s';
  }

  /// Generate SSML-formatted text
  String generateSSML(String text, {EmotionTag? emotion}) {
    final processed = addPacingCues(text, emotion: emotion);
    
    return '''
<speak>
  <voice name="en-US-Neural2-A">
    $processed
  </voice>
</speak>
'''.trim();
  }

  /// Generate pacing metadata for segments
  List<Map<String, dynamic>> generatePacingMetadata(String text) {
    final sentences = _splitIntoSentences(text);
    final metadata = <Map<String, dynamic>>[];
    
    for (final sentence in sentences) {
      final wordCount = sentence.split(' ').length;
      final hasQuestion = sentence.trim().endsWith('?');
      final hasExclamation = sentence.trim().endsWith('!');
      
      metadata.add({
        'text': sentence,
        'word_count': wordCount,
        'estimated_duration_seconds': wordCount * 0.5, // Rough estimate
        'has_question': hasQuestion,
        'has_exclamation': hasExclamation,
        'recommended_pause_after': _determinePauseDuration(sentence, ''),
      });
    }
    
    return metadata;
  }

  /// Extract pacing cues from text
  List<PacingCue> extractPacingCues(String text) {
    final cues = <PacingCue>[];
    
    // Extract pauses
    final pausePattern = RegExp(r'<break time="([^"]+)"/>');
    final pauseMatches = pausePattern.allMatches(text);
    for (final match in pauseMatches) {
      cues.add(PacingCue(
        type: PacingType.pause,
        duration: match.group(1),
      ));
    }
    
    // Extract emphasis
    final emphasisPattern = RegExp(r'<emphasis level="([^"]+)">');
    final emphasisMatches = emphasisPattern.allMatches(text);
    for (final match in emphasisMatches) {
      final level = match.group(1);
      final strength = level == 'strong' ? 1.0 : 0.5;
      cues.add(PacingCue(
        type: PacingType.emphasis,
        strength: strength,
      ));
    }
    
    return cues;
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    final sentences = <String>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      
      if (i < text.length - 1) {
        final char = text[i];
        final nextChar = text[i + 1];
        
        if ((char == '.' || char == '!' || char == '?') && 
            (nextChar == ' ' || nextChar == '\n')) {
          sentences.add(buffer.toString().trim());
          buffer.clear();
        }
      }
    }
    
    if (buffer.isNotEmpty) {
      sentences.add(buffer.toString().trim());
    }
    
    return sentences.where((s) => s.isNotEmpty).toList();
  }

  /// Clean SSML tags from text (for display purposes)
  String cleanSSMLTags(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

