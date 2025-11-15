import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../subscription/services/subscription_service.dart';
import '../../voice_cloning/services/voice_cloning_service.dart';
import '../../../shared/models/user_voice.dart';
import '../../../shared/widgets/storyhug_background.dart';
import '../../../shared/responsive.dart';
import '../services/dashboard_analytics_service.dart';
import '../models/dashboard_stats.dart';

class ParentalDashboardPage extends StatefulWidget {
  const ParentalDashboardPage({super.key});

  @override
  State<ParentalDashboardPage> createState() => _ParentalDashboardPageState();
}

class _ParentalDashboardPageState extends State<ParentalDashboardPage> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  final DashboardAnalyticsService _analyticsService =
      DashboardAnalyticsService();

  bool _isLoading = true;
  int _totalStoriesListened = 0;
  int _totalListeningTime = 0; // in minutes
  String _mostPopularCategory = 'Moral Stories';
  int _activeChildren = 0;
  List<RecentActivity> _recentActivity = [];
  List<UserVoice> _userVoices = [];
  bool _isLoadingVoices = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadUserVoices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh dashboard when returning to this page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[DASHBOARD] Page visible - refreshing data');
      _loadDashboardData();
    });
  }

  Future<void> _loadDashboardData() async {
    try {
      print('[DASHBOARD] Fetch stats started');
      setState(() {
        _isLoading = true;
      });

      final stats = await _analyticsService.getDashboardStats();

      print('[DASHBOARD] Fetch stats completed');
      print(
        '[DASHBOARD] Stories: ${stats.totalStoriesListened}, Listening: ${stats.totalListeningTimeMinutes}m, Activity count: ${stats.recentActivities.length}',
      );

      setState(() {
        _totalStoriesListened = stats.totalStoriesListened;
        _totalListeningTime = stats.totalListeningTimeMinutes;
        _mostPopularCategory =
            stats.favoriteCategory.isNotEmpty &&
                stats.favoriteCategory != 'None'
            ? stats.favoriteCategory
            : 'Moral Stories';
        _activeChildren = stats.activeChildren;
        _recentActivity = stats.recentActivities;
        _isLoading = false;
      });
    } catch (e) {
      print('[DASHBOARD] Fetch stats ERROR: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserVoices() async {
    try {
      setState(() {
        _isLoadingVoices = true;
      });

      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final voices = await _voiceCloningService.getUserVoices(userId);
        setState(() {
          _userVoices = voices;
          _isLoadingVoices = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user voices: $e');
      setState(() {
        _isLoadingVoices = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Parental Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Navigate to home page with a child profile
            context.go('/home');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () async {
              print('[DASHBOARD] Manual refresh triggered');
              setState(() {
                _isLoading = true;
              });
              await _loadDashboardData();
            },
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      body: StoryHugBackground(
        showStars: true,
        animateStars: false,
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Padding(
                      padding: Responsive.responsiveHorizontalPadding(context),
                      child: RefreshIndicator(
                        onRefresh: () async {
                          print('[DASHBOARD] Pull-to-refresh triggered');
                          await _loadDashboardData();
                        },
                        color: AppTheme.accentColor,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header
                              _buildHeader(),
                              SizedBox(
                                height: Responsive.spacingLarge(context),
                              ),

                              // Stats Cards
                              _buildStatsCards(),
                              SizedBox(
                                height: Responsive.spacingLarge(context),
                              ),

                              // Subscription Status
                              _buildSubscriptionStatus(),
                              SizedBox(
                                height: Responsive.spacingLarge(context),
                              ),

                              // Recent Activity
                              _buildRecentActivity(),
                              SizedBox(
                                height: Responsive.spacingLarge(context),
                              ),

                              // Voice Management
                              if (_userVoices.isNotEmpty) ...[
                                _buildVoiceManagement(),
                                SizedBox(
                                  height: Responsive.spacingLarge(context),
                                ),
                              ],

                              // Quick Actions
                              _buildQuickActions(),
                              SizedBox(
                                height: Responsive.spacingLarge(context),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentColor.withValues(alpha: 0.25),
            AppTheme.accentColor.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.dashboard,
              color: AppTheme.accentColor,
              size: Responsive.isDesktop(context) ? 28 : 24,
            ),
          ),
          SizedBox(width: Responsive.spacingMedium(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parental Dashboard',
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      20,
                      22,
                      24,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: Responsive.spacingSmall(context) / 2),
                Text(
                  'Track your child\'s story journey and manage their experience',
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      13,
                      14,
                      15,
                    ),
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = Responsive.gridCrossAxisCount(
          context,
          mobile: 1,
          tablet: 2,
          desktop: 2,
        );

        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: Responsive.spacingMedium(context),
          mainAxisSpacing: Responsive.spacingMedium(context),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: Responsive.isMobile(context) ? 1.8 : 1.6,
          children: [
            _buildStatCard(
              title: 'Stories Listened',
              value: _totalStoriesListened.toString(),
              icon: Icons.book,
              color: AppTheme.primaryColor,
            ),
            _buildStatCard(
              title: 'Listening Time',
              value:
                  '${_totalListeningTime ~/ 60}h ${_totalListeningTime % 60}m',
              icon: Icons.timer,
              color: AppTheme.accentColor,
            ),
            _buildStatCard(
              title: 'Favorite Category',
              value: _mostPopularCategory,
              icon: Icons.favorite,
              color: Colors.pink,
            ),
            _buildStatCard(
              title: 'Active Children',
              value: _activeChildren.toString(),
              icon: Icons.child_care,
              color: Colors.blue,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Responsive.isDesktop(context) ? 10 : 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: Responsive.isDesktop(context) ? 22 : 20,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      20,
                      22,
                      24,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.spacingMedium(context)),
          Text(
            title,
            style: TextStyle(
              fontSize: Responsive.responsiveFontSize(context, 12, 13, 14),
              color: Colors.white.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionStatus() {
    final isPremium = _subscriptionService.isPremiumActive;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPremium
              ? [
                  AppTheme.accentColor.withValues(alpha: 0.2),
                  AppTheme.accentColor.withValues(alpha: 0.1),
                ]
              : [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.08),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPremium
              ? AppTheme.accentColor.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isPremium
                ? AppTheme.accentColor.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(Responsive.isDesktop(context) ? 12 : 10),
            decoration: BoxDecoration(
              color: isPremium
                  ? AppTheme.accentColor.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium ? Icons.star : Icons.star_border,
              color: isPremium ? AppTheme.accentColor : Colors.white70,
              size: Responsive.isDesktop(context) ? 26 : 24,
            ),
          ),
          SizedBox(width: Responsive.spacingMedium(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium ? 'Premium Active' : 'Free Plan',
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      18,
                      20,
                      22,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: Responsive.spacingSmall(context) / 2),
                Text(
                  isPremium
                      ? 'You have access to all premium features'
                      : 'Upgrade to unlock unlimited stories and voice cloning',
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      12,
                      13,
                      14,
                    ),
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (!isPremium)
            ElevatedButton(
              onPressed: () => context.go('/subscription'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.black87,
                padding: EdgeInsets.symmetric(
                  horizontal: Responsive.isDesktop(context) ? 24 : 20,
                  vertical: Responsive.isDesktop(context) ? 14 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'UPGRADE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.responsiveFontSize(context, 11, 12, 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(
                    Responsive.isDesktop(context) ? 10 : 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    color: AppTheme.accentColor,
                    size: Responsive.isDesktop(context) ? 22 : 20,
                  ),
                ),
                SizedBox(width: Responsive.spacingMedium(context)),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      16,
                      18,
                      20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          if (_recentActivity.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      fontSize: Responsive.responsiveFontSize(
                        context,
                        18,
                        20,
                        22,
                      ),
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stories you listen to will appear here',
                    style: TextStyle(
                      fontSize: Responsive.responsiveFontSize(
                        context,
                        14,
                        15,
                        16,
                      ),
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ..._recentActivity.map((activity) => _buildActivityItem(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentActivity activity) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.spacingMedium(context),
        vertical: Responsive.spacingSmall(context) / 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: Responsive.spacingMedium(context),
          vertical: Responsive.spacingSmall(context),
        ),
        leading: Container(
          width: Responsive.isDesktop(context) ? 48 : 40,
          height: Responsive.isDesktop(context) ? 48 : 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: activity.completed
                  ? [
                      AppTheme.successColor.withValues(alpha: 0.3),
                      AppTheme.successColor.withValues(alpha: 0.2),
                    ]
                  : [
                      AppTheme.primaryColor.withValues(alpha: 0.3),
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: activity.completed
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
              width: 2,
            ),
          ),
          child: Icon(
            activity.completed ? Icons.check : Icons.play_arrow,
            color: activity.completed
                ? AppTheme.successColor
                : AppTheme.primaryColor,
            size: Responsive.isDesktop(context) ? 24 : 20,
          ),
        ),
        title: Text(
          activity.storyTitle,
          style: TextStyle(
            fontSize: Responsive.responsiveFontSize(context, 15, 16, 17),
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Responsive.spacingSmall(context) / 2),
            Text(
              '${activity.childName} • ${activity.durationMinutes} min',
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 12, 13, 14),
                color: Colors.white.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: Responsive.spacingSmall(context) / 2),
            Text(
              activity.timeAgo,
              style: TextStyle(
                fontSize: Responsive.responsiveFontSize(context, 11, 12, 13),
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.spacingSmall(context),
            vertical: Responsive.spacingSmall(context) / 2,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: activity.completed
                  ? [
                      AppTheme.successColor.withValues(alpha: 0.3),
                      AppTheme.successColor.withValues(alpha: 0.2),
                    ]
                  : [
                      AppTheme.primaryColor.withValues(alpha: 0.3),
                      AppTheme.primaryColor.withValues(alpha: 0.2),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: activity.completed
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
              width: 1,
            ),
          ),
          child: Text(
            activity.completed ? 'Completed' : 'In Progress',
            style: TextStyle(
              fontSize: Responsive.responsiveFontSize(context, 10, 11, 12),
              fontWeight: FontWeight.w600,
              color: activity.completed
                  ? AppTheme.successColor
                  : AppTheme.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceManagement() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: AppTheme.accentColor,
                  size: Responsive.isDesktop(context) ? 26 : 24,
                ),
                SizedBox(width: Responsive.spacingMedium(context)),
                Text(
                  'My Voices',
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      16,
                      18,
                      20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadUserVoices,
                  icon: _isLoadingVoices
                      ? SizedBox(
                          width: Responsive.isDesktop(context) ? 18 : 16,
                          height: Responsive.isDesktop(context) ? 18 : 16,
                          child: const CircularProgressIndicator(
                            color: Colors.white70,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          color: Colors.white70,
                          size: Responsive.isDesktop(context) ? 24 : 20,
                        ),
                  tooltip: 'Refresh Voices',
                ),
              ],
            ),
          ),
          ..._userVoices.map((voice) => _buildVoiceTile(voice)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/voice-cloning'),
                    icon: const Icon(Icons.add),
                    label: const Text('Record New Voice'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentColor,
                      side: const BorderSide(color: AppTheme.accentColor),
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.isDesktop(context) ? 16 : 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: Responsive.spacingSmall(context)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/voice-diagnostics'),
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Voice Diagnostics'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: EdgeInsets.symmetric(
                        vertical: Responsive.isDesktop(context) ? 16 : 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceTile(UserVoice voice) {
    return ListTile(
      leading: const Icon(Icons.record_voice_over, color: Colors.white70),
      title: Text(voice.voiceName, style: const TextStyle(color: Colors.white)),
      subtitle: voice.voiceDescription != null
          ? Text(
              voice.voiceDescription!,
              style: const TextStyle(color: Colors.white70),
            )
          : null,
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white70),
        onSelected: (value) => _handleVoiceAction(value, voice),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8),
                Text('Rename'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVoiceAction(String action, UserVoice voice) async {
    final userId = SupabaseService.client.auth.currentUser?.id;
    if (userId == null) return;

    switch (action) {
      case 'rename':
        await _renameVoice(voice, userId);
        break;
      case 'delete':
        await _deleteVoice(voice, userId);
        break;
    }
  }

  Future<void> _renameVoice(UserVoice voice, String userId) async {
    final nameController = TextEditingController(text: voice.voiceName);
    final descriptionController = TextEditingController(
      text: voice.voiceDescription ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Voice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Voice Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _voiceCloningService.updateVoice(
          userId,
          voice.voiceId,
          nameController.text.trim(),
          voiceDescription: descriptionController.text.trim().isNotEmpty
              ? descriptionController.text.trim()
              : null,
        );
        await _loadUserVoices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice renamed to ${nameController.text.trim()}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rename voice: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteVoice(UserVoice voice, String userId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice'),
        content: Text(
          'Are you sure you want to delete "${voice.voiceName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _voiceCloningService.deleteVoice(userId, voice.voiceId);
        await _loadUserVoices();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${voice.voiceName} has been deleted'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete voice: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppTheme.accentColor,
                  size: Responsive.isDesktop(context) ? 26 : 24,
                ),
                SizedBox(width: Responsive.spacingMedium(context)),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: Responsive.responsiveFontSize(
                      context,
                      16,
                      18,
                      20,
                    ),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildActionTile(
            title: 'Manage Children',
            subtitle: 'Add, edit, or remove child profiles',
            icon: Icons.child_care,
            onTap: () => context.go('/manage-kids'),
          ),
          _buildActionTile(
            title: 'Voice Cloning',
            subtitle: 'Record your voice for personalized stories',
            icon: Icons.mic,
            onTap: () => context.go('/voice-cloning'),
          ),
          _buildActionTile(
            title: 'Story Tuning Demo 🎯',
            subtitle: 'Test emotion detection, pacing & personalization',
            icon: Icons.psychology,
            onTap: () => context.go('/story-tuning-demo'),
          ),
          const SizedBox(height: 8),
          _buildActionTile(
            title: 'UX & Safety Demo 🧪',
            subtitle: 'Test all new features: Moods, Safety, Consent & More',
            icon: Icons.science,
            onTap: () => context.go('/ux-safety-demo'),
          ),
          _buildActionTile(
            title: 'Import Stories',
            subtitle: 'Upload Ramayana stories from Word document',
            icon: Icons.upload_file,
            onTap: () => context.go('/story-import'),
          ),
          _buildActionTile(
            title: 'Import Bala Kanda',
            subtitle: 'Import the first 10 childhood stories of Rama',
            icon: Icons.child_care,
            onTap: () => context.go('/bala-kanda-import'),
          ),
          _buildActionTile(
            title: 'Preferences',
            subtitle: 'Customize app settings and notifications',
            icon: Icons.settings,
            onTap: () => context.go('/preferences'),
          ),
          _buildActionTile(
            title: 'Reminders',
            subtitle: 'Set up story time reminders',
            icon: Icons.notifications,
            onTap: () => context.go('/reminders'),
          ),
          _buildActionTile(
            title: 'Logout',
            subtitle: 'Sign out of your account',
            icon: Icons.logout,
            onTap: () => _handleLogout(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Responsive.spacingMedium(context),
        vertical: Responsive.spacingSmall(context) / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: Responsive.spacingMedium(context),
          vertical: Responsive.spacingSmall(context),
        ),
        leading: Container(
          padding: EdgeInsets.all(Responsive.isDesktop(context) ? 10 : 8),
          decoration: BoxDecoration(
            color: isDestructive
                ? Colors.red.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.white70,
            size: Responsive.isDesktop(context) ? 22 : 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: Responsive.responsiveFontSize(context, 15, 16, 17),
            fontWeight: FontWeight.w600,
            color: isDestructive ? Colors.red : Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: Responsive.responsiveFontSize(context, 12, 13, 14),
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.all(Responsive.isDesktop(context) ? 6 : 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            color: Colors.white.withValues(alpha: 0.6),
            size: Responsive.isDesktop(context) ? 16 : 14,
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await SupabaseService.client.auth.signOut();
                if (context.mounted) {
                  context.go('/');
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logout failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
