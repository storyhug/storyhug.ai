import 'dart:io';
import 'dart:convert';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../config/environment.dart';
import '../../../core/services/supabase_service.dart';

class StoryImportService {
  static final StoryImportService _instance = StoryImportService._internal();
  factory StoryImportService() => _instance;
  StoryImportService._internal();

  /// Parse Word document and extract stories with automatic category creation
  Future<List<Map<String, dynamic>>> parseWordDocument(String filePath, {String? customCategory}) async {
    try {
      print('📄 Parsing Word document: $filePath');
      
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      // Extract document name for category
      final fileName = file.path.split('/').last.split('\\').last;
      final documentName = fileName.replaceAll('.docx', '').replaceAll('.doc', '');
      final category = customCategory ?? documentName;
      
      print('📁 Document category: $category');

      // Read the Word document
      final bytes = await file.readAsBytes();
      final text = docxToText(bytes);
      
      print('📖 Extracted text length: ${text.length} characters');
      
      // Parse stories from the text with enhanced logic
      final stories = _parseStoriesFromText(text, category);
      
      print('📚 Parsed ${stories.length} stories for category: $category');
      return stories;
    } catch (e) {
      print('❌ Error parsing Word document: $e');
      throw Exception('Failed to parse Word document: $e');
    }
  }

  /// Parse stories from extracted text with enhanced logic
  List<Map<String, dynamic>> _parseStoriesFromText(String text, String category) {
    final stories = <Map<String, dynamic>>[];
    
    // Enhanced parsing patterns for different document formats
    final lines = text.split('\n');
    String currentStory = '';
    String currentTitle = '';
    int storyNumber = 1;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Skip empty lines
      if (line.isEmpty) continue;
      
      // Enhanced story title detection patterns
      if (_isStoryTitle(line)) {
        // Save previous story if exists
        if (currentStory.isNotEmpty && currentTitle.isNotEmpty) {
          stories.add(_createStoryMap(storyNumber, currentTitle, currentStory, category));
          storyNumber++;
        }
        
        // Start new story
        currentTitle = line;
        currentStory = '';
      } else {
        // Add line to current story
        currentStory += line + '\n';
      }
    }
    
    // Add the last story
    if (currentStory.isNotEmpty && currentTitle.isNotEmpty) {
      stories.add(_createStoryMap(storyNumber, currentTitle, currentStory, category));
    }
    
    // If no stories were found with title detection, try alternative parsing
    if (stories.isEmpty) {
      stories.addAll(_parseStoriesAlternative(text, category));
    }
    
