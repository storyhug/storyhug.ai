import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';

class AnimatedFavoriteButton extends ConsumerStatefulWidget {
  final String storyId;
  final String storyTitle;
  final double size;

  const AnimatedFavoriteButton({
    super.key,
    required this.storyId,
    required this.storyTitle,
    this.size = 28,
  });

  @override
  ConsumerState<AnimatedFavoriteButton> createState() =>
      _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState
    extends ConsumerState<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.4, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final favorites = ref.read(favoritesNotifierProvider);
      final isFavorite = favorites.contains(widget.storyId);

      // Play animation
      await _controller.forward();
      _controller.reset();

      // Toggle favorite with story title
      await ref.read(favoritesNotifierProvider.notifier).toggleFavorite(
            widget.storyId,
            storyTitle: widget.storyTitle,
          );

      // Show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars(); // Clear existing
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFavorite ? Icons.heart_broken : Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isFavorite
                        ? 'Removed from favorites'
                        : 'Added to favorites',
                  ),
                ),
              ],
            ),
            backgroundColor:
                isFavorite ? Colors.grey.shade700 : Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = ref.watch(favoritesNotifierProvider);
    final isFavorite = favorites.contains(widget.storyId);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite
              ? Colors.red
              : Colors.white.withValues(alpha: 0.7),
          size: widget.size,
        ),
        onPressed: _isProcessing ? null : _toggleFavorite,
        tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
      ),
    );
  }
}



