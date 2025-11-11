import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import '../../../config/environment.dart';
import '../../../shared/models/story.dart';
import '../../voice_cloning/services/story_emotion_mapper.dart';

/// Parameters passed to the background isolate for voice regeneration.
class VoiceGenerationParams {
  VoiceGenerationParams({
    required this.storyJson,
    required this.voiceId,
    required this.outputPath,
    required this.userId,
    required this.storyId,
    required this.preferBackgroundMusic,
  });

  final Map<String, dynamic> storyJson;
  final String voiceId;
  final String outputPath;
  final String userId;
  final String storyId;
  final bool preferBackgroundMusic;

  Map<String, dynamic> toJson() {
    return {
      'storyJson': storyJson,
      'voiceId': voiceId,
      'outputPath': outputPath,
      'userId': userId,
      'storyId': storyId,
      'preferBackgroundMusic': preferBackgroundMusic,
    };
  }

  factory VoiceGenerationParams.fromJson(Map<String, dynamic> json) {
    return VoiceGenerationParams(
      storyJson: Map<String, dynamic>.from(json['storyJson'] as Map),
      voiceId: json['voiceId'] as String,
      outputPath: json['outputPath'] as String,
      userId: json['userId'] as String,
      storyId: json['storyId'] as String,
      preferBackgroundMusic: json['preferBackgroundMusic'] as bool,
    );
  }
}

/// Entry point used by `compute` – accepts a serialisable map.
Future<String> voiceGenerationWorker(Map<String, dynamic> rawParams) async {
  final params = VoiceGenerationParams.fromJson(rawParams);

  final story = Story.fromJson(params.storyJson);
  final emotionMapper = StoryEmotionMapper();
  final preset = emotionMapper.mapStory(story);

  final payload = <String, dynamic>{
    'text': story.body,
    'model_id': 'eleven_multilingual_v2',
    'voice_settings': preset.toVoiceSettings(),
    'emotion': preset.emotion,
    'emotional_tone': preset.emotion,
    'optimize_streaming_latency': 3,
    'output_format': 'mp3_44100_128',
  };

  final request = http.Request(
    'POST',
    Uri.parse(
      '${Environment.elevenLabsBaseUrl}/text-to-speech/${params.voiceId}',
    ),
  );
  request.headers['xi-api-key'] = Environment.elevenLabsApiKey;
  request.headers['Content-Type'] = 'application/json';
  request.body = json.encode(payload);

  final client = http.Client();
  final outputFile = File(params.outputPath);

  try {
    final response = await client.send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      throw Exception(
        'Voice generation failed: ${response.statusCode} - $errorBody',
      );
    }

    await outputFile.parent.create(recursive: true);

    // Write audio stream incrementally to disk.
    final sink = outputFile.openWrite();
    await response.stream.pipe(sink);
    await sink.flush();
    await sink.close();

    // Touch file timestamp for caching heuristics.
    await outputFile.setLastModified(DateTime.now());
    return outputFile.path;
  } finally {
    client.close();
  }
}
