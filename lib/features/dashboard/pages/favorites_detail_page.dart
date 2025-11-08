import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/story.dart';
import '../../stories/providers/favorites_provider.dart';

class FavoritesDetailPage extends ConsumerStatefulWidget {
  const FavoritesDetailPage({super.key});

  @override
  ConsumerState<FavoritesDetailPage> createState() =>
      _FavoritesDetailPageState();
}

class _FavoritesDetailPageState extends ConsumerState<FavoritesDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<List<Story>> _loadFavoriteStories(Set<String> favoriteIds) async {
    if (favoriteIds.isEmpty) return [];

    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) return [];

      // Load directly from favorite_stories table (simplified version)
      final response = await SupabaseService.client
          .from('favorite_stories')
          .select('story_id, story_title, added_at')
          .eq('user_id', userId)
          .order('added_at', ascending: false);

      // Convert favorites data to Story objects (with minimal data)
      return (response as List<dynamic>).map<Story>((fav) {
        return Story(
          id: fav['story_id'] as String,
          title: fav['story_title'] as String? ?? 'Unknown Story',
          body: '', // Not stored in favorites
          category: 'Story', // Not stored in simplified version
          minAge: 3, // Default value
          maxAge: 12, // Default value
          audioDefaultUrl: '', // Not stored in favorites
          durationMinutes: 0, // Not stored in favorites
          thumbnailUrl: null, // Not stored in simplified version
          createdAt: DateTime.parse(fav['added_at'] as String),
          updatedAt: DateTime.parse(fav['added_at'] as String),
        );
      }).toList();
    } catch (e) {
      print('Error loading favorite stories: $e');
      return [];
    }
  }

  Future<void> _removeFavorite(String storyId, String storyTitle) async {
    await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(
          storyId,
          storyTitle: storyTitle,
        );
    
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Removed from favorites'),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(milliseconds: 1500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // WATCH the favorites provider for real-time updates
    final favoriteIds = ref.watch(favoritesNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Favorite Stories',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/parental-dashboard');
            }
          },
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: favoriteIds.isEmpty
              ? _buildEmptyState()
              : FutureBuilder<List<Story>>(
                  future: _loadFavoriteStories(favoriteIds),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentColor,
                        ),
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                      return _buildEmptyState();
                    }

                    return _buildFavoritesList(snapshot.data!);
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.white.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No favorite stories yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on stories to add them here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<Story> favoriteStories) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favoriteStories.length,
      itemBuilder: (context, index) {
        final story = favoriteStories[index];
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              index * 0.1,
              1.0,
              curve: Curves.easeOut,
            ),
          )),
          child: FadeTransition(
            opacity: _animationController,
            child: _buildStoryCard(story, index),
          ),
        );
      },
    );
  }

  Widget _buildStoryCard(Story story, int index) {
    final gradientColors = [
      [const Color(0xFFFF6B9D), const Color(0xFFC239B3)],
      [const Color(0xFF4FC3F7), const Color(0xFF2962FF)],
      [const Color(0xFFFFD54F), const Color(0xFFFF9800)],
      [const Color(0xFF81C784), const Color(0xFF4CAF50)],
    ];
    
    final colors = gradientColors[index % gradientColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors[0].withOpacity(0.3),
            colors[1].withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/player', extra: story),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Story thumbnail
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors[1].withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: story.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            story.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.auto_stories,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.auto_stories,
                          color: Colors.white,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                // Story info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          story.category,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Remove button
                IconButton(
                  icon: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 28,
                  ),
                  onPressed: () => _removeFavorite(story.id, story.title),
                  tooltip: 'Remove from favorites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

