import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../services/dashboard_analytics_service.dart';

/// Provider for dashboard analytics service
final dashboardAnalyticsServiceProvider = Provider<DashboardAnalyticsService>(
  (ref) => DashboardAnalyticsService(),
);

/// Provider for dashboard statistics with auto-refresh
final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final service = ref.watch(dashboardAnalyticsServiceProvider);
  
  // Auto-refresh every 30 seconds
  final timer = Stream.periodic(const Duration(seconds: 30));
  ref.listen(StreamProvider((ref) => timer), (_, __) {
    ref.invalidateSelf();
  });

  return await service.getDashboardStats();
});

/// Provider for manual refresh trigger
final dashboardRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider that refreshes when manual trigger is invoked
final refreshableDashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  // Watch the refresh trigger
  ref.watch(dashboardRefreshProvider);
  
  final service = ref.watch(dashboardAnalyticsServiceProvider);
  return await service.getDashboardStats();
});

/// Stream provider for real-time updates (optional)
final dashboardStatsStreamProvider =
    StreamProvider.autoDispose<DashboardStats>((ref) {
  final service = ref.watch(dashboardAnalyticsServiceProvider);
  return service.watchDashboardStats();
});

