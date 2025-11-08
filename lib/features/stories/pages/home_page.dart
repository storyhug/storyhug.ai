import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:math';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/child_profile.dart';
import '../services/story_service.dart';
import '../../../shared/models/story.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../subscription/services/stripe_subscription_service.dart';
import '../providers/story_provider.dart';
import '../providers/favorites_provider.dart';
import '../widgets/animated_favorite_button.dart';
import '../../../shared/widgets/storyhug_background.dart';

class HomePage extends ConsumerStatefulWidget {
  final ChildProfile? childProfile;
  
  const HomePage({super.key, this.childProfile});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  String _userName = 'there';
  bool _isPremium = false;
  bool _isCheckingPremium = true;
  final StripeSubscriptionService _subscriptionService = StripeSubscriptionService();
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    _loadUserName();
    _checkPremiumStatus();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart animation when widget updates with new data
    if (oldWidget.childProfile != widget.childProfile) {
      _listAnimationController.reset();
      _listAnimationController.forward();
    }
  }

  Future<void> _loadUserName() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final fullName = user.userMetadata?['full_name'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          setState(() {
            _userName = fullName.split(' ').first; // Use first name only
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  Future<void> _checkPremiumStatus() async {
    try {
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final isPremium = await _subscriptionService.isPremiumActive(user.id);
        setState(() {
          _isPremium = isPremium;
          _isCheckingPremium = false;
        });
      } else {
        setState(() {
          _isPremium = false;
          _isCheckingPremium = false;
        });
      }
    } catch (e) {
      print('Error checking premium status: $e');
      setState(() {
        _isPremium = false;
        _isCheckingPremium = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final storyState = ref.watch(storyProvider);
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        // Show exit confirmation dialog
        _showExitDialog(context);
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          toolbarHeight: 82,
          titleSpacing: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: null,
          actions: const <Widget>[],
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
                    child: Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              'assets/branding/storyhug_logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.auto_stories, color: AppTheme.accentColor, size: 28),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0, end: 1),
                            builder: (context, value, child) => Opacity(opacity: value, child: child),
                            child: RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 17,
                                  color: Colors.white,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Hey ',
                                    style: TextStyle(
                                      fontStyle: FontStyle.italic,
                                      color: Color(0xFFFFD85A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(text: _userName),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        _buildPremiumStarButton(),
                        const SizedBox(width: 6),
                        IconButton(
                          iconSize: 26,
                          splashRadius: 22,
                          icon: const Icon(Icons.search, color: Colors.white),
                          onPressed: () => context.go('/search'),
                          tooltip: 'Search Stories',
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          iconSize: 26,
                          splashRadius: 22,
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () => ref.read(storyProvider.notifier).refresh(),
                          tooltip: 'Refresh Stories',
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          iconSize: 26,
                          splashRadius: 22,
                          icon: const Icon(Icons.dashboard, color: Colors.white),
                          onPressed: () => context.go('/parental-dashboard'),
                          tooltip: 'Dashboard',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: StoryHugBackground(
          showStars: true,
          animateStars: true,
          child: SafeArea(
            child: storyState.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.accentColor,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(storyProvider.notifier).refresh(),
                    color: AppTheme.accentColor,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          _buildCategories(storyState),
                          const SizedBox(height: 24),
                          _buildFeaturedStories(storyState),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit StoryHug?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Exit the app
              SystemNavigator.pop();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }


  Widget _buildWelcomeBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD85A).withValues(alpha: 0.4),
            const Color(0xFFFF8CB3).withValues(alpha: 0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD85A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌟 Ready for a Story?',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Let\'s explore magical adventures together!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_stories,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories(StoryState storyState) {
    final categoryColors = [
      [Colors.pink.shade400, Colors.purple.shade600],
      [Colors.blue.shade400, Colors.cyan.shade600],
      [Colors.orange.shade400, Colors.red.shade600],
      [Colors.green.shade400, Colors.teal.shade600],
      [Colors.indigo.shade400, Colors.purple.shade600],
      [Colors.teal.shade400, Colors.green.shade600],
    ];

    if (storyState.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Story Categories',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '${storyState.categories.length} categories',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: storyState.categories.length,
            itemBuilder: (context, index) {
              final category = storyState.categories[index];
              final storyCount = storyState.categorizedStories[category]?.length ?? 0;
              final colors = categoryColors[index % categoryColors.length];
              
              return Container(
                width: 130,
                margin: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    context.go('/search', extra: {'category': category});
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: const SizedBox.expand(),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                        ),
                        Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getCategoryIcon(category),
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              Text(
                                category,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
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
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$storyCount ${storyCount == 1 ? 'story' : 'stories'}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedStories(StoryState storyState) {
    final storyColors = [
      [Colors.indigo.shade400, Colors.purple.shade600],
      [Colors.pink.shade400, Colors.red.shade600],
      [Colors.blue.shade400, Colors.indigo.shade600],
      [Colors.teal.shade400, Colors.green.shade600],
      [Colors.orange.shade400, Colors.deepOrange.shade600],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Featured Stories',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              '${storyState.featuredStories.length} stories',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        storyState.featuredStories.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.menu_book,
                        size: 64,
                        color: Colors.white54,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stories available yet',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.read(storyProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: storyState.featuredStories.length,
                itemBuilder: (context, index) {
                  final story = storyState.featuredStories[index];
                  final colors = storyColors[index % storyColors.length];
                  
                  // Create staggered animation for each item
                  final animation = Tween<double>(
                    begin: 0.0,
                    end: 1.0,
                  ).animate(CurvedAnimation(
                    parent: _listAnimationController,
                    curve: Interval(
                      (index * 0.1).clamp(0.0, 0.9),
                      ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                      curve: Curves.easeOut,
                    ),
                  ));
                  
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.3),
                        end: Offset.zero,
                      ).animate(animation),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => context.go('/player', extra: story),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  colors[0].withValues(alpha: 0.4),
                                  colors[1].withValues(alpha: 0.3),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colors[1].withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
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
                                        color: colors[1].withValues(alpha: 0.4),
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
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.access_time,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${story.durationMinutes} min',
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              story.category,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white.withValues(alpha: 0.8),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Favorite button
                                AnimatedFavoriteButton(
                                  storyId: story.id,
                                  storyTitle: story.title,
                                ),
                                // Play button
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: colors[1],
                                    size: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'moral stories':
        return Icons.favorite;
      case 'indian mythology':
        return Icons.temple_hindu;
      case 'adventure':
        return Icons.explore;
      case 'fairy tales':
        return Icons.auto_awesome;
      default:
        return Icons.book;
    }
  }

  Widget _buildPremiumStarButton() {
    if (_isCheckingPremium) {
      return IconButton(
        icon: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
        onPressed: null,
        tooltip: 'Checking Premium Status...',
      );
    }

    return PopupMenuButton<String>(
      icon: Stack(
        children: [
          Icon(
            _isPremium ? Icons.star : Icons.star_border,
            color: _isPremium ? Colors.amber : Colors.white,
            size: 24,
          ),
          if (!_isPremium)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      tooltip: _isPremium ? 'Premium Active' : 'Upgrade to Premium',
      onSelected: (value) {
        switch (value) {
          case 'subscription':
            context.go('/subscription');
            break;
          case 'voice_cloning':
            if (_isPremium) {
              context.go('/voice-cloning');
            } else {
              _showPremiumRequiredDialog('Voice Cloning');
            }
            break;
          case 'offline_download':
            if (_isPremium) {
              _showOfflineDownloadDialog();
            } else {
              _showPremiumRequiredDialog('Offline Downloads');
            }
            break;
          case 'premium_features':
            _showPremiumFeaturesDialog();
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'subscription',
          child: Row(
            children: [
              Icon(
                _isPremium ? Icons.star : Icons.star_border,
                color: _isPremium ? Colors.amber : Colors.grey,
              ),
              const SizedBox(width: 12),
              Text(_isPremium ? 'Premium Active' : 'Upgrade to Premium'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'voice_cloning',
          child: Row(
            children: [
              Icon(
                Icons.record_voice_over,
                color: _isPremium ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 12),
              const Text('Voice Cloning'),
              if (!_isPremium) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        PopupMenuItem(
          value: 'offline_download',
          child: Row(
            children: [
              Icon(
                Icons.download,
                color: _isPremium ? Colors.white : Colors.grey,
              ),
              const SizedBox(width: 12),
              const Text('Offline Downloads'),
              if (!_isPremium) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'premium_features',
          child: Row(
            children: [
              const Icon(Icons.info_outline),
              const SizedBox(width: 12),
              const Text('Premium Features'),
            ],
          ),
        ),
      ],
    );
  }

  void _showPremiumRequiredDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Premium Required'),
          ],
        ),
        content: Text('$feature is a premium feature. Upgrade to access this functionality.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/subscription');
            },
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showPremiumFeaturesDialog() {
    final premiumFeatures = _subscriptionService.getPremiumFeatures();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('Premium Features'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPremium 
                    ? 'You have access to all premium features!'
                    : 'Upgrade to unlock these premium features:',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...premiumFeatures.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      _isPremium ? Icons.check_circle : Icons.lock,
                      color: _isPremium ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature)),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!_isPremium)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/subscription');
              },
              child: const Text('Upgrade Now'),
            ),
        ],
      ),
    );
  }

  void _showOfflineDownloadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text('Offline Downloads'),
          ],
        ),
        content: const Text('Download stories for offline listening. This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

