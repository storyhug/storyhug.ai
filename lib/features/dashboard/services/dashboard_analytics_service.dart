import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../models/dashboard_stats.dart';
import '../../player/services/listen_cache_service.dart';

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
      print('[DASHBOARD] getDashboardStats called');
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        print('[DASHBOARD] ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('[DASHBOARD] Fetching stats for userId: $userId');

      // Fetch all data in parallel for better performance
      final results = await Future.wait([
        _getTotalStoriesListened(userId),
        _getTotalListeningTime(userId),
        _getFavoriteCategory(userId),
        _getActiveChildrenCount(userId),
        _getRecentActivities(userId),
      ]);

      final stats = DashboardStats(
        totalStoriesListened: results[0] as int,
        totalListeningTimeMinutes: results[1] as int,
        favoriteCategory: results[2] as String,
        activeChildren: results[3] as int,
        recentActivities: results[4] as List<RecentActivity>,
        lastUpdated: DateTime.now(),
      );

      print(
        '[DASHBOARD] Stats fetched: stories=${stats.totalStoriesListened}, time=${stats.totalListeningTimeMinutes}m, activities=${stats.recentActivities.length}',
      );

      return stats;
    } catch (e) {
      print('[DASHBOARD] ERROR fetching dashboard stats: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      // Return empty stats on error
      return DashboardStats.empty();
    }
  }

  /// Get total number of stories listened (includes cached listens)
  Future<int> _getTotalStoriesListened(String userId) async {
    try {
      print('[DASHBOARD] Fetching total stories listened for userId: $userId');

      final Set<String> uniqueStories = {};

      // Get from Supabase
      try {
        final response = await _supabase
            .from('listens')
            .select('story_id')
            .eq('user_id', userId);

        if (response is List) {
          response
              .map((item) => item['story_id'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .forEach((id) => uniqueStories.add(id));
        }
      } catch (e) {
        print('[DASHBOARD] Error fetching from Supabase: $e');
      }

      // Add cached listens for this user
      try {
        final cachedListens = await ListenCacheService.getPendingListens();
        cachedListens
            .where((listen) => listen['user_id'] == userId)
            .map((listen) => listen['story_id'] as String? ?? '')
            .where((id) => id.isNotEmpty)
            .forEach((id) => uniqueStories.add(id));
      } catch (e) {
        print('[DASHBOARD] Error fetching from cache: $e');
      }

      final count = uniqueStories.length;
      print(
        '[DASHBOARD] Total unique stories listened: $count (includes cached)',
      );
      return count;
    } catch (e) {
      print('[DASHBOARD] ERROR getting total stories: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      return 0;
    }
  }

  /// Get total listening time in minutes (includes cached listens)
  Future<int> _getTotalListeningTime(String userId) async {
    try {
      print('[DASHBOARD] Fetching total listening time for userId: $userId');

      // Get from Supabase
      int totalSeconds = 0;
      try {
        final response = await _supabase
            .from('listens')
            .select('duration_seconds')
            .eq('user_id', userId);

        if (response is List && response.isNotEmpty) {
          totalSeconds = response.fold<int>(
            0,
            (sum, listen) => sum + (listen['duration_seconds'] as int? ?? 0),
          );
        }
      } catch (e) {
        print('[DASHBOARD] Error fetching from Supabase: $e');
      }

      // Add cached listens for this user
      try {
        final cachedListens = await ListenCacheService.getPendingListens();
        final userCachedSeconds = cachedListens
            .where((listen) => listen['user_id'] == userId)
            .fold<int>(
              0,
              (sum, listen) => sum + (listen['duration_seconds'] as int? ?? 0),
            );

        totalSeconds += userCachedSeconds;
        if (userCachedSeconds > 0) {
          print('[DASHBOARD] Added ${userCachedSeconds}s from cache');
        }
      } catch (e) {
        print('[DASHBOARD] Error fetching from cache: $e');
      }

      final minutes = (totalSeconds / 60).round();
      print('[DASHBOARD] Total listening time: ${totalSeconds}s = ${minutes}m');
      return minutes;
    } catch (e) {
      print('[DASHBOARD] ERROR getting listening time: $e');
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
  Future<List<RecentActivity>> _getRecentActivities(
    String userId, {
    int limit = 5,
  }) async {
    try {
      print('[DASHBOARD] Fetching recent activities for userId: $userId');

      final List<Map<String, dynamic>> allListens = [];

      // Get from Supabase
      try {
        final response = await _supabase
            .from('listens')
            .select('''
              id,
              story_id,
              duration_seconds,
              completed,
              listened_at
            ''')
            .eq('user_id', userId)
            .order('listened_at', ascending: false)
            .limit(limit);

        if (response is List) {
          allListens.addAll(
            response.map((item) => Map<String, dynamic>.from(item)),
          );
        }
      } catch (e) {
        print('[DASHBOARD] Error fetching from Supabase: $e');
      }

      // Add cached listens for this user
      try {
        final cachedListens = await ListenCacheService.getPendingListens();
        final userCached = cachedListens
            .where((listen) => listen['user_id'] == userId)
            .map(
              (listen) => {
                'id': 'cached_${listen['cached_at']}',
                'story_id': listen['story_id'],
                'duration_seconds': listen['duration_seconds'],
                'completed': listen['completed'],
                'listened_at': listen['listened_at'],
              },
            )
            .toList();
        allListens.addAll(userCached);
      } catch (e) {
        print('[DASHBOARD] Error fetching from cache: $e');
      }

      // Sort by listened_at (most recent first)
      allListens.sort((a, b) {
        final aTime = DateTime.parse(a['listened_at'] ?? '2000-01-01');
        final bTime = DateTime.parse(b['listened_at'] ?? '2000-01-01');
        return bTime.compareTo(aTime);
      });

      // Take only the most recent ones
      final recentListens = allListens.take(limit).toList();

      print(
        '[DASHBOARD] Found ${recentListens.length} listens (${allListens.length} total including cache)',
      );

      if (recentListens.isNotEmpty) {
        final activities = <RecentActivity>[];

        for (final item in recentListens) {
          final storyId = item['story_id'] as String? ?? '';
          String storyTitle = 'Unknown Story';
          String? category;
          String? thumbnailUrl;

          // Try to fetch story details from stories table
          if (storyId.isNotEmpty) {
            try {
              final storyResponse = await _supabase
                  .from('stories')
                  .select('title, category, thumbnail_url')
                  .eq('id', storyId)
                  .maybeSingle();

              if (storyResponse != null) {
                storyTitle = storyResponse['title'] ?? 'Unknown Story';
                category = storyResponse['category'];
                thumbnailUrl = storyResponse['thumbnail_url'];
              } else {
                // Try ramayana_stories table
                try {
                  final ramayanaResponse = await _supabase
                      .from('ramayana_stories')
                      .select('title, category')
                      .eq('id', storyId)
                      .maybeSingle();

                  if (ramayanaResponse != null) {
                    storyTitle = ramayanaResponse['title'] ?? 'Unknown Story';
                    category = ramayanaResponse['category'] ?? 'Ramayana';
                  }
                } catch (e) {
                  print('[DASHBOARD] Could not fetch Ramayana story: $e');
                }
              }
            } catch (e) {
              print('[DASHBOARD] Could not fetch story details: $e');
            }
          }

          activities.add(
            RecentActivity(
              childName: 'You',
              storyTitle: storyTitle,
              storyId: storyId,
              durationMinutes: ((item['duration_seconds'] ?? 0) / 60).round(),
              completed: item['completed'] ?? false,
              timestamp: DateTime.parse(item['listened_at']),
              thumbnailUrl: thumbnailUrl,
              category: category,
            ),
          );
        }

        print('[DASHBOARD] Returning ${activities.length} activities');
        return activities;
      }

      print('[DASHBOARD] No listens found');
      return [];
    } catch (e) {
      print('[DASHBOARD] ERROR getting recent activities: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
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
