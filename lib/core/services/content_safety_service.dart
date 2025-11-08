/// Service to filter and validate content for child safety
class ContentSafetyService {
  static final ContentSafetyService _instance = ContentSafetyService._internal();
  factory ContentSafetyService() => _instance;
  ContentSafetyService._internal();

  // Inappropriate words/phrases that should be flagged
  static const List<String> _prohibitedWords = [
    'violence', 'weapon', 'blood', 'kill', 'death', 'die',
    'scary', 'horror', 'monster', 'nightmare',
    // Add more as needed
  ];

  // Age-appropriate themes
  static const Map<int, List<String>> _ageAppropriateThemes = {
    3: ['animals', 'family', 'friendship', 'colors', 'shapes'],
    5: ['adventure', 'magic', 'nature', 'learning', 'kindness'],
    7: ['courage', 'honesty', 'teamwork', 'problem-solving', 'history'],
    10: ['mythology', 'science', 'culture', 'responsibility', 'leadership'],
    12: ['moral dilemmas', 'complex emotions', 'social issues', 'critical thinking'],
  };

  /// Filter content for child safety
  Future<Map<String, dynamic>> filterContent({
    required String content,
    required int childAge,
    bool strictMode = true,
  }) async {
    final violations = <String>[];
    final warnings = <String>[];
    String filteredContent = content;

    // Check for prohibited words
    for (final word in _prohibitedWords) {
      if (content.toLowerCase().contains(word.toLowerCase())) {
        violations.add('Contains prohibited word: $word');
        
        // Replace with age-appropriate alternative
        if (!strictMode) {
          filteredContent = _replaceProhibitedWord(filteredContent, word);
          warnings.add('Replaced: $word');
        }
      }
    }

    // Check content length
    if (content.length > 10000) {
      warnings.add('Content is very long - may be too complex for age $childAge');
    }

    // Check sentence complexity
    final sentences = content.split(RegExp(r'[.!?]'));
    final avgWordsPerSentence = _calculateAverageWordsPerSentence(sentences);
    
    if (avgWordsPerSentence > _getMaxWordsPerSentence(childAge)) {
      warnings.add('Sentences may be too complex for age $childAge');
    }

    // Check for age-appropriate themes
    final themes = _extractThemes(content);
    final appropriateThemes = _getAppropriateThemesForAge(childAge);
    
    for (final theme in themes) {
      if (!appropriateThemes.contains(theme.toLowerCase())) {
        warnings.add('Theme "$theme" may not be suitable for age $childAge');
      }
    }

    return {
      'is_safe': violations.isEmpty,
      'is_age_appropriate': violations.isEmpty && warnings.length <= 2,
      'violations': violations,
      'warnings': warnings,
      'filtered_content': filteredContent,
      'safety_score': _calculateSafetyScore(violations, warnings),
      'age_appropriateness_score': _calculateAgeAppropriatenessScore(childAge, content),
    };
  }

  /// Replace prohibited words with safer alternatives
  String _replaceProhibitedWord(String content, String word) {
    final replacements = {
      'violence': 'conflict',
      'weapon': 'tool',
      'blood': 'juice',
      'kill': 'defeat',
      'death': 'sleep',
      'die': 'rest',
      'scary': 'surprising',
      'horror': 'mystery',
      'monster': 'creature',
      'nightmare': 'dream',
    };

    return content.replaceAll(
      RegExp(word, caseSensitive: false),
      replacements[word.toLowerCase()] ?? 'thing',
    );
  }

  /// Calculate average words per sentence
  double _calculateAverageWordsPerSentence(List<String> sentences) {
    if (sentences.isEmpty) return 0;
    
    final totalWords = sentences
        .map((s) => s.trim().split(' ').length)
        .reduce((a, b) => a + b);
    
    return totalWords / sentences.length;
  }

  /// Get maximum recommended words per sentence for age
  int _getMaxWordsPerSentence(int age) {
    if (age <= 4) return 8;
    if (age <= 6) return 12;
    if (age <= 8) return 15;
    if (age <= 10) return 20;
    return 25;
  }

  /// Extract themes from content
  List<String> _extractThemes(String content) {
    final themes = <String>[];
    final lowerContent = content.toLowerCase();

    for (final ageThemes in _ageAppropriateThemes.values) {
      for (final theme in ageThemes) {
        if (lowerContent.contains(theme)) {
          themes.add(theme);
        }
      }
    }

    return themes;
  }

  /// Get appropriate themes for age
  List<String> _getAppropriateThemesForAge(int age) {
    final themes = <String>[];
    
    for (final entry in _ageAppropriateThemes.entries) {
      if (age >= entry.key) {
        themes.addAll(entry.value);
      }
    }
    
    return themes;
  }

  /// Calculate safety score (0-100)
  int _calculateSafetyScore(List<String> violations, List<String> warnings) {
    int score = 100;
    score -= violations.length * 30; // Major penalty for violations
    score -= warnings.length * 10;   // Minor penalty for warnings
    return score.clamp(0, 100);
  }

  /// Calculate age appropriateness score (0-100)
  int _calculateAgeAppropriatenessScore(int age, String content) {
    int score = 100;
    
    // Check word count
    final wordCount = content.split(' ').length;
    final idealWordCount = _getIdealWordCount(age);
    
    if (wordCount > idealWordCount * 1.5) {
      score -= 20; // Too long
    } else if (wordCount < idealWordCount * 0.5) {
      score -= 10; // Too short
    }
    
    return score.clamp(0, 100);
  }

  /// Get ideal word count for age
  int _getIdealWordCount(int age) {
    if (age <= 4) return 200;
    if (age <= 6) return 400;
    if (age <= 8) return 600;
    if (age <= 10) return 800;
    return 1000;
  }

  /// Validate content before TTS generation
  Future<bool> validateBeforeTTS({
    required String content,
    required int childAge,
  }) async {
    final result = await filterContent(
      content: content,
      childAge: childAge,
      strictMode: true,
    );

    if (!result['is_safe']) {
      throw Exception(
        'Content contains inappropriate material:\n${(result['violations'] as List).join('\n')}',
      );
    }

    return true;
  }

  /// Get safety report
  Future<Map<String, dynamic>> getSafetyReport({
    required String content,
    required int childAge,
  }) async {
    return await filterContent(
      content: content,
      childAge: childAge,
      strictMode: false,
    );
  }
}

