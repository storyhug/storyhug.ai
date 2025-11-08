import 'package:flutter/material.dart';
import '../story_tuning_service.dart';
import '../models/tuned_segment.dart';

/// Example demonstrating how to use the StoryTuning Service
class StoryTuningExample {
  final _storyTuningService = StoryTuningService();

  /// Example 1: Basic story tuning
  Future<void> basicTuningExample() async {
    const sampleStory = '''
      Once upon a time, in a magical forest, there lived a brave prince named Rama.
      He was known for his wisdom and courage.
      One day, a terrible demon threatened the kingdom.
      Rama quickly gathered his allies and prepared for battle.
      After a long fight, he finally defeated the demon!
      The kingdom celebrated with joy and happiness.
    ''';

    print('=== Basic Tuning Example ===');
    
    final segments = await _storyTuningService.tuneStory(
      storyText: sampleStory,
      enableExpansion: true,
      enablePacing: true,
      enablePersonalization: false,
    );

    print('Generated ${segments.length} tuned segments:');
    for (final segment in segments) {
      print('- ${segment.emotion}: ${segment.text}');
    }
  }

  /// Example 2: Personalized story tuning
  Future<void> personalizedTuningExample() async {
    const sampleStory = '''
      Once upon a time, dear child, there was a wonderful adventure waiting.
      The brave hero discovered a hidden treasure.
      With the help of mother, the hero learned valuable lessons.
    ''';

    print('\n=== Personalized Tuning Example ===');
    
    final segments = await _storyTuningService.tuneStory(
      storyText: sampleStory,
      childName: 'Arjun',
      parentName: 'Mom',
      enablePersonalization: true,
      enableExpansion: true,
      enablePacing: true,
    );

    print('Personalized story with ${segments.length} segments');
    for (final segment in segments) {
      print('- [${segment.emotion}] ${segment.text}');
    }
  }

  /// Example 3: Generate TTS script
  Future<void> generateTTSScriptExample() async {
    const sampleStory = '''
      The sun rose over the mountains.
      Birds began to sing their morning songs.
      A new adventure was about to begin!
    ''';

    print('\n=== TTS Script Generation Example ===');
    
    // Generate for ElevenLabs
    final elevenLabsScript = await _storyTuningService.generateTTSScript(
      storyText: sampleStory,
      engine: 'elevenlabs',
      voiceId: 'test-voice-id',
    );

    print('ElevenLabs Script:');
    print(elevenLabsScript);

    // Generate SSML
    final ssml = await _storyTuningService.generateSSML(
      storyText: sampleStory,
      voiceName: 'en-US-Neural2-A',
    );

    print('\nSSML Output:');
    print(ssml);
  }

  /// Example 4: Emotion analysis only
  void emotionAnalysisExample() {
    const sampleStory = '''
      I am so happy today!
      Yesterday was quite sad.
      But now I feel excited about the future.
      Life is mysterious and wonderful.
    ''';

    print('\n=== Emotion Analysis Example ===');
    
    final analysis = _storyTuningService.analyzeEmotions(sampleStory);
    
    print('Emotion analysis:');
    for (final item in analysis) {
      print('- "${item['sentence']}": ${item['emotion']}');
    }
  }

  /// Example 5: Get tuning statistics
  Future<void> tuningStatisticsExample() async {
    const sampleStory = '''
      In the beginning, there was darkness.
      Then came the light, bright and warm.
      The world awakened with joy and wonder.
      Nature sang its eternal song.
      Peace filled every corner of existence.
    ''';

    print('\n=== Tuning Statistics Example ===');
    
    final segments = await _storyTuningService.tuneStory(
      storyText: sampleStory,
      enableExpansion: true,
    );

    final stats = _storyTuningService.getTuningStatistics(segments);
    
    print('Statistics:');
    print('- Total segments: ${stats['total_segments']}');
    print('- Total words: ${stats['total_words']}');
    print('- Unique emotions: ${stats['unique_emotions']}');
    print('- Emotion list: ${stats['emotion_list']}');
    print('- Estimated duration: ${stats['estimated_duration_minutes']} minutes');
    print('- Average words per segment: ${stats['average_words_per_segment']}');
  }

  /// Example 6: Full story with complete script
  Future<void> fullStoryScriptExample() async {
    const sampleStory = '''
      Once upon a time, in a far away kingdom, there lived a wise king.
      The king had a beautiful daughter who loved to explore the gardens.
      One mysterious night, she discovered a secret door in the old temple.
      Behind the door was a magical world filled with wonder!
      She gasped in surprise at the incredible sight.
      The princess knew this would be an adventure to remember.
    ''';

    print('\n=== Full Story Script Example ===');
    
    final script = await _storyTuningService.tuneStoryWithScript(
      storyId: 'sample-story-001',
      storyTitle: 'The Princess and the Secret Door',
      storyText: sampleStory,
      childName: 'Priya',
      voiceId: 'custom-voice-123',
      enableExpansion: true,
      enablePersonalization: true,
      enablePacing: true,
    );

    print('Complete Script:');
    print('Story ID: ${script['story_id']}');
    print('Story Title: ${script['story_title']}');
    print('Total Segments: ${script['total_segments']}');
    print('Estimated Duration: ${script['estimated_duration_seconds']}s');
    print('Emotion Distribution: ${script['emotion_distribution']}');
    print('\nSegments:');
    
    final segments = script['segments'] as List;
    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      print('${i + 1}. [${seg['emotion']}] ${seg['text']}');
      if (seg['pause_after'] != null) {
        print('   → Pause: ${seg['pause_after']}');
      }
    }
  }

  /// Run all examples
  Future<void> runAllExamples() async {
    await basicTuningExample();
    await personalizedTuningExample();
    await generateTTSScriptExample();
    emotionAnalysisExample();
    await tuningStatisticsExample();
    await fullStoryScriptExample();
    
    print('\n✅ All examples completed successfully!');
  }
}

/// Widget demonstrating StoryTuning integration in UI
class StoryTuningDemoWidget extends StatefulWidget {
  const StoryTuningDemoWidget({Key? key}) : super(key: key);

  @override
  State<StoryTuningDemoWidget> createState() => _StoryTuningDemoWidgetState();
}

class _StoryTuningDemoWidgetState extends State<StoryTuningDemoWidget> {
  final _storyTuningService = StoryTuningService();
  final _textController = TextEditingController();
  List<TunedSegment> _tunedSegments = [];
  bool _isProcessing = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _processStory() async {
    if (_textController.text.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final segments = await _storyTuningService.tuneStory(
        storyText: _textController.text,
        childName: 'Demo Child',
        enableExpansion: true,
        enablePersonalization: true,
        enablePacing: true,
      );

      setState(() => _tunedSegments = segments);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Processed ${segments.length} segments'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Tuning Demo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Enter Story Text',
                border: OutlineInputBorder(),
                hintText: 'Type your story here...',
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isProcessing ? null : _processStory,
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : const Text('Process Story'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tuned Segments:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _tunedSegments.length,
                itemBuilder: (context, index) {
                  final segment = _tunedSegments[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                      ),
                      title: Text(segment.text),
                      subtitle: Text(
                        'Emotion: ${segment.emotion} | Pause: ${segment.pauseAfter}',
                      ),
                      trailing: Icon(_getEmotionIcon(segment.emotion)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion) {
      case 'happy':
      case 'joyful':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'excited':
        return Icons.celebration;
      case 'calm':
        return Icons.self_improvement;
      case 'fearful':
        return Icons.warning;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'surprised':
        return Icons.lightbulb;
      default:
        return Icons.sentiment_neutral;
    }
  }
}

