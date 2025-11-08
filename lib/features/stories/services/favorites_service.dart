import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';

class FavoritesService {
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final SupabaseClient _supabase = SupabaseService.client;

  /// Get all favorite story IDs for current user
  Future<Set<String>> getFavoriteStoryIds() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return {};

      final response = await _supabase
          .from('favorite_stories')
          .select('story_id')
          .eq('user_id', userId);

      if (response is List) {
        return response.map((item) => item['story_id'] as String).toSet();
      }
      return {};
    } catch (e) {
      print('Error fetching favorites: $e');
      return {};
    }
  }

  /// Add story to favorites (simplified - only stores title)
  Future<bool> addFavorite(
    String storyId, {
    required String storyTitle,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('favorite_stories').insert({
        'user_id': userId,
        'story_id': storyId,
        'story_title': storyTitle,
        'added_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      print('Error adding favorite: $e');
      return false;
    }
  }

  /// Remove story from favorites
  Future<bool> removeFavorite(String storyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('favorite_stories')
          .delete()
          .eq('user_id', userId)
          .eq('story_id', storyId);

      return true;
    } catch (e) {
      print('Error removing favorite: $e');
      return false;
    }
  }

  /// Toggle favorite status (simplified)
  Future<bool> toggleFavorite(
    String storyId,
    bool isFavorite, {
    String? storyTitle,
  }) async {
    if (isFavorite) {
      return await removeFavorite(storyId);
    } else {
      return await addFavorite(
        storyId,
        storyTitle: storyTitle ?? 'Unknown Story',
      );
    }
  }

  /// Get count of favorites
  Future<int> getFavoritesCount() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await _supabase
          .from('favorite_stories')
          .select()
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  /// Stream favorites changes
  Stream<Set<String>> watchFavorites() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return Stream.value({});

    return _supabase
        .from('favorite_stories')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((data) {
          return data.map((item) => item['story_id'] as String).toSet();
        });
  }
}

