import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/dashboard_stats.dart';

/// Service to fetch real-time dashboard analytics
class DashboardAnalyticsService {
  static final DashboardAnalyticsService _instance =
      DashboardAnalyticsService._internal();
  factory DashboardAnalyticsService() => _instance;
  DashboardAnalyticsService._internal();

  SupabaseClient get _supabase => SupabaseService.client;

  /// Fetch comprehensive dashboard statistics
  Future<DashboardStats> getDashboardStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _getTotalStoriesListened(userId),
        _getTotalListeningTime(userId),
        _getFavoriteCategory(userId),
        _getActiveChildrenCount(userId),
        _getRecentActivities(userId),
      ]);

      return DashboardStats(
        totalStoriesListened: results[0] as int,
        totalListeningTimeMinutes: results[1] as int,
        favoriteCategory: results[2] as String,
        activeChildren: results[3] as int,
        recentActivities: results[4] as List<RecentActivity>,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      // Return empty stats on error
      return DashboardStats.empty();
    }
  }

  /// Get total number of stories listened
  Future<int> _getTotalStoriesListened(String userId) async {
    try {
      final response = await _supabase
          .from('listens')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting total stories: $e');
      return 0;
    }
  }

  /// Get total listening time in minutes
  Future<int> _getTotalListeningTime(String userId) async {
    try {
      final response = await _supabase
          .from('listens')
          .select('duration_seconds')
          .eq('user_id', userId);

      if (response is List && response.isNotEmpty) {
        final totalSeconds = response.fold<int>(
          0,
          (sum, listen) => sum + (listen['duration_seconds'] as int? ?? 0),
        );
        return (totalSeconds / 60).round();
      }
      return 0;
    } catch (e) {
      print('Error getting listening time: $e');
      return 0;
    }
  }

  /// Get most popular story category
  Future<String> _getFavoriteCategory(String userId) async {
    try {
      // Query to get most listened category
      final response = await _supabase.rpc(
        'get_favorite_category',
        params: {'user_uuid': userId},
      );

      if (response != null && response.isNotEmpty) {
        return response as String;
      }
      return 'None';
    } catch (e) {
      // Fallback: query manually
      print('RPC failed, using fallback: $e');
      try {
        final listens = await _supabase
            .from('listens')
            .select('story_id')
            .eq('user_id', userId);

        if (listens is List && listens.isNotEmpty) {
          // Get story categories
          final storyIds = listens.map((l) => l['story_id']).toSet().toList();
          final stories = await _supabase
              .from('stories')
              .select('category')
              .inFilter('id', storyIds);

          // Count categories
          final categoryCount = <String, int>{};
          for (final story in stories as List) {
            final category = story['category'] as String;
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
          }

          if (categoryCount.isNotEmpty) {
            return categoryCount.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }
        }
      } catch (e2) {
        print('Fallback also failed: $e2');
      }
      return 'Moral Stories'; // Default
    }
  }

  /// Get number of active children profiles
  Future<int> _getActiveChildrenCount(String userId) async {
    try {
      final response = await _supabase
          .from('child_profiles')
          .select('id')
          .eq('user_id', userId);

      return (response as List).length;
    } catch (e) {
      print('Error getting active children: $e');
      return 0;
    }
  }

  /// Get recent listening activities
  Future<List<RecentActivity>> _getRecentActivities(String userId,
      {int limit = 5}) async {
    try {
      final response = await _supabase
          .from('listens')
          .select('''
            duration_seconds,
            completed,
            listened_at,
            stories!inner(id, title, category, thumbnail_url),
            child_profiles!inner(name)
          ''')
          .eq('user_id', userId)
          .order('listened_at', ascending: false)
          .limit(limit);

      if (response is List) {
        return response.map((item) {
          return RecentActivity(
            childName: item['child_profiles']?['name'] ?? 'Unknown',
            storyTitle: item['stories']?['title'] ?? 'Unknown Story',
            storyId: item['stories']?['id'] ?? '',
            durationMinutes: ((item['duration_seconds'] ?? 0) / 60).round(),
            completed: item['completed'] ?? false,
            timestamp: DateTime.parse(item['listened_at']),
            thumbnailUrl: item['stories']?['thumbnail_url'],
            category: item['stories']?['category'],
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting recent activities: $e');
      return [];
    }
  }

  /// Stream of real-time updates (for future use)
  Stream<DashboardStats> watchDashboardStats() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      return Stream.value(DashboardStats.empty());
    }

    // Listen to listens table changes
    return _supabase
        .from('listens')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .asyncMap((_) => getDashboardStats());
  }
}

