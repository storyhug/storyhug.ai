import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

/// Service to personalize stories by injecting child and parent names
class PersonalizerService {
  static final PersonalizerService _instance = PersonalizerService._internal();
  factory PersonalizerService() => _instance;
  PersonalizerService._internal();

  // Lazy-load Supabase client to avoid initialization issues in tests
  SupabaseClient get _supabase => SupabaseService.client;

  /// Personalize story text with user names
  Future<String> personalizeText(
    String text, {
    String? userId,
    String? childName,
    String? parentName,
  }) async {
    String personalized = text;
    
    // Get user data if not provided
    if (userId != null && (childName == null || parentName == null)) {
      try {
        final userData = await _getUserData(userId);
        childName ??= userData['childName'];
        parentName ??= userData['parentName'];
      } catch (e) {
        print('⚠️ Could not fetch user data for personalization: $e');
      }
    }
    
    // Apply name substitutions
    if (childName != null && childName.isNotEmpty) {
      personalized = _injectChildName(personalized, childName);
    }
    
    if (parentName != null && parentName.isNotEmpty) {
      personalized = _injectParentName(personalized, parentName);
    }
    
    // Add custom voice hints if available
    personalized = await _addCustomVoiceHints(personalized, userId: userId);
    
    return personalized;
  }

  /// Inject child's name into story
  String _injectChildName(String text, String childName) {
    // Replace generic child placeholders with actual name
    final placeholders = [
      'the child',
      'the little one',
      'dear child',
      'young one',
      'little friend',
    ];
    
    String personalized = text;
    for (final placeholder in placeholders) {
      final pattern = RegExp(placeholder, caseSensitive: false);
      personalized = personalized.replaceAll(pattern, childName);
    }
    
    // Add personalized opening if story starts generically
    if (!personalized.toLowerCase().contains(childName.toLowerCase())) {
      personalized = 'Once upon a time, there was a wonderful child named $childName. $personalized';
    }
    
    return personalized;
  }

  /// Inject parent's name into story
  String _injectParentName(String text, String parentName) {
    // Replace generic parent placeholders
    final placeholders = [
      'the parent',
      'mother',
      'father',
      'mom',
      'dad',
    ];
    
    String personalized = text;
    for (final placeholder in placeholders) {
      final pattern = RegExp(r'\b' + placeholder + r'\b', caseSensitive: false);
      // Only replace if it appears to be a narrator reference, not character dialogue
      if (pattern.hasMatch(personalized) && !personalized.contains('"$placeholder"')) {
        personalized = personalized.replaceFirst(pattern, parentName);
      }
    }
    
    return personalized;
  }

  /// Add custom voice hints for personalized narration
  Future<String> _addCustomVoiceHints(String text, {String? userId}) async {
    if (userId == null) return text;
    
    try {
      // Check if user has recorded custom phrases
      final customPhrases = await _getCustomPhrases(userId);
      
      if (customPhrases.isEmpty) return text;
      
      // Add markers for custom voice segments
      String enhanced = text;
      for (final phrase in customPhrases) {
        final phraseText = phrase['phrase_text'] as String;
        if (text.contains(phraseText)) {
          enhanced = enhanced.replaceFirst(
            phraseText,
            '<custom_voice user_id="$userId">$phraseText</custom_voice>',
          );
        }
      }
      
      return enhanced;
    } catch (e) {
      print('⚠️ Could not add custom voice hints: $e');
      return text;
    }
  }

  /// Get user data from database
  Future<Map<String, dynamic>> _getUserData(String userId) async {
    try {
      // Get child profile
      final childProfiles = await _supabase
          .from('child_profiles')
          .select('name')
          .eq('user_id', userId)
          .limit(1);
      
      // Get user metadata
      final user = _supabase.auth.currentUser;
      final parentName = user?.userMetadata?['full_name'] as String?;
      
      return {
        'childName': childProfiles.isNotEmpty 
            ? childProfiles.first['name'] 
            : null,
        'parentName': parentName,
      };
    } catch (e) {
      print('⚠️ Error fetching user data: $e');
      return {};
    }
  }

  /// Get custom recorded phrases for user
  Future<List<Map<String, dynamic>>> _getCustomPhrases(String userId) async {
    try {
      final phrases = await _supabase
          .from('custom_phrases')
          .select('phrase_text, audio_url')
          .eq('user_id', userId);
      
      return List<Map<String, dynamic>>.from(phrases);
    } catch (e) {
      print('⚠️ Error fetching custom phrases: $e');
      return [];
    }
  }

  /// Generate personalized greeting for story
  String generatePersonalizedGreeting({
    required String childName,
    String? parentName,
    String? timeOfDay,
  }) {
    final greeting = timeOfDay ?? _getTimeOfDay();
    
    if (parentName != null) {
      return '$greeting, $childName! $parentName has a special story just for you.';
    } else {
      return '$greeting, $childName! Here\'s a wonderful story just for you.';
    }
  }

  /// Get appropriate greeting based on time of day
  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Replace character names with personalized versions
  String personalizeCharacterNames(
    String text, {
    Map<String, String>? characterMapping,
  }) {
    if (characterMapping == null || characterMapping.isEmpty) {
      return text;
    }
    
    String personalized = text;
    
    characterMapping.forEach((originalName, personalizedName) {
      final pattern = RegExp(r'\b' + originalName + r'\b', caseSensitive: false);
      personalized = personalized.replaceAll(pattern, personalizedName);
    });
    
    return personalized;
  }

  /// Add personalized ending to story
  String addPersonalizedEnding(String text, {required String childName}) {
    final endings = [
      'And that\'s the end of the story, $childName. Sleep tight!',
      'The end, $childName. Sweet dreams!',
      'And they all lived happily ever after. Goodnight, $childName!',
      'That\'s all for tonight, $childName. Dream wonderful dreams!',
    ];
    
    final randomEnding = endings[DateTime.now().millisecond % endings.length];
    
    return '$text\n\n$randomEnding';
  }

  /// Check if text contains personalization placeholders
  bool hasPersonalizationPlaceholders(String text) {
    final placeholders = [
      '{child_name}',
      '{parent_name}',
      '{time_of_day}',
      '[CHILD_NAME]',
      '[PARENT_NAME]',
    ];
    
    return placeholders.any((placeholder) => text.contains(placeholder));
  }

  /// Replace explicit placeholders with actual values
  String replacePlaceholders(
    String text, {
    String? childName,
    String? parentName,
    String? timeOfDay,
  }) {
    String processed = text;
    
    if (childName != null) {
      processed = processed
          .replaceAll('{child_name}', childName)
          .replaceAll('[CHILD_NAME]', childName);
    }
    
    if (parentName != null) {
      processed = processed
          .replaceAll('{parent_name}', parentName)
          .replaceAll('[PARENT_NAME]', parentName);
    }
    
    if (timeOfDay != null) {
      processed = processed.replaceAll('{time_of_day}', timeOfDay);
    }
    
    return processed;
  }
}

