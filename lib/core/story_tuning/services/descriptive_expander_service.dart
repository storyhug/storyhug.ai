import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config/environment.dart';

/// Service to enhance and expand story text for vivid narration
class DescriptiveExpanderService {
  static final DescriptiveExpanderService _instance = DescriptiveExpanderService._internal();
  factory DescriptiveExpanderService() => _instance;
  DescriptiveExpanderService._internal();

  // Cache for expanded content to avoid redundant API calls
  final Map<String, String> _expansionCache = {};

  /// Expand a sentence to make it more vivid and engaging
  Future<String> expandSentence(String sentence, {String? context}) async {
    // Check cache first
    final cacheKey = '$sentence|$context';
    if (_expansionCache.containsKey(cacheKey)) {
      return _expansionCache[cacheKey]!;
    }

    try {
      // For now, use rule-based expansion
      // In production, integrate with GPT or another LLM
      final expanded = _ruleBasedExpansion(sentence, context: context);
      
      // Cache the result
      _expansionCache[cacheKey] = expanded;
      
      return expanded;
    } catch (e) {
      print('⚠️ Error expanding sentence: $e');
      // Return original sentence if expansion fails
      return sentence;
    }
  }

  /// Expand entire text while preserving meaning
  Future<String> expandText(String text, {int maxExpansionRatio = 2}) async {
    final sentences = _splitIntoSentences(text);
    final expandedSentences = <String>[];
    
    for (int i = 0; i < sentences.length; i++) {
      final sentence = sentences[i];
      final context = i > 0 ? sentences[i - 1] : null;
      
      try {
        final expanded = await expandSentence(sentence, context: context);
        expandedSentences.add(expanded);
      } catch (e) {
        expandedSentences.add(sentence); // Fallback to original
      }
    }
    
    return expandedSentences.join(' ');
  }

  /// Rule-based expansion (fallback/offline mode)
  String _ruleBasedExpansion(String sentence, {String? context}) {
    String expanded = sentence;
    
    // Add descriptive adjectives
    expanded = _addDescriptiveAdjectives(expanded);
    
    // Enhance action verbs
    expanded = _enhanceActionVerbs(expanded);
    
    // Add sensory details
    expanded = _addSensoryDetails(expanded);
    
    // Ensure we don't over-expand
    if (expanded.length > sentence.length * 2) {
      return sentence; // Too much expansion, return original
    }
    
    return expanded;
  }

  /// Add descriptive adjectives to nouns
  String _addDescriptiveAdjectives(String text) {
    final Map<String, String> enhancements = {
      'forest': 'dense, mystical forest',
      'river': 'flowing, crystal-clear river',
      'mountain': 'towering, majestic mountain',
      'palace': 'grand, ornate palace',
      'kingdom': 'prosperous, ancient kingdom',
      'warrior': 'brave, noble warrior',
      'prince': 'valiant, young prince',
      'princess': 'beautiful, graceful princess',
      'king': 'wise, mighty king',
      'queen': 'elegant, kind queen',
      'demon': 'fearsome, powerful demon',
      'sword': 'gleaming, mighty sword',
      'arrow': 'swift, magical arrow',
      'bow': 'golden, enchanted bow',
      'garden': 'lush, blooming garden',
      'temple': 'sacred, ancient temple',
      'sky': 'vast, blue sky',
      'moon': 'bright, silver moon',
      'sun': 'radiant, golden sun',
      'stars': 'twinkling, distant stars',
    };
    
    String enhanced = text;
    enhancements.forEach((word, replacement) {
      final pattern = RegExp(r'\b' + word + r'\b', caseSensitive: false);
      if (pattern.hasMatch(enhanced) && !enhanced.contains(replacement)) {
        enhanced = enhanced.replaceFirst(pattern, replacement);
      }
    });
    
    return enhanced;
  }

  /// Enhance action verbs with adverbs
  String _enhanceActionVerbs(String text) {
    final Map<String, String> enhancements = {
      'walked': 'walked gracefully',
      'ran': 'ran swiftly',
      'said': 'said softly',
      'shouted': 'shouted loudly',
      'looked': 'looked carefully',
      'fought': 'fought bravely',
      'jumped': 'jumped high',
      'flew': 'flew majestically',
      'sang': 'sang beautifully',
      'danced': 'danced joyfully',
      'spoke': 'spoke wisely',
      'listened': 'listened attentively',
      'thought': 'thought deeply',
      'smiled': 'smiled warmly',
      'cried': 'cried softly',
    };
    
    String enhanced = text;
    enhancements.forEach((word, replacement) {
      final pattern = RegExp(r'\b' + word + r'\b', caseSensitive: false);
      if (pattern.hasMatch(enhanced) && !enhanced.contains(replacement)) {
        enhanced = enhanced.replaceFirst(pattern, replacement);
      }
    });
    
    return enhanced;
  }

  /// Add sensory details to sentences
  String _addSensoryDetails(String text) {
    // Add visual details
    if (text.toLowerCase().contains('morning') && !text.contains('sun')) {
      text = text.replaceFirst('morning', 'morning as the sun rose');
    }
    
    // Add auditory details
    if (text.toLowerCase().contains('silent') && !text.contains('sound')) {
      text = text.replaceFirst('silent', 'silent, without a sound');
    }
    
    // Add emotional context
    if (text.toLowerCase().contains('happy') && !text.contains('joy')) {
      text = text.replaceFirst('happy', 'happy, filled with joy');
    }
    
    return text;
  }

  /// Split text into sentences
  List<String> _splitIntoSentences(String text) {
    final sentences = text.split(RegExp(r'[.!?]+'));
    return sentences
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Expand using GPT/LLM API (optional, for premium users)
  Future<String> expandWithAI(String text, {String? styleHint}) async {
    // This is a placeholder for GPT integration
    // You can integrate with OpenAI GPT-4 or similar LLM
    
    try {
      // Example structure for future GPT integration:
      // final response = await http.post(
      //   Uri.parse('https://api.openai.com/v1/chat/completions'),
      //   headers: {
      //     'Authorization': 'Bearer ${Environment.openAIApiKey}',
      //     'Content-Type': 'application/json',
      //   },
      //   body: jsonEncode({
      //     'model': 'gpt-4',
      //     'messages': [
      //       {
      //         'role': 'system',
      //         'content': 'You are a storytelling expert. Expand the following text to make it more vivid and engaging for children, while preserving its original meaning.',
      //       },
      //       {
      //         'role': 'user',
      //         'content': text,
      //       }
      //     ],
      //     'temperature': 0.7,
      //     'max_tokens': 500,
      //   }),
      // );
      
      // For now, fallback to rule-based
      return await expandText(text);
    } catch (e) {
      print('⚠️ AI expansion failed, using rule-based: $e');
      return await expandText(text);
    }
  }

  /// Clear expansion cache
  void clearCache() {
    _expansionCache.clear();
  }

  /// Get cache size
  int getCacheSize() {
    return _expansionCache.length;
  }
}

