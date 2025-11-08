import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/story.dart';
import '../../../core/services/supabase_service.dart';

class StoryService {
  final SupabaseClient _supabase = SupabaseService.client;

  Future<List<Story>> getStories({
    int? age,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      var query = _supabase.from('stories').select();
      
      if (age != null) {
        query = query.gte('min_age', age).lte('max_age', age);
      }
      
      if (category != null) {
        query = query.eq('category', category);
      }
      
      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      return (response as List)
          .map((json) => Story.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stories: $e');
    }
  }

  Future<List<Story>> searchStories(String query) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .or('title.ilike.%$query%,body.ilike.%$query%')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Story.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search stories: $e');
    }
  }

  Future<List<String>> getCategories() async {
    try {
      final response = await _supabase
          .from('stories')
          .select('category')
          .order('category');

      return (response as List)
          .map((json) => json['category'] as String)
          .toSet()
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  Future<Story?> getStoryById(String storyId) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .eq('id', storyId)
          .single();

      return Story.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch story: $e');
    }
  }

  Future<List<Story>> getFeaturedStories({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => Story.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch featured stories: $e');
    }
  }

  Future<List<Story>> getStoriesByAge(int age) async {
    try {
      final response = await _supabase
          .from('stories')
          .select()
          .gte('min_age', age)
          .lte('max_age', age)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Story.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch stories by age: $e');
    }
  }

  Future<void> recordListen(String storyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('listens').insert({
        'user_id': userId,
        'story_id': storyId,
        'listened_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record listen: $e');
    }
  }

  Future<void> recordListenWithDuration(String storyId, int durationSeconds, bool completed) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('listens').insert({
        'user_id': userId,
        'story_id': storyId,
        'listened_at': DateTime.now().toIso8601String(),
        'duration_seconds': durationSeconds,
        'completed': completed,
      });
    } catch (e) {
      throw Exception('Failed to record listen with duration: $e');
    }
  }

  // Ramayana Stories Methods
  Future<List<Story>> getRamayanaStories({
    int? startStory,
    int? endStory,
    String? searchTerm,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('🔍 getRamayanaStories called with category: $category');
      
      var query = _supabase
          .from('ramayana_stories')
          .select('*')
          .eq('is_active', true);
      
      // Filter by category if specified
      if (category != null) {
        print('🔍 Filtering by category: $category');
        query = query.eq('category', category);
      }
      
      // Filter by story range if specified
      if (startStory != null) {
        query = query.gte('story_number', startStory);
      }
      if (endStory != null) {
        query = query.lte('story_number', endStory);
      }
      
      final response = await query
          .order('story_number')
          .range((page - 1) * limit, page * limit - 1);

      final stories = (response as List).map((json) => _convertRamayanaToStory(json)).toList();
      print('🔍 Found ${stories.length} Ramayana stories');
      if (stories.isNotEmpty) {
        print('🔍 First story category: ${stories.first.category}');
      }
      return stories;
    } catch (e) {
      print('❌ Error in getRamayanaStories: $e');
      throw Exception('Failed to fetch Ramayana stories: $e');
    }
  }

  Future<Story?> getRamayanaStoryByNumber(int storyNumber) async {
    try {
      final response = await _supabase
          .from('ramayana_stories')
          .select('*')
          .eq('story_number', storyNumber)
          .eq('is_active', true)
          .single();

      return _convertRamayanaToStory(response);
    } catch (e) {
      throw Exception('Failed to fetch Ramayana story $storyNumber: $e');
    }
  }

  Future<List<Story>> getAllStories({
    int? age,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final List<Story> allStories = [];
      
      // Get regular stories
      final regularStories = await getStories(
        age: age,
        category: category,
        page: page,
        limit: limit,
      );
      allStories.addAll(regularStories);
      
      // Get Ramayana stories if category is 'Ramayana', 'Bala Kanda', or no category specified
      if (category == null || category == 'Ramayana' || category == 'Bala Kanda') {
        final ramayanaStories = await getRamayanaStories(
          category: category == 'Ramayana' ? null : category, // Only filter if specific category requested
          page: page,
          limit: limit,
        );
        allStories.addAll(ramayanaStories);
      }
      
      // Sort by creation date
      allStories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return allStories;
    } catch (e) {
      throw Exception('Failed to fetch all stories: $e');
    }
  }

  Future<List<String>> getAllCategories() async {
    try {
      final categories = <String>{};
      
      // Get regular story categories
      final regularCategories = await getCategories();
      categories.addAll(regularCategories);
      
      // Add Ramayana categories
      categories.add('Bala Kanda');
      categories.add('Ramayana');
      
      return categories.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch all categories: $e');
    }
  }

  Future<Story?> getStoryByIdOrNumber(String identifier) async {
    try {
      // Try to parse as number (for Ramayana stories)
      final number = int.tryParse(identifier);
      if (number != null) {
        return await getRamayanaStoryByNumber(number);
      }
      
      // Try as regular story ID
      return await getStoryById(identifier);
    } catch (e) {
      throw Exception('Failed to fetch story: $e');
    }
  }

  // Convert Ramayana story to Story model
  Story _convertRamayanaToStory(Map<String, dynamic> ramayanaStory) {
    return Story(
      id: ramayanaStory['id'],
      title: ramayanaStory['title'],
      body: ramayanaStory['content'],
      category: ramayanaStory['category'] ?? 'Ramayana',
      minAge: _parseAgeRange(ramayanaStory['age_range'] ?? '6-12')[0],
      maxAge: _parseAgeRange(ramayanaStory['age_range'] ?? '6-12')[1],
      audioDefaultUrl: '', // Ramayana stories are text-only
      durationMinutes: ramayanaStory['estimated_duration_minutes'] ?? 5,
      thumbnailUrl: _getRamayanaThumbnail(ramayanaStory['story_number']),
      createdAt: DateTime.parse(ramayanaStory['created_at']),
      updatedAt: DateTime.parse(ramayanaStory['updated_at']),
    );
  }

  List<int> _parseAgeRange(String ageRange) {
    final parts = ageRange.split('-');
    if (parts.length == 2) {
      return [int.parse(parts[0]), int.parse(parts[1])];
    }
    return [6, 12]; // Default
  }

  String _getRamayanaThumbnail(int storyNumber) {
    // Generate appropriate thumbnail based on story number
    final colors = ['FFD700', 'FF6B6B', '4ECDC4', '45B7D1', '96CEB4', 'FFEAA7'];
    final color = colors[storyNumber % colors.length];
    return 'https://via.placeholder.com/200x200/$color/FFFFFF?text=R${storyNumber.toString().padLeft(2, '0')}';
  }

  // Sample data for development/testing
  static List<Story> getSampleStories() {
    return [
      Story(
        id: '1',
        title: 'The Brave Little Rabbit',
        body: 'Once upon a time, there was a brave little rabbit who lived in a magical forest. Every day, he would hop through the tall grass and explore new places...',
        category: 'Moral Stories',
        minAge: 3,
        maxAge: 8,
        audioDefaultUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        durationMinutes: 5,
        thumbnailUrl: 'https://via.placeholder.com/200x200/7B3FE4/FFFFFF?text=Rabbit',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Story(
        id: '2',
        title: 'Rama\'s Courage',
        body: 'In the ancient kingdom of Ayodhya, there lived a brave prince named Rama. He was known for his courage and wisdom...',
        category: 'Indian Mythology',
        minAge: 5,
        maxAge: 10,
        audioDefaultUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        durationMinutes: 7,
        thumbnailUrl: 'https://via.placeholder.com/200x200/FFD700/000000?text=Rama',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Story(
        id: '3',
        title: 'The Magic Forest Adventure',
        body: 'Deep in the enchanted forest, where the trees whispered secrets and the flowers sang melodies, lived a curious little girl named Luna...',
        category: 'Adventure',
        minAge: 4,
        maxAge: 9,
        audioDefaultUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        durationMinutes: 6,
        thumbnailUrl: 'https://via.placeholder.com/200x200/87CEEB/000000?text=Forest',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      Story(
        id: '4',
        title: 'The Kind Princess',
        body: 'In a beautiful castle surrounded by roses, lived a kind princess who always helped others...',
        category: 'Fairy Tales',
        minAge: 3,
        maxAge: 7,
        audioDefaultUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        durationMinutes: 4,
        thumbnailUrl: 'https://via.placeholder.com/200x200/FF69B4/FFFFFF?text=Princess',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      Story(
        id: '5',
        title: 'The Wise Old Owl',
        body: 'High up in the tallest tree of the forest, lived a wise old owl who knew all the secrets of the night...',
        category: 'Moral Stories',
        minAge: 4,
        maxAge: 8,
        audioDefaultUrl: 'https://www.soundjay.com/misc/sounds/bell-ringing-05.wav',
        durationMinutes: 5,
        thumbnailUrl: 'https://via.placeholder.com/200x200/8B4513/FFFFFF?text=Owl',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }
}
