import 'package:go_router/go_router.dart';
import '../../features/splash/pages/splash_page.dart';
import '../../features/auth/pages/welcome_page.dart';
import '../../features/auth/pages/auth_page.dart';
import '../../features/profiles/pages/manage_kids_page.dart';
import '../../features/stories/pages/home_page.dart';
import '../../features/stories/pages/search_page.dart';
import '../../features/player/pages/story_player_screen.dart';
import '../../features/voice_cloning/pages/voice_cloning_page.dart';
import '../../features/voice_cloning/pages/voice_diagnostics_page.dart';
import '../../features/subscription/pages/subscription_page.dart';
import '../../features/preferences/pages/preferences_page.dart';
import '../../features/reminders/pages/reminders_page.dart';
import '../../features/dashboard/pages/parental_dashboard_page.dart';
import '../../features/dashboard/pages/enhanced_parental_dashboard.dart';
import '../../features/dashboard/pages/stories_detail_page.dart';
import '../../features/dashboard/pages/listening_time_detail_page.dart';
import '../../features/dashboard/pages/favorites_detail_page.dart';
import '../../features/stories/pages/story_import_page.dart';
import '../../features/stories/pages/bala_kanda_import_page.dart';
import '../../features/stories/pages/story_tuning_demo_page.dart';
import '../../features/legal/pages/privacy_policy_page.dart';
import '../../features/dashboard/pages/ux_safety_demo_page.dart';
import '../../shared/models/story.dart';
import '../../shared/models/child_profile.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      GoRoute(
        path: '/manage-kids',
        builder: (context, state) => const ManageKidsPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final childProfile = state.extra as ChildProfile?;
          return HomePage(childProfile: childProfile);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/player',
        builder: (context, state) {
          final story = state.extra as Story;
          return StoryPlayerScreen(story: story);
        },
      ),
      GoRoute(
        path: '/voice-cloning',
        builder: (context, state) => const VoiceCloningPage(),
      ),
      GoRoute(
        path: '/voice-diagnostics',
        builder: (context, state) => const VoiceDiagnosticsPage(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, state) => const PreferencesPage(),
      ),
      GoRoute(
        path: '/reminders',
        builder: (context, state) => const RemindersPage(),
      ),
      GoRoute(
        path: '/parental-dashboard',
        builder: (context, state) => const EnhancedParentalDashboard(),
      ),
      GoRoute(
        path: '/parental-dashboard-legacy',
        builder: (context, state) => const ParentalDashboardPage(),
      ),
      GoRoute(
        path: '/story-import',
        builder: (context, state) => const StoryImportPage(),
      ),
      GoRoute(
        path: '/bala-kanda-import',
        builder: (context, state) => const BalaKandaImportPage(),
      ),
      GoRoute(
        path: '/story-tuning-demo',
        builder: (context, state) => const StoryTuningDemoPage(),
      ),
      GoRoute(
        path: '/privacy-policy',
        builder: (context, state) => const PrivacyPolicyPage(),
      ),
      GoRoute(
        path: '/ux-safety-demo',
        builder: (context, state) => const UxSafetyDemoPage(),
      ),
      GoRoute(
        path: '/dashboard/stories-detail',
        builder: (context, state) => const StoriesDetailPage(),
      ),
      GoRoute(
        path: '/dashboard/listening-time-detail',
        builder: (context, state) => const ListeningTimeDetailPage(),
      ),
      GoRoute(
        path: '/dashboard/favorites-detail',
        builder: (context, state) => const FavoritesDetailPage(),
      ),
    ],
  );
}
