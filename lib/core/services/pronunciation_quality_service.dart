/// Service to check pronunciation quality in generated audio
/// Uses heuristics and pattern matching (lightweight G2P alternative)
class PronunciationQualityService {
  static final PronunciationQualityService _instance = PronunciationQualityService._internal();
  factory PronunciationQualityService() => _instance;
  PronunciationQualityService._internal();

  // Common mispronunciation patterns
  static const Map<String, List<String>> commonMispronunciations = {
    'character names': [
      'Rama',
      'Krishna',
      'Hanuman',
      'Lakshman',
      'Sita',
    ],
    'difficult words': [
      'lieutenant',
      'colonel',
      'pronunciation',
      'mischievous',
    ],
  };

  // Phonetic rules for validation
  static const Map<String, String> phoneticRules = {
    'Rama': 'RAH-mah',
    'Krishna': 'KRISH-nah',
    'Hanuman': 'HA-noo-mahn',
    'Sita': 'SEE-tah',
  };

  /// Check text for potential mispronunciations
  Future<Map<String, dynamic>> checkPronunciation(String text) async {
    final issues = <Map<String, dynamic>>[];
    final suggestions = <Map<String, dynamic>>[];

    // Check for character names that might be mispronounced
    for (final category in commonMispronunciations.entries) {
      for (final word in category.value) {
        if (text.contains(word)) {
          final phonetic = phoneticRules[word];
          if (phonetic != null) {
            suggestions.add({
              'word': word,
              'category': category.key,
              'phonetic': phonetic,
              'importance': 'high',
            });
          }
        }
      }
    }

    // Check for unusual character combinations
    final unusualPatterns = [
      RegExp(r'\w{15,}'), // Very long words
      RegExp(r'[^aeiouAEIOU]{6,}'), // 6+ consecutive consonants
      RegExp(r'[aeiouAEIOU]{5,}'), // 5+ consecutive vowels
    ];

    for (final pattern in unusualPatterns) {
      final matches = pattern.allMatches(text);
      for (final match in matches) {
        issues.add({
          'text': match.group(0),
          'type': 'unusual_pattern',
          'position': match.start,
          'severity': 'medium',
        });
      }
    }

    // Check for numbers that should be spelled out
    final numberPattern = RegExp(r'\b\d+\b');
    final numberMatches = numberPattern.allMatches(text);
    
    for (final match in numberMatches) {
      suggestions.add({
        'text': match.group(0),
        'type': 'number',
        'suggestion': _numberToWords(int.tryParse(match.group(0)!) ?? 0),
        'severity': 'low',
      });
    }

    return {
      'has_issues': issues.isNotEmpty,
      'issues': issues,
      'suggestions': suggestions,
      'quality_score': _calculateQualityScore(issues, suggestions),
    };
  }

  /// Calculate pronunciation quality score (0-100)
  int _calculateQualityScore(
    List<Map<String, dynamic>> issues,
    List<Map<String, dynamic>> suggestions,
  ) {
    int score = 100;
    
    // Deduct points for issues
    for (final issue in issues) {
      if (issue['severity'] == 'high') {
        score -= 15;
      } else if (issue['severity'] == 'medium') {
        score -= 10;
      } else {
        score -= 5;
      }
    }

    // Minor deduction for suggestions
    score -= suggestions.length * 2;

    return score.clamp(0, 100);
  }

  /// Convert number to words (simple implementation)
  String _numberToWords(int number) {
    if (number == 0) return 'zero';
    
    const ones = [
      '', 'one', 'two', 'three', 'four', 'five',
      'six', 'seven', 'eight', 'nine',
    ];
    const teens = [
      'ten', 'eleven', 'twelve', 'thirteen', 'fourteen',
      'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen',
    ];
    const tens = [
      '', '', 'twenty', 'thirty', 'forty', 'fifty',
      'sixty', 'seventy', 'eighty', 'ninety',
    ];

    if (number < 10) return ones[number];
    if (number < 20) return teens[number - 10];
    if (number < 100) {
      final tenDigit = number ~/ 10;
      final oneDigit = number % 10;
      return '${tens[tenDigit]}${oneDigit > 0 ? '-${ones[oneDigit]}' : ''}';
    }
    if (number < 1000) {
      final hundred = number ~/ 100;
      final remainder = number % 100;
      return '${ones[hundred]} hundred${remainder > 0 ? ' and ${_numberToWords(remainder)}' : ''}';
    }
    
    return number.toString(); // Fallback for large numbers
  }

  /// Add SSML pronunciation hints
  String addPronunciationHints(String text) {
    String enhanced = text;

    // Add pronunciation hints for known words
    for (final entry in phoneticRules.entries) {
      final word = entry.key;
      final phonetic = entry.value;
      
      // Replace with SSML phoneme tag (if TTS supports it)
      enhanced = enhanced.replaceAllMapped(
        RegExp('\\b$word\\b'),
        (match) => '<phoneme alphabet="ipa" ph="$phonetic">$word</phoneme>',
      );
    }

    return enhanced;
  }

  /// Suggest text corrections for better pronunciation
  String suggestCorrections(String text) {
    String corrected = text;

    // Replace numbers with words
    corrected = corrected.replaceAllMapped(
      RegExp(r'\b(\d+)\b'),
      (match) {
        final number = int.tryParse(match.group(1)!);
        if (number != null && number < 1000) {
          return _numberToWords(number);
        }
        return match.group(0)!;
      },
    );

    // Add spaces to very long words to help pronunciation
    corrected = corrected.replaceAllMapped(
      RegExp(r'\w{20,}'),
      (match) {
        final word = match.group(0)!;
        // Insert spaces every 10 characters
        return word.replaceAllMapped(
          RegExp(r'.{10}'),
          (m) => '${m.group(0)} ',
        ).trim();
      },
    );

    return corrected;
  }

  /// Validate pronunciation before TTS generation
  Future<bool> validateBeforeTTS(String text) async {
    final result = await checkPronunciation(text);
    final score = result['quality_score'] as int;

    if (score < 70) {
      print('⚠️ Pronunciation quality score low: $score/100');
      print('Issues: ${result['issues']}');
      print('Suggestions: ${result['suggestions']}');
    }

    return score >= 50; // Allow if score is at least 50
  }

  /// Get pronunciation report
  Future<Map<String, dynamic>> getPronunciationReport(String text) async {
    final result = await checkPronunciation(text);
    
    return {
      'text_length': text.length,
      'word_count': text.split(' ').length,
      'quality_score': result['quality_score'],
      'has_issues': result['has_issues'],
      'issue_count': (result['issues'] as List).length,
      'suggestion_count': (result['suggestions'] as List).length,
      'issues': result['issues'],
      'suggestions': result['suggestions'],
      'corrected_text': suggestCorrections(text),
    };
  }
}

