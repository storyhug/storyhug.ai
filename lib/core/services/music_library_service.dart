import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

/// Service to manage royalty-free ambient background music
class MusicLibraryService {
  static final MusicLibraryService _instance = MusicLibraryService._internal();
  factory MusicLibraryService() => _instance;
  MusicLibraryService._internal();

  AudioPlayer? _bgmPlayer;
  double _volume = 0.3; // Default background music volume (30%)

  /// Available ambient music categories
  static const Map<String, Map<String, String>> musicLibrary = {
    'night': {
      'display_name': 'Peaceful Night',
      'description': 'Soft lullaby tones for bedtime',
      'asset_path': 'assets/audio/ambient_night.mp3',
      'mood': 'bedtime',
    },
    'forest': {
      'display_name': 'Enchanted Forest',
      'description': 'Nature sounds and gentle melodies',
      'asset_path': 'assets/audio/ambient_forest.mp3',
      'mood': 'adventure',
    },
    'ocean': {
      'display_name': 'Ocean Waves',
      'description': 'Calming ocean sounds',
      'asset_path': 'assets/audio/ambient_ocean.mp3',
      'mood': 'bedtime',
    },
    'space': {
      'display_name': 'Cosmic Journey',
      'description': 'Ethereal space ambience',
      'asset_path': 'assets/audio/ambient_space.mp3',
      'mood': 'adventure',
    },
    'calm': {
      'display_name': 'Gentle Piano',
      'description': 'Soft piano for learning',
      'asset_path': 'assets/audio/ambient_calm.mp3',
      'mood': 'learning',
    },
  };

  /// Get music for a specific category
  String? getMusicForCategory(String category) {
    final music = musicLibrary[category];
    return music?['asset_path'];
  }

  /// Get music for a mood preset
  String? getMusicForMood(String mood) {
    for (final entry in musicLibrary.entries) {
      if (entry.value['mood'] == mood) {
        return entry.value['asset_path'];
      }
    }
    return null;
  }

  /// Play background music
  Future<void> playBackgroundMusic({
    required String category,
    double? volume,
    bool loop = true,
  }) async {
    try {
      final music = musicLibrary[category];
      if (music == null) {
        print('Music category not found: $category');
        return;
      }

      // Initialize player if needed
      _bgmPlayer ??= AudioPlayer();

      // Set volume
      final effectiveVolume = volume ?? _volume;
      await _bgmPlayer!.setVolume(effectiveVolume);

      // Set loop mode
      await _bgmPlayer!.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);

      // Play from assets
      final assetPath = music['asset_path']!;
      await _bgmPlayer!.play(AssetSource(assetPath.replaceFirst('assets/', '')));

      print('🎵 Playing background music: ${music['display_name']}');
    } catch (e) {
      print('Error playing background music: $e');
    }
  }

  /// Stop background music
  Future<void> stopBackgroundMusic() async {
    try {
      await _bgmPlayer?.stop();
    } catch (e) {
      print('Error stopping background music: $e');
    }
  }

  /// Pause background music
  Future<void> pauseBackgroundMusic() async {
    try {
      await _bgmPlayer?.pause();
    } catch (e) {
      print('Error pausing background music: $e');
    }
  }

  /// Resume background music
  Future<void> resumeBackgroundMusic() async {
    try {
      await _bgmPlayer?.resume();
    } catch (e) {
      print('Error resuming background music: $e');
    }
  }

  /// Set background music volume (0.0 - 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _bgmPlayer?.setVolume(_volume);
    } catch (e) {
      print('Error setting volume: $e');
    }
  }

  /// Get current volume
  double getVolume() => _volume;

  /// Fade in background music
  Future<void> fadeIn({
    required String category,
    int durationMillis = 3000,
  }) async {
    await playBackgroundMusic(category: category, volume: 0.0);
    
    final steps = 30;
    final stepDuration = durationMillis ~/ steps;
    final volumeIncrement = _volume / steps;

    for (int i = 0; i <= steps; i++) {
      await _bgmPlayer?.setVolume(volumeIncrement * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }
  }

  /// Fade out background music
  Future<void> fadeOut({int durationMillis = 3000}) async {
    final currentVolume = _volume;
    final steps = 30;
    final stepDuration = durationMillis ~/ steps;
    final volumeDecrement = currentVolume / steps;

    for (int i = steps; i >= 0; i--) {
      await _bgmPlayer?.setVolume(volumeDecrement * i);
      await Future.delayed(Duration(milliseconds: stepDuration));
    }

    await stopBackgroundMusic();
  }

  /// Get all available music categories
  List<Map<String, String>> getAllMusic() {
    return musicLibrary.entries.map((entry) {
      return {
        'id': entry.key,
        ...entry.value,
      };
    }).toList();
  }

  /// Get music info
  Map<String, dynamic>? getMusicInfo(String category) {
    final music = musicLibrary[category];
    if (music == null) return null;

    return {
      'id': category,
      ...music,
    };
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stopBackgroundMusic();
    await _bgmPlayer?.dispose();
    _bgmPlayer = null;
  }

  /// Mix background music with narration (adjusts volumes)
  Future<void> mixWithNarration({
    required String category,
    double narrationVolume = 1.0,
    double musicVolume = 0.2,
  }) async {
    await playBackgroundMusic(
      category: category,
      volume: musicVolume,
    );
  }

  /// Auto-select music based on story metadata
  String? autoSelectMusic({
    String? mood,
    String? category,
    int? childAge,
  }) {
    // Priority 1: Mood-based selection
    if (mood != null) {
      return getMusicForMood(mood);
    }

    // Priority 2: Category-based selection
    if (category != null) {
      if (category.toLowerCase().contains('myth')) {
        return getMusicForCategory('space');
      } else if (category.toLowerCase().contains('fairy')) {
        return getMusicForCategory('forest');
      } else if (category.toLowerCase().contains('moral')) {
        return getMusicForCategory('calm');
      }
    }

    // Priority 3: Age-based selection
    if (childAge != null) {
      if (childAge <= 5) {
        return getMusicForCategory('night'); // Calmer for younger kids
      } else {
        return getMusicForCategory('forest'); // More engaging for older kids
      }
    }

    // Default fallback
    return getMusicForCategory('calm');
  }
}

