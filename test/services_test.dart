import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:storyhug_app/features/auth/services/auth_service.dart';
import 'package:storyhug_app/features/stories/services/story_service.dart';
import 'package:storyhug_app/features/profiles/services/profile_service.dart';
import 'package:storyhug_app/features/subscription/services/subscription_service.dart';
import 'package:storyhug_app/features/player/services/audio_player_service.dart';
import 'package:storyhug_app/shared/models/story.dart';
import 'package:storyhug_app/shared/models/child_profile.dart';

void main() {
  group('AuthService Tests', () {
    late AuthService authService;

    setUp(() {
      authService = AuthService();
    });

    test('should initialize with null current user', () {
      expect(authService.currentUser, isNull);
    });

    test('should have auth state changes stream', () {
      expect(authService.authStateChanges, isA<Stream<dynamic>>());
    });
  });

  group('StoryService Tests', () {
    test('should return sample stories', () {
      final stories = StoryService.getSampleStories();
      
      expect(stories, isNotEmpty);
      expect(stories.length, equals(5));
      
      // Test first story properties
      final firstStory = stories.first;
      expect(firstStory.id, isNotEmpty);
      expect(firstStory.title, isNotEmpty);
      expect(firstStory.body, isNotEmpty);
      expect(firstStory.category, isNotEmpty);
      expect(firstStory.minAge, isA<int>());
      expect(firstStory.maxAge, isA<int>());
      expect(firstStory.audioDefaultUrl, isNotEmpty);
      expect(firstStory.durationMinutes, isA<int>());
      expect(firstStory.createdAt, isA<DateTime>());
    });

    test('should have valid story categories', () {
      final stories = StoryService.getSampleStories();
      final categories = stories.map((s) => s.category).toSet();
      
      expect(categories, contains('Moral Stories'));
      expect(categories, contains('Indian Mythology'));
      expect(categories, contains('Adventure'));
      expect(categories, contains('Fairy Tales'));
    });

    test('should have age-appropriate stories', () {
      final stories = StoryService.getSampleStories();
      
      for (final story in stories) {
        expect(story.minAge, lessThanOrEqualTo(story.maxAge));
        expect(story.minAge, greaterThanOrEqualTo(3));
        expect(story.maxAge, lessThanOrEqualTo(10));
      }
    });
  });

  group('ProfileService Tests', () {
    test('should return sample profiles', () {
      final profiles = ProfileService.getSampleProfiles();
      
      expect(profiles, isNotEmpty);
      expect(profiles.length, equals(2));
      
      // Test first profile properties
      final firstProfile = profiles.first;
      expect(firstProfile.id, isNotEmpty);
      expect(firstProfile.userId, isNotEmpty);
      expect(firstProfile.childName, isNotEmpty);
      expect(firstProfile.ageBucket, isA<int>());
      expect(firstProfile.createdAt, isA<DateTime>());
    });

    test('should have valid age buckets', () {
      final profiles = ProfileService.getSampleProfiles();
      
      for (final profile in profiles) {
        expect(profile.ageBucket, greaterThanOrEqualTo(3));
        expect(profile.ageBucket, lessThanOrEqualTo(10));
      }
    });
  });

  group('AudioPlayerService Tests', () {
    late AudioPlayerService audioPlayerService;

    setUp(() {
      audioPlayerService = AudioPlayerService();
    });

    test('should initialize with stopped state', () {
      expect(audioPlayerService.playerState, equals(PlayerState.stopped));
      expect(audioPlayerService.duration, equals(Duration.zero));
      expect(audioPlayerService.position, equals(Duration.zero));
      expect(audioPlayerService.currentUrl, isNull);
      expect(audioPlayerService.isParentVoice, isFalse);
      expect(audioPlayerService.isRepeatMode, isFalse);
      expect(audioPlayerService.sleepTimerMinutes, isNull);
    });

    test('should have position stream', () {
      expect(audioPlayerService.positionStream, isA<Stream<Duration>>());
    });

    test('should have duration stream', () {
      expect(audioPlayerService.durationStream, isA<Stream<Duration>>());
    });

    test('should have player state stream', () {
      expect(audioPlayerService.playerStateStream, isA<Stream<PlayerState>>());
    });
  });

  group('SubscriptionService Tests', () {
    late SubscriptionService subscriptionService;

    setUp(() {
      subscriptionService = SubscriptionService();
    });

    test('should initialize with not initialized state', () {
      expect(subscriptionService.isInitialized, isFalse);
      expect(subscriptionService.customerInfo, isNull);
      expect(subscriptionService.availablePackages, isEmpty);
      expect(subscriptionService.isPremiumActive, isFalse);
    });

    test('should return premium features list', () {
      final features = subscriptionService.getPremiumFeatures();
      
      expect(features, isNotEmpty);
      expect(features, contains('Unlimited Stories'));
      expect(features, contains('Voice Cloning'));
      expect(features, contains('Offline Downloads'));
      expect(features, contains('Premium Categories'));
      expect(features, contains('Ad-Free Experience'));
      expect(features, contains('Priority Support'));
    });

    test('should return subscription benefits', () {
      final benefits = subscriptionService.getSubscriptionBenefits();
      
      expect(benefits, isNotEmpty);
      expect(benefits.length, equals(6));
    });

    test('should return free user limits', () {
      final limits = subscriptionService.getFreeUserLimits();
      
      expect(limits, isNotEmpty);
      expect(limits['stories_per_day'], equals(3));
      expect(limits['voice_cloning_attempts'], equals(1));
      expect(limits['offline_downloads'], equals(0));
      expect(limits['premium_categories'], equals(0));
    });

    test('should check feature availability', () {
      // Test free features
      expect(subscriptionService.isFeatureAvailable('basic_stories'), isTrue);
      
      // Test premium features (should be false when not premium)
      expect(subscriptionService.isFeatureAvailable('unlimited_stories'), isFalse);
      expect(subscriptionService.isFeatureAvailable('voice_cloning'), isFalse);
      expect(subscriptionService.isFeatureAvailable('offline_download'), isFalse);
      expect(subscriptionService.isFeatureAvailable('premium_categories'), isFalse);
    });

    test('should return subscription status', () {
      final status = subscriptionService.getSubscriptionStatus();
      expect(status, equals('Not initialized'));
    });
  });

  group('Story Model Tests', () {
    test('should create story from JSON', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Story',
        'body': 'Test story body',
        'category': 'Test Category',
        'min_age': 3,
        'max_age': 6,
        'audio_default_url': 'https://example.com/audio.mp3',
        'duration_minutes': 5,
        'thumbnail_url': 'https://example.com/thumb.jpg',
        'created_at': '2023-01-01T00:00:00Z',
      };

      final story = Story.fromJson(json);

      expect(story.id, equals('test-id'));
      expect(story.title, equals('Test Story'));
      expect(story.body, equals('Test story body'));
      expect(story.category, equals('Test Category'));
      expect(story.minAge, equals(3));
      expect(story.maxAge, equals(6));
      expect(story.audioDefaultUrl, equals('https://example.com/audio.mp3'));
      expect(story.durationMinutes, equals(5));
      expect(story.thumbnailUrl, equals('https://example.com/thumb.jpg'));
      expect(story.createdAt, isA<DateTime>());
    });

    test('should handle missing optional fields', () {
      final json = {
        'id': 'test-id',
        'title': 'Test Story',
        'body': 'Test story body',
        'category': 'Test Category',
        'min_age': 3,
        'max_age': 6,
        'audio_default_url': 'https://example.com/audio.mp3',
        'created_at': '2023-01-01T00:00:00Z',
      };

      final story = Story.fromJson(json);

      expect(story.durationMinutes, equals(5)); // Default value
      expect(story.thumbnailUrl, isNull);
    });
  });

  group('ChildProfile Model Tests', () {
    test('should create child profile from JSON', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'child_name': 'Test Child',
        'age_bucket': 5,
        'avatar_url': 'https://example.com/avatar.jpg',
        'nickname': 'Testy',
        'created_at': '2023-01-01T00:00:00Z',
        'updated_at': '2023-01-01T00:00:00Z',
      };

      final profile = ChildProfile.fromJson(json);

      expect(profile.id, equals('test-id'));
      expect(profile.userId, equals('user-123'));
      expect(profile.childName, equals('Test Child'));
      expect(profile.ageBucket, equals(5));
      expect(profile.avatarUrl, equals('https://example.com/avatar.jpg'));
      expect(profile.nickname, equals('Testy'));
      expect(profile.createdAt, isA<DateTime>());
    });

    test('should convert to JSON', () {
      final profile = ChildProfile(
        id: 'test-id',
        userId: 'user-123',
        childName: 'Test Child',
        ageBucket: 5,
        avatarUrl: 'https://example.com/avatar.jpg',
        nickname: 'Testy',
        createdAt: DateTime.parse('2023-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2023-01-01T00:00:00Z'),
      );

      final json = profile.toJson();

      expect(json['id'], equals('test-id'));
      expect(json['user_id'], equals('user-123'));
      expect(json['child_name'], equals('Test Child'));
      expect(json['age_bucket'], equals(5));
      expect(json['avatar_url'], equals('https://example.com/avatar.jpg'));
      expect(json['nickname'], equals('Testy'));
      expect(json['created_at'], equals('2023-01-01T00:00:00.000Z'));
    });

    test('should handle missing optional fields', () {
      final json = {
        'id': 'test-id',
        'user_id': 'user-123',
        'child_name': 'Test Child',
        'age_bucket': 5,
        'created_at': '2023-01-01T00:00:00Z',
      };

      final profile = ChildProfile.fromJson(json);

      expect(profile.avatarUrl, isNull);
      expect(profile.nickname, isNull);
    });
  });
}