    return stories;
  }

  /// Check if a line is a story title with enhanced patterns
  bool _isStoryTitle(String line) {
    // Enhanced patterns for different document formats
    final titlePatterns = [
      RegExp(r'^Story \d+:', caseSensitive: false),
      RegExp(r'^Chapter \d+:', caseSensitive: false),
      RegExp(r'^Episode \d+:', caseSensitive: false),
      RegExp(r'^\d+\.', caseSensitive: false), // Number followed by period
      RegExp(r'^[A-Z][A-Z\s]+$'), // All caps words
      RegExp(r'^[A-Z][a-z]+ [A-Z][a-z]+'), // Title case with spaces
      RegExp(r'^[IVX]+\.', caseSensitive: false), // Roman numerals
    ];
    
    // Additional checks for title characteristics
    final isShortLine = line.length < 100;
    final hasTitleWords = RegExp(r'\b(story|tale|adventure|journey|legend|myth)\b', caseSensitive: false).hasMatch(line);
    
    return titlePatterns.any((pattern) => pattern.hasMatch(line)) && 
           (isShortLine || hasTitleWords);
  }

  /// Alternative parsing method for documents without clear titles
  List<Map<String, dynamic>> _parseStoriesAlternative(String text, String category) {
    final stories = <Map<String, dynamic>>[];
    
    // Split by double line breaks or page breaks
    final sections = text.split(RegExp(r'\n\s*\n'));
    
    int storyNumber = 1;
    for (final section in sections) {
      final trimmedSection = section.trim();
      if (trimmedSection.length > 100) { // Only consider substantial sections
        final title = _generateTitleFromContent(trimmedSection, storyNumber, category);
        stories.add(_createStoryMap(storyNumber, title, trimmedSection, category));
        storyNumber++;
      }
    }
    
    return stories;
  }

  /// Generate a title from story content
  String _generateTitleFromContent(String content, int storyNumber, String category) {
    // Extract first meaningful sentence or phrase
    final sentences = content.split('.').where((s) => s.trim().isNotEmpty).toList();
    if (sentences.isNotEmpty) {
      final firstSentence = sentences.first.trim();
      if (firstSentence.length > 10 && firstSentence.length < 80) {
        return firstSentence;
      }
    }
    
    // Fallback to generic title
    return 'Story $storyNumber from $category';
  }

  /// Create story map for database insertion
  Map<String, dynamic> _createStoryMap(int storyNumber, String title, String content, String category) {
    return {
      'story_number': storyNumber,
      'title': title,
      'content': content.trim(),
      'summary': _generateSummary(content),
      'keywords': _extractKeywords(title, content),
      'estimated_duration_minutes': _estimateDuration(content),
      'difficulty_level': _determineDifficulty(content),
      'age_range': '6-12',
      'category': category, // Use the provided category
    };
  }

  /// Generate a summary from story content
  String _generateSummary(String content) {
    final sentences = content.split('.').where((s) => s.trim().isNotEmpty).toList();
    if (sentences.length <= 2) return content;
    
    // Take first 2 sentences as summary
    return sentences.take(2).join('.') + '.';
  }

  /// Extract keywords from title and content
  List<String> _extractKeywords(String title, String content) {
    final keywords = <String>{};
    
    // Add words from title
    final titleWords = title.toLowerCase().split(' ').where((w) => w.length > 3).toList();
    keywords.addAll(titleWords);
    
    // Add common Ramayana keywords
    final ramayanaKeywords = [
      'Rama', 'Sita', 'Lakshmana', 'Hanuman', 'Ravana', 'Ayodhya', 'Lanka',
      'Dasharatha', 'Kausalya', 'Sumitra', 'Kaikeyi', 'Bharata', 'Shatrughna',
      'Valmiki', 'Vishnu', 'Shiva', 'Brahma', 'Indra', 'Agni', 'Vayu'
    ];
    
    for (final keyword in ramayanaKeywords) {
      if (content.toLowerCase().contains(keyword.toLowerCase())) {
        keywords.add(keyword);
      }
    }
    
    return keywords.take(10).toList(); // Limit to 10 keywords
  }

  /// Estimate reading duration in minutes
  int _estimateDuration(String content) {
    final wordCount = content.split(' ').length;
    final wordsPerMinute = 200; // Average reading speed
    final minutes = (wordCount / wordsPerMinute).ceil();
    return minutes.clamp(3, 15); // Between 3-15 minutes
  }

  /// Determine difficulty level based on content
  String _determineDifficulty(String content) {
    final wordCount = content.split(' ').length;
    final sentenceCount = content.split('.').length;
    final avgWordsPerSentence = wordCount / sentenceCount;
    
    if (avgWordsPerSentence < 8) return 'Easy';
    if (avgWordsPerSentence < 12) return 'Medium';
    return 'Hard';
  }

  /// Upload stories to Supabase database
  Future<void> uploadStoriesToDatabase(List<Map<String, dynamic>> stories) async {
    try {
      print('📤 Uploading ${stories.length} stories to database...');
      
      for (int i = 0; i < stories.length; i++) {
        final story = stories[i];
        print('📝 Uploading story ${i + 1}/${stories.length}: ${story['title']}');
        
        await SupabaseService.client
            .from('ramayana_stories')
            .insert(story);
      }
      
      print('✅ Successfully uploaded all stories to database');
    } catch (e) {
      print('❌ Error uploading stories: $e');
      throw Exception('Failed to upload stories to database: $e');
    }
  }

  /// Get stories from database
  Future<List<Map<String, dynamic>>> getStoriesFromDatabase({
    int? startStory,
    int? endStory,
    String? searchTerm,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('ramayana_stories')
          .select('*')
          .eq('is_active', true)
          .order('story_number');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching stories: $e');
      throw Exception('Failed to fetch stories: $e');
    }
  }

  /// Get a single story by number
  Future<Map<String, dynamic>?> getStoryByNumber(int storyNumber) async {
    try {
      final response = await SupabaseService.client
          .from('ramayana_stories')
          .select('*')
          .eq('story_number', storyNumber)
          .eq('is_active', true)
          .single();

      return response;
    } catch (e) {
      print('❌ Error fetching story $storyNumber: $e');
      return null;
    }
  }

  /// Pick and process Word document
  Future<List<Map<String, dynamic>>> pickAndProcessDocument() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['docx'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final file = result.files.first;
      if (file.path == null) {
        throw Exception('File path is null');
      }

      // Parse document
      final stories = await parseWordDocument(file.path!);
      
      return stories;
    } catch (e) {
      print('❌ Error picking and processing document: $e');
      throw Exception('Failed to pick and process document: $e');
    }
  }

  /// Complete import process: pick, parse, and upload
  Future<void> completeImportProcess() async {
    try {
      print('🚀 Starting complete import process...');
      
      // Step 1: Pick and parse document
      final stories = await pickAndProcessDocument();
      
      // Step 2: Upload to database
      await uploadStoriesToDatabase(stories);
      
      print('🎉 Import process completed successfully!');
    } catch (e) {
      print('❌ Import process failed: $e');
      throw Exception('Import process failed: $e');
    }
  }

  /// Get story statistics
  Future<Map<String, dynamic>> getStoryStatistics() async {
    try {
      final response = await SupabaseService.client
          .from('ramayana_stories')
          .select('story_number, difficulty_level, age_range, estimated_duration_minutes')
          .eq('is_active', true);

      final stories = List<Map<String, dynamic>>.from(response);
      
      return {
        'total_stories': stories.length,
        'total_duration_minutes': stories.fold<int>(0, (sum, story) => sum + (story['estimated_duration_minutes'] as int)),
        'difficulty_distribution': _getDifficultyDistribution(stories),
        'age_range_distribution': _getAgeRangeDistribution(stories),
      };
    } catch (e) {
      print('❌ Error getting story statistics: $e');
      return {};
    }
  }

  Map<String, int> _getDifficultyDistribution(List<Map<String, dynamic>> stories) {
    final distribution = <String, int>{};
    for (final story in stories) {
      final difficulty = story['difficulty_level'] as String;
      distribution[difficulty] = (distribution[difficulty] ?? 0) + 1;
    }
    return distribution;
  }

  Map<String, int> _getAgeRangeDistribution(List<Map<String, dynamic>> stories) {
    final distribution = <String, int>{};
    for (final story in stories) {
      final ageRange = story['age_range'] as String;
      distribution[ageRange] = (distribution[ageRange] ?? 0) + 1;
    }
    return distribution;
  }
}
