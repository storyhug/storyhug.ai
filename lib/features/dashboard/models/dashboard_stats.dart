/// Model for dashboard statistics
class DashboardStats {
  final int totalStoriesListened;
  final int totalListeningTimeMinutes;
  final String favoriteCategory;
  final int activeChildren;
  final List<RecentActivity> recentActivities;
  final DateTime lastUpdated;

  DashboardStats({
    required this.totalStoriesListened,
    required this.totalListeningTimeMinutes,
    required this.favoriteCategory,
    required this.activeChildren,
    required this.recentActivities,
    required this.lastUpdated,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalStoriesListened: 0,
      totalListeningTimeMinutes: 0,
      favoriteCategory: 'None',
      activeChildren: 0,
      recentActivities: [],
      lastUpdated: DateTime.now(),
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalStoriesListened: json['total_stories'] ?? 0,
      totalListeningTimeMinutes: json['total_minutes'] ?? 0,
      favoriteCategory: json['favorite_category'] ?? 'None',
      activeChildren: json['active_children'] ?? 0,
      recentActivities: (json['recent_activities'] as List?)
              ?.map((e) => RecentActivity.fromJson(e))
              .toList() ??
          [],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_stories': totalStoriesListened,
      'total_minutes': totalListeningTimeMinutes,
      'favorite_category': favoriteCategory,
      'active_children': activeChildren,
      'recent_activities': recentActivities.map((e) => e.toJson()).toList(),
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  String get formattedListeningTime {
    final hours = totalListeningTimeMinutes ~/ 60;
    final minutes = totalListeningTimeMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }
}

class RecentActivity {
  final String childName;
  final String storyTitle;
  final String storyId;
  final int durationMinutes;
  final bool completed;
  final DateTime timestamp;
  final String? thumbnailUrl;
  final String? category;

  RecentActivity({
    required this.childName,
    required this.storyTitle,
    required this.storyId,
    required this.durationMinutes,
    required this.completed,
    required this.timestamp,
    this.thumbnailUrl,
    this.category,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      childName: json['child_name'] ?? 'Unknown',
      storyTitle: json['story_title'] ?? 'Unknown Story',
      storyId: json['story_id'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 0,
      completed: json['completed'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      thumbnailUrl: json['thumbnail_url'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'child_name': childName,
      'story_title': storyTitle,
      'story_id': storyId,
      'duration_minutes': durationMinutes,
      'completed': completed,
      'timestamp': timestamp.toIso8601String(),
      'thumbnail_url': thumbnailUrl,
      'category': category,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inSeconds < 60) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${difference.inDays ~/ 7}w ago';
  }
}

