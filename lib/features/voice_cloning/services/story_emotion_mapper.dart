import '../../../shared/models/story.dart';

class StoryEmotionPreset {
  final String emotion;
  final double stability;
  final double similarityBoost;
  final double style;
  final bool useSpeakerBoost;
  final double speakingRate;

  const StoryEmotionPreset({
    required this.emotion,
    required this.stability,
    required this.similarityBoost,
    required this.style,
    required this.useSpeakerBoost,
    required this.speakingRate,
  });

  const StoryEmotionPreset.neutralWarm()
    : emotion = 'neutral_warm',
      stability = 0.45,
      similarityBoost = 0.88,
      style = 0.55,
      useSpeakerBoost = true,
      speakingRate = 0.17;

  Map<String, dynamic> toVoiceSettings() {
    return {
      'stability': stability,
      'similarity_boost': similarityBoost,
      'style': style,
      'use_speaker_boost': useSpeakerBoost,
      'speaking_rate': speakingRate,
    };
  }
}

class StoryEmotionMapper {
  StoryEmotionPreset mapStory(Story story) {
    final category = story.category.toLowerCase();
    final title = story.title.toLowerCase();

    if (_isCalmStory(category, title)) {
      return const StoryEmotionPreset(
        emotion: 'calm',
        stability: 0.55,
        similarityBoost: 0.9,
        style: 0.35,
        useSpeakerBoost: true,
        speakingRate: 0.16,
      );
    }

    if (_isAdventureStory(category, title)) {
      return const StoryEmotionPreset(
        emotion: 'excited',
        stability: 0.38,
        similarityBoost: 0.92,
        style: 0.8,
        useSpeakerBoost: true,
        speakingRate: 0.2,
      );
    }

    if (_isJoyfulStory(category, title)) {
      return const StoryEmotionPreset(
        emotion: 'joyful',
        stability: 0.42,
        similarityBoost: 0.9,
        style: 0.7,
        useSpeakerBoost: true,
        speakingRate: 0.19,
      );
    }

    if (_isReflectiveStory(category, title)) {
      return const StoryEmotionPreset(
        emotion: 'sad',
        stability: 0.6,
        similarityBoost: 0.85,
        style: 0.3,
        useSpeakerBoost: true,
        speakingRate: 0.16,
      );
    }

    return const StoryEmotionPreset.neutralWarm();
  }

  bool _isCalmStory(String category, String title) {
    return category.contains('bedtime') ||
        category.contains('sleep') ||
        category.contains('dream') ||
        title.contains('bedtime') ||
        title.contains('dream');
  }

  bool _isAdventureStory(String category, String title) {
    return category.contains('adventure') ||
        category.contains('hero') ||
        category.contains('myth') ||
        category.contains('quest') ||
        title.contains('journey') ||
        title.contains('quest');
  }

  bool _isJoyfulStory(String category, String title) {
    return category.contains('fairy') ||
        category.contains('festival') ||
        category.contains('friendship') ||
        title.contains('happy') ||
        title.contains('smile');
  }

  bool _isReflectiveStory(String category, String title) {
    return category.contains('moral') ||
        category.contains('lesson') ||
        category.contains('reflection') ||
        title.contains('lesson') ||
        title.contains('learn');
  }
}
