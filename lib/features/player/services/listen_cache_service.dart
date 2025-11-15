import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/supabase_service.dart';

/// Local cache for listens to ensure they're never lost
class ListenCacheService {
  static const String _cacheKey = 'pending_listens';
  static const String _syncedKey = 'synced_listens';

  /// Save listen to local cache
  static Future<void> cacheListen({
    required String storyId,
    required String userId,
    required int durationSeconds,
    required bool completed,
    required String listenedAt,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedListens = prefs.getStringList(_cacheKey) ?? [];

      final listenData = {
        'story_id': storyId,
        'user_id': userId,
        'duration_seconds': durationSeconds,
        'completed': completed,
        'listened_at': listenedAt,
        'cached_at': DateTime.now().toIso8601String(),
      };

      cachedListens.add(jsonEncode(listenData));
      await prefs.setStringList(_cacheKey, cachedListens);

      print(
        '[CACHE] Listen cached locally: storyId=$storyId, duration=${durationSeconds}s',
      );
    } catch (e) {
      print('[CACHE] ERROR caching listen: $e');
    }
  }

  /// Get all pending listens from cache
  static Future<List<Map<String, dynamic>>> getPendingListens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedListens = prefs.getStringList(_cacheKey) ?? [];

      return cachedListens.map((json) {
        return Map<String, dynamic>.from(jsonDecode(json));
      }).toList();
    } catch (e) {
      print('[CACHE] ERROR getting pending listens: $e');
      return [];
    }
  }

  /// Mark listen as synced (remove from cache)
  static Future<void> markAsSynced(String listenJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedListens = prefs.getStringList(_cacheKey) ?? [];

      cachedListens.remove(listenJson);
      await prefs.setStringList(_cacheKey, cachedListens);

      // Also track synced listens
      final syncedListens = prefs.getStringList(_syncedKey) ?? [];
      syncedListens.add(listenJson);
      await prefs.setStringList(_syncedKey, syncedListens);

      print('[CACHE] Listen marked as synced');
    } catch (e) {
      print('[CACHE] ERROR marking as synced: $e');
    }
  }

  /// Sync all pending listens to Supabase
  static Future<void> syncPendingListens() async {
    try {
      final pending = await getPendingListens();
      if (pending.isEmpty) {
        print('[CACHE] No pending listens to sync');
        return;
      }

      print('[CACHE] Syncing ${pending.length} pending listens...');

      // Import SupabaseService
      final supabase = SupabaseService.client;

      final List<String> syncedJson = [];

      for (final listen in pending) {
        try {
          await supabase.from('listens').insert({
            'story_id': listen['story_id'],
            'user_id': listen['user_id'],
            'duration_seconds': listen['duration_seconds'],
            'completed': listen['completed'],
            'listened_at': listen['listened_at'],
          });

          syncedJson.add(jsonEncode(listen));
          print('[CACHE] ✅ Synced listen: ${listen['story_id']}');
        } catch (e) {
          print('[CACHE] ⚠️ Failed to sync listen: $e');
          // Keep in cache for next sync attempt
        }
      }

      // Mark all successfully synced listens
      for (final json in syncedJson) {
        await markAsSynced(json);
      }

      print('[CACHE] Synced ${syncedJson.length}/${pending.length} listens');
    } catch (e) {
      print('[CACHE] ERROR syncing pending listens: $e');
    }
  }

  /// Clear all cached listens (use with caution)
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('[CACHE] Cache cleared');
    } catch (e) {
      print('[CACHE] ERROR clearing cache: $e');
    }
  }
}
