import '../models/emotion_tag.dart';

/// Service to analyze text and assign emotion tags
class EmotionMapperService {
  static final EmotionMapperService _instance = EmotionMapperService._internal();
  factory EmotionMapperService() => _instance;
  EmotionMapperService._internal();

  /// Analyze a sentence and determine its emotional tone
  /// Returns a map with 'emotion' and 'intensity' (0.0-1.0)
  Map<String, dynamic> analyzeEmotionWithIntensity(String sentence) {
    final emotion = analyzeEmotion(sentence);
    final intensity = _calculateIntensity(sentence, emotion);
    return {
      'emotion': emotion,
      'intensity': intensity,
    };
  }

  /// Analyze a sentence and determine its emotional tone
  EmotionTag analyzeEmotion(String sentence) {
    final lowerSentence = sentence.toLowerCase();
    
    // Check for excited/joyful emotions
    if (_containsAny(lowerSentence, [
      'yay', 'hooray', 'wonderful', 'amazing', 'fantastic', 'excellent',
      'thrilled', 'delighted', 'excited', 'celebration', 'victory',
      'triumph', 'won', 'succeeded', 'achieved'
    ])) {
      return EmotionTag.excited;
    }

    // Check for happy/joyful emotions
    if (_containsAny(lowerSentence, [
      'happy', 'joy', 'smile', 'laugh', 'cheerful', 'pleased',
      'glad', 'merry', 'bright', 'sunny', 'fun', 'playful'
    ])) {
      return EmotionTag.happy;
    }

    // Check for sad emotions
    if (_containsAny(lowerSentence, [
      'sad', 'cry', 'tear', 'sorrow', 'grief', 'mourn',
      'unhappy', 'depressed', 'gloomy', 'melancholy', 'weep',
      'disappointed', 'heartbroken'
    ])) {
      return EmotionTag.sad;
    }

    // Check for fearful emotions
    if (_containsAny(lowerSentence, [
      'afraid', 'fear', 'scared', 'terrified', 'frightened',
      'anxious', 'worried', 'nervous', 'trembled', 'shook',
      'panic', 'horror', 'dread'
    ])) {
      return EmotionTag.fearful;
    }

    // Check for angry emotions
    if (_containsAny(lowerSentence, [
      'angry', 'rage', 'furious', 'mad', 'irritated',
      'annoyed', 'frustrated', 'outraged', 'wrath', 'fury',
      'shouted', 'yelled', 'screamed'
    ])) {
      return EmotionTag.angry;
    }

    // Check for surprised emotions
    if (_containsAny(lowerSentence, [
      'surprise', 'astonished', 'amazed', 'shocked', 'stunned',
      'startled', 'wow', 'gasp', 'unexpected', 'suddenly',
      'never expected'
    ])) {
      return EmotionTag.surprised;
    }

    // Check for mysterious emotions
    if (_containsAny(lowerSentence, [
      'mysterious', 'secret', 'hidden', 'unknown', 'enigma',
      'whisper', 'shadow', 'dark', 'mysterious', 'strange',
      'curious', 'wonder'
    ])) {
      return EmotionTag.mysterious;
    }

    // Check for calm/gentle emotions
    if (_containsAny(lowerSentence, [
      'calm', 'peaceful', 'serene', 'tranquil', 'quiet',
      'gentle', 'soft', 'soothing', 'relaxed', 'still',
      'meditation', 'breathe'
    ])) {
      return EmotionTag.calm;
    }

    // Check for thoughtful emotions
    if (_containsAny(lowerSentence, [
      'thought', 'pondered', 'considered', 'reflected',
      'wondered', 'contemplated', 'realized', 'understood',
      'wisdom', 'insight'
    ])) {
      return EmotionTag.thoughtful;
    }

    // Check for urgent emotions
    if (_containsAny(lowerSentence, [
      'urgent', 'hurry', 'quick', 'fast', 'immediately',
      'now', 'rush', 'emergency', 'critical', 'vital',
      'must', 'quickly'
    ])) {
      return EmotionTag.urgent;
    }

    // Check for dramatic emotions
    if (_containsAny(lowerSentence, [
      'dramatic', 'intense', 'powerful', 'mighty', 'grand',
      'magnificent', 'epic', 'legendary', 'heroic', 'noble'
    ])) {
      return EmotionTag.dramatic;
    }

    // Check for playful emotions
    if (_containsAny(lowerSentence, [
      'play', 'game', 'fun', 'giggle', 'silly', 'mischief',
      'tease', 'joke', 'trick', 'prank'
    ])) {
      return EmotionTag.playful;
    }

    // Check for loving emotions
    if (_containsAny(lowerSentence, [
      'love', 'hug', 'embrace', 'affection', 'tender', 'care',
      'cherish', 'adore', 'warmth', 'cuddle', 'sweet', 'dear'
    ])) {
      return EmotionTag.loving;
    }

    // Check for curious emotions
    if (_containsAny(lowerSentence, [
      'curious', 'wonder', 'how', 'why', 'what if', 'interesting',
      'explore', 'discover', 'question', 'investigate', 'puzzle'
    ])) {
      return EmotionTag.curious;
    }

    // Check for whisper emotions
    if (_containsAny(lowerSentence, [
      'whisper', 'shh', 'quietly', 'softly', 'hush', 'secret',
      'silent', 'murmur', 'gentle voice', 'low voice'
    ])) {
      return EmotionTag.whisper;
    }

    // Check for punctuation-based emotions
    if (sentence.endsWith('!')) {
      return EmotionTag.excited;
    }
    if (sentence.endsWith('?')) {
      return EmotionTag.thoughtful;
    }
    if (sentence.contains('...')) {
      return EmotionTag.mysterious;
    }

    // Default to neutral
    return EmotionTag.neutral;
  }

