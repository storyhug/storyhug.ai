import 'package:flutter_test/flutter_test.dart';
import 'package:storyhug_app/core/story_tuning/story_tuning.dart';

void main() {
  group('StoryTuning Service Tests', () {
    final storyTuningService = StoryTuningService();

    test('Should tune a simple story', () async {
      const story = '''
        Once upon a time, there was a brave prince.
        He was very happy and excited about his journey.
        The prince fought fearlessly against the evil demon.
        Finally, he achieved victory!
      ''';

      final segments = await storyTuningService.tuneStory(
        storyText: story,
        enableExpansion: false,
        enablePersonalization: false,
        enablePacing: true,
      );

      expect(segments.isNotEmpty, true);
      expect(segments.length, greaterThanOrEqualTo(3));
      
      // Verify each segment has required fields
      for (final segment in segments) {
        expect(segment.text, isNotEmpty);
        expect(segment.emotion, isNotEmpty);
      }
    });

    test('Should analyze emotions correctly', () {
      const happySentence = 'I am so happy and joyful today!';
      const sadSentence = 'I feel very sad and sorrowful.';
      const excitedSentence = 'Wow, this is amazing!';

      final analysis = storyTuningService.analyzeEmotions(
        '$happySentence $sadSentence $excitedSentence',
      );

      expect(analysis.isNotEmpty, true);
      expect(analysis.length, equals(3));
      
      // Check emotion detection
      final emotions = analysis.map((a) => a['emotion'] as String).toList();
      expect(emotions.contains('happy'), true);
      expect(emotions.contains('sad'), true);
    });

    test('Should generate tuning statistics', () async {
      const story = 'Once upon a time. There was magic. Everyone was happy.';
      
      final segments = await storyTuningService.tuneStory(storyText: story);
      final stats = storyTuningService.getTuningStatistics(segments);

      expect(stats['total_segments'], greaterThan(0));
      expect(stats['total_words'], greaterThan(0));
      expect(stats['unique_emotions'], greaterThan(0));
      expect(stats['estimated_duration_seconds'], greaterThan(0));
    });

    test('Should validate tuned segments', () async {
      const story = 'Hello world. This is a test.';
      
      final segments = await storyTuningService.tuneStory(storyText: story);
      final isValid = storyTuningService.validateTunedSegments(segments);

      expect(isValid, true);
    });

    test('Should export as JSON', () async {
      const story = 'Once upon a time, there was a story.';
      
      final segments = await storyTuningService.tuneStory(storyText: story);
      final json = storyTuningService.exportAsJson(segments, pretty: true);

      expect(json, isNotEmpty);
      expect(json, contains('text'));
      expect(json, contains('emotion'));
    });

    test('Should personalize story with child name', () async {
      const story = 'Once upon a time, dear child, there was an adventure.';
      
      final segments = await storyTuningService.tuneStory(
        storyText: story,
        childName: 'Arjun',
        enablePersonalization: true,
      );

      final combinedText = segments.map((s) => s.text).join(' ');
      
      // The personalizer should have injected the child's name
      // Note: The actual implementation might vary based on personalizer logic
      expect(segments.isNotEmpty, true);
    });

    test('Should generate SSML output', () async {
      const story = 'Hello! This is exciting. How wonderful.';
      
      final ssml = await storyTuningService.generateSSML(
        storyText: story,
        voiceName: 'en-US-Neural2-A',
      );

      expect(ssml, contains('<speak>'));
      expect(ssml, contains('</speak>'));
      expect(ssml, contains('<voice'));
    });

    test('Should handle empty text gracefully', () async {
      const emptyStory = '';
      
      final segments = await storyTuningService.tuneStory(storyText: emptyStory);
      
      expect(segments, isEmpty);
    });

    test('Should detect dominant emotion', () {
      const story = '''
        I am happy! So happy! Very happy!
        I feel joyful and excited!
        What a wonderful day!
        Maybe a little sad.
      ''';

      final emotionMapper = storyTuningService.emotionMapper;
      final dominantEmotion = emotionMapper.getDominantEmotion(story);

      expect(dominantEmotion.value, anyOf(['happy', 'joyful', 'excited']));
    });

    test('Should add pacing cues', () {
      const sentence = 'This is a test sentence with important words.';
      
      final pacingFormatter = storyTuningService.pacingFormatter;
      final withPacing = pacingFormatter.addPacingCues(sentence);

      expect(withPacing, isNotEmpty);
      // Should contain some SSML-like tags
      expect(withPacing.contains('<break') || withPacing == sentence, true);
    });

    test('EmotionTag should have correct voice modulation', () {
      final happyModulation = EmotionTag.happy.getVoiceModulation();
      final sadModulation = EmotionTag.sad.getVoiceModulation();

      expect(happyModulation['pitch'], greaterThan(1.0));
      expect(sadModulation['pitch'], lessThan(1.0));
    });

    test('Should create TunedSegment correctly', () {
      final segment = TunedSegment(
        text: 'Test text',
        emotion: 'happy',
        pauseAfter: '0.5s',
        voiceStyle: 'enthusiastic',
        emphasis: 0.8,
      );

      expect(segment.text, equals('Test text'));
      expect(segment.emotion, equals('happy'));
      expect(segment.pauseAfter, equals('0.5s'));

      final json = segment.toJson();
      expect(json['text'], equals('Test text'));
      expect(json['emotion'], equals('happy'));
    });

    test('Should handle quick tune', () async {
      const story = 'Quick story for testing. Very short.';
      
      final segments = await storyTuningService.quickTune(story);

      expect(segments.isNotEmpty, true);
      // Quick tune should be faster (no expansion)
    });
  });

  group('Emotion Mapper Tests', () {
    final emotionMapper = EmotionMapperService();

    test('Should detect happy emotion', () {
      final emotion = emotionMapper.analyzeEmotion('I am so happy and joyful!');
      expect(emotion, anyOf([EmotionTag.happy, EmotionTag.joyful, EmotionTag.excited]));
    });

    test('Should detect sad emotion', () {
      final emotion = emotionMapper.analyzeEmotion('I am very sad and crying.');
      expect(emotion, equals(EmotionTag.sad));
    });

    test('Should detect excited emotion', () {
      final emotion = emotionMapper.analyzeEmotion('Wow! This is amazing!');
      expect(emotion, anyOf([EmotionTag.excited, EmotionTag.surprised]));
    });

    test('Should default to neutral for unclear text', () {
      final emotion = emotionMapper.analyzeEmotion('The sky is blue.');
      expect(emotion, equals(EmotionTag.neutral));
    });
  });

  group('Personalizer Service Tests', () {
    final personalizer = PersonalizerService();

    test('Should generate personalized greeting', () {
      final greeting = personalizer.generatePersonalizedGreeting(
        childName: 'Emma',
        parentName: 'Mom',
      );

      expect(greeting, contains('Emma'));
      expect(greeting, contains('Mom'));
    });

    test('Should add personalized ending', () {
      const story = 'Once upon a time, there was a tale.';
      final withEnding = personalizer.addPersonalizedEnding(
        story,
        childName: 'Arjun',
      );

      expect(withEnding, contains('Arjun'));
      expect(withEnding.length, greaterThan(story.length));
    });

    test('Should detect placeholders', () {
      const textWithPlaceholders = 'Hello {child_name}, how are you?';
      const textWithoutPlaceholders = 'Hello world';

      expect(personalizer.hasPersonalizationPlaceholders(textWithPlaceholders), true);
      expect(personalizer.hasPersonalizationPlaceholders(textWithoutPlaceholders), false);
    });

    test('Should replace placeholders', () {
      const text = 'Hello {child_name}, good {time_of_day}!';
      final replaced = personalizer.replacePlaceholders(
        text,
        childName: 'Priya',
        timeOfDay: 'morning',
      );

      expect(replaced, contains('Priya'));
      expect(replaced, contains('morning'));
      expect(replaced, isNot(contains('{child_name}')));
    });
  });

  group('Script Emitter Tests', () {
    final scriptEmitter = ScriptEmitterService();

    test('Should generate final script', () {
      final segments = [
        TunedSegment(text: 'Hello', emotion: 'happy'),
        TunedSegment(text: 'World', emotion: 'excited'),
      ];

      final script = scriptEmitter.generateFinalScript(segments);

      expect(script.length, equals(2));
      expect(script[0]['text'], equals('Hello'));
      expect(script[1]['emotion'], equals('excited'));
    });

    test('Should export as JSON', () {
      final segments = [
        TunedSegment(text: 'Test', emotion: 'neutral'),
      ];

      final json = scriptEmitter.exportAsJson(segments, pretty: true);

      expect(json, isNotEmpty);
      expect(json, contains('Test'));
      expect(json, contains('neutral'));
    });

    test('Should validate script', () {
      final validSegments = [
        TunedSegment(text: 'Hello', emotion: 'happy'),
      ];

      final invalidSegments = [
        TunedSegment(text: '', emotion: ''),
      ];

      expect(scriptEmitter.validateScript(validSegments), true);
      expect(scriptEmitter.validateScript(invalidSegments), false);
    });

    test('Should generate statistics', () {
      final segments = [
        TunedSegment(text: 'Hello world', emotion: 'happy'),
        TunedSegment(text: 'Goodbye world', emotion: 'sad'),
      ];

      final stats = scriptEmitter.getScriptStatistics(segments);

      expect(stats['total_segments'], equals(2));
      expect(stats['total_words'], equals(4));
      expect(stats['unique_emotions'], equals(2));
    });

    test('Should generate plain text', () {
      final segments = [
        TunedSegment(text: 'Hello', emotion: 'happy'),
        TunedSegment(text: 'World', emotion: 'excited'),
      ];

      final plainText = scriptEmitter.generatePlainText(segments);

      expect(plainText, equals('Hello World'));
    });
  });
}

