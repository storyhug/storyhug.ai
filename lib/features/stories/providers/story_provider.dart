import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/story.dart';
import '../services/story_service.dart';

/// Story state model
class StoryState {
  final List<Story> allStories;
  final List<Story> featuredStories;
  final Map<String, List<Story>> categorizedStories;
  final List<String> categories;
  final bool isLoading;
  final String? error;

  StoryState({
    this.allStories = const [],
    this.featuredStories = const [],
    this.categorizedStories = const {},
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  StoryState copyWith({
    List<Story>? allStories,
    List<Story>? featuredStories,
    Map<String, List<Story>>? categorizedStories,
    List<String>? categories,
    bool? isLoading,
    String? error,
  }) {
    return StoryState(
      allStories: allStories ?? this.allStories,
      featuredStories: featuredStories ?? this.featuredStories,
      categorizedStories: categorizedStories ?? this.categorizedStories,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Story provider using Riverpod
class StoryNotifier extends StateNotifier<StoryState> {
  final StoryService _storyService;

  StoryNotifier(this._storyService) : super(StoryState()) {
    loadStories();
  }

  /// Load all stories from database
  Future<void> loadStories() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch all stories from database
      final stories = await _storyService.getAllStories();
      
      // Sort by most recent
      stories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // Featured stories (latest 10)
      final featured = stories.take(10).toList();
      
      // Categorize stories
      final Map<String, List<Story>> categorized = {};
      final Set<String> categorySet = {};
      
      for (final story in stories) {
        final category = story.category.trim();
        categorySet.add(category);
        
        if (!categorized.containsKey(category)) {
          categorized[category] = [];
        }
        categorized[category]!.add(story);
      }
      
      // Sort categories alphabetically
      final sortedCategories = categorySet.toList()..sort();
      
      // Sort stories within each category by most recent
      categorized.forEach((key, value) {
        value.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });
      
      state = state.copyWith(
        allStories: stories,
        featuredStories: featured,
        categorizedStories: categorized,
        categories: sortedCategories,
        isLoading: false,
      );
      
      print('📚 Loaded ${stories.length} stories across ${sortedCategories.length} categories');
      print('📚 Categories: $sortedCategories');
    } catch (e) {
      print('❌ Error loading stories: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load stories: $e',
      );
    }
  }

  /// Import a new story
  Future<bool> importStory(Story story) async {
    try {
      // Add to all stories
      final updatedAllStories = [story, ...state.allStories];
      
      // Add to featured (at the top)
      final updatedFeatured = [story, ...state.featuredStories];
      if (updatedFeatured.length > 10) {
        updatedFeatured.removeLast();
      }
      
      // Add to category
      final category = story.category.trim();
      final updatedCategorized = Map<String, List<Story>>.from(state.categorizedStories);
      
      if (!updatedCategorized.containsKey(category)) {
        updatedCategorized[category] = [];
      }
      updatedCategorized[category] = [story, ...updatedCategorized[category]!];
      
      // Update categories list
      final updatedCategories = Set<String>.from(state.categories);
      updatedCategories.add(category);
      final sortedCategories = updatedCategories.toList()..sort();
      
      // Update state immediately for instant UI refresh
      state = state.copyWith(
        allStories: updatedAllStories,
        featuredStories: updatedFeatured,
        categorizedStories: updatedCategorized,
        categories: sortedCategories,
      );
      
      print('✅ Story imported: ${story.title} to category: $category');
      return true;
    } catch (e) {
      print('❌ Error importing story: $e');
      return false;
    }
  }

  /// Import multiple stories (bulk import)
  Future<int> importStories(List<Story> stories) async {
    int successCount = 0;
    
    for (final story in stories) {
      final success = await importStory(story);
      if (success) successCount++;
    }
    
    return successCount;
  }

  /// Get stories by category
  List<Story> getStoriesByCategory(String category) {
    return state.categorizedStories[category] ?? [];
  }

  /// Search stories
  List<Story> searchStories(String query) {
    if (query.trim().isEmpty) return [];
    
    final lowerQuery = query.toLowerCase();
    return state.allStories.where((story) {
      return story.title.toLowerCase().contains(lowerQuery) ||
             story.category.toLowerCase().contains(lowerQuery) ||
             story.body.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Refresh stories (pull from database)
  Future<void> refresh() async {
    await loadStories();
  }
}

/// Provider instance
final storyServiceProvider = Provider<StoryService>((ref) => StoryService());

final storyProvider = StateNotifierProvider<StoryNotifier, StoryState>((ref) {
  final storyService = ref.watch(storyServiceProvider);
  return StoryNotifier(storyService);
});

