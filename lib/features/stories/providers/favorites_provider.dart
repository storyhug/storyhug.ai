import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/favorites_service.dart';

/// Provider for favorites service
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

/// Provider for favorite story IDs
final favoritesProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  final service = ref.watch(favoritesServiceProvider);
  return await service.getFavoriteStoryIds();
});

/// Stream provider for real-time favorites updates
final favoritesStreamProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return service.watchFavorites();
});

/// State provider for managing favorites locally
class FavoritesNotifier extends StateNotifier<Set<String>> {
  final FavoritesService _service;

  FavoritesNotifier(this._service) : super({}) {
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    state = await _service.getFavoriteStoryIds();
  }

  Future<void> toggleFavorite(
    String storyId, {
    String? storyTitle,
  }) async {
    final isFavorite = state.contains(storyId);
    
    // Optimistic update
    if (isFavorite) {
      state = Set.from(state)..remove(storyId);
    } else {
      state = Set.from(state)..add(storyId);
    }

    // Sync with backend
    final success = await _service.toggleFavorite(
      storyId,
      isFavorite,
      storyTitle: storyTitle,
    );
    
    if (!success) {
      // Revert on failure
      if (isFavorite) {
        state = Set.from(state)..add(storyId);
      } else {
        state = Set.from(state)..remove(storyId);
      }
    }
  }

  Future<void> refresh() async {
    await _loadFavorites();
  }
}

final favoritesNotifierProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  final service = ref.watch(favoritesServiceProvider);
  return FavoritesNotifier(service);
});