  /// Analyze multiple sentences and return emotion map
  Map<String, EmotionTag> analyzeSentences(List<String> sentences) {
    final Map<String, EmotionTag> emotionMap = {};
    
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();
      if (sentence.isNotEmpty) {
        emotionMap[sentence] = analyzeEmotion(sentence);
      }
    }
    
    return emotionMap;
  }

  /// Analyze full text and return metadata
  List<Map<String, dynamic>> analyzeText(String text) {
    final sentences = _splitIntoSentences(text);
    final List<Map<String, dynamic>> results = [];
    
    for (final sentence in sentences) {
      if (sentence.trim().isEmpty) continue;
      
      final emotion = analyzeEmotion(sentence);
      results.add({
        'sentence': sentence,
        'emotion': emotion.value,
        'emotion_tag': emotion,
        'modulation': emotion.getVoiceModulation(),
      });
    }
    
    return results;
  }

  /// Split text into sentences intelligently
  List<String> _splitIntoSentences(String text) {
    // Split by common sentence endings, but preserve them
    final sentences = <String>[];
    final buffer = StringBuffer();
    
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      
      if (i < text.length - 1) {
        final char = text[i];
        final nextChar = text[i + 1];
        
        // Sentence ending detection
        if ((char == '.' || char == '!' || char == '?') && 
            (nextChar == ' ' || nextChar == '\n')) {
          sentences.add(buffer.toString().trim());
          buffer.clear();
        }
      }
    }
    
    // Add remaining text
    if (buffer.isNotEmpty) {
      sentences.add(buffer.toString().trim());
    }
    
    return sentences.where((s) => s.isNotEmpty).toList();
  }

  /// Helper to check if text contains any of the given keywords
  bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  /// Get emotion distribution statistics
  Map<String, int> getEmotionDistribution(String text) {
    final analyzed = analyzeText(text);
    final Map<String, int> distribution = {};
    
    for (final item in analyzed) {
      final emotion = item['emotion'] as String;
      distribution[emotion] = (distribution[emotion] ?? 0) + 1;
    }
    
    return distribution;
  }

  /// Get dominant emotion in text
  EmotionTag getDominantEmotion(String text) {
    final distribution = getEmotionDistribution(text);
    
    if (distribution.isEmpty) return EmotionTag.neutral;
    
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return EmotionTag.fromString(sorted.first.key);
  }

  /// Calculate emotion intensity based on text features
  /// Returns a value from 0.0 (subtle) to 1.0 (maximum intensity)
  double _calculateIntensity(String sentence, EmotionTag emotion) {
    double intensity = 0.7; // Base intensity
    
    // Check for exclamation marks (increases intensity)
    final exclamationCount = sentence.split('!').length - 1;
    intensity += exclamationCount * 0.1;
    
    // Check for ALL CAPS words (increases intensity)
    final words = sentence.split(' ');
    final capsWords = words.where((w) => w.isNotEmpty && w == w.toUpperCase() && w.length > 2).length;
    intensity += (capsWords / words.length) * 0.2;
    
    // Check for intensifying adverbs
    final intensifiers = [
      'very', 'extremely', 'incredibly', 'so', 'really', 'absolutely',
      'completely', 'utterly', 'totally', 'quite', 'highly'
    ];
    final lowerSentence = sentence.toLowerCase();
    final hasIntensifier = intensifiers.any((word) => lowerSentence.contains(word));
    if (hasIntensifier) intensity += 0.15;
    
    // Check for repetition (e.g., "very very")
    if (lowerSentence.contains(RegExp(r'(\w+)\s+\1'))) {
      intensity += 0.1;
    }
    
    // Reduce intensity for whisper/calm emotions
    if (emotion == EmotionTag.whisper || emotion == EmotionTag.calm || emotion == EmotionTag.gentle) {
      intensity *= 0.7;
    }
    
    // Increase intensity for urgent/excited emotions
    if (emotion == EmotionTag.urgent || emotion == EmotionTag.excited || emotion == EmotionTag.angry) {
      intensity *= 1.1;
    }
    
    // Clamp to valid range
    return intensity.clamp(0.0, 1.0);
  }
}

