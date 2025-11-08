import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../../../shared/models/story.dart';
import '../../voice_cloning/services/voice_cloning_service.dart';
import '../../voice_cloning/services/audio_strategy_service.dart';
import '../../stories/services/story_service.dart';

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal();

  AudioPlayer? _audioPlayer;
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  final AudioStrategyService _audioStrategyService = AudioStrategyService();
  final StoryService _storyService = StoryService();
  
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _currentUrl;
  bool _isParentVoice = false;
  bool _isRepeatMode = false;
  int? _sleepTimerMinutes;
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  // Getters
  PlayerState get playerState => _playerState;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentUrl => _currentUrl;
  bool get isParentVoice => _isParentVoice;
  bool get isRepeatMode => _isRepeatMode;
  int? get sleepTimerMinutes => _sleepTimerMinutes;

  // Streams - create new streams for each audio player instance
  Stream<Duration> get positionStream => _audioPlayer?.onPositionChanged ?? Stream.value(Duration.zero);
  Stream<Duration> get durationStream => _audioPlayer?.onDurationChanged ?? Stream.value(Duration.zero);
  Stream<PlayerState> get playerStateStream => _audioPlayer?.onPlayerStateChanged ?? Stream.value(PlayerState.stopped);

  /// Get or create audio player instance
  AudioPlayer get _audioPlayerInstance {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
    }
    return _audioPlayer!;
  }

  void _setPlayerState(PlayerState state) {
    _playerState = state;
  }

  /// Clean up existing listeners to prevent multiple subscriptions
  void _cleanupListeners() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription = null;
  }

  /// Set up listeners for duration and position changes
  void _setupListeners() {
    _cleanupListeners(); // Clean up any existing listeners first
    
    if (_audioPlayer != null) {
      _durationSubscription = _audioPlayer!.onDurationChanged.listen((duration) {
        _duration = duration;
      });
      
      _positionSubscription = _audioPlayer!.onPositionChanged.listen((position) {
        _position = position;
      });
    }
  }

  Future<void> play(String url, {bool isParentVoice = false, String? userId, String? storyId, String? selectedVoiceId, Story? story, String? voiceType}) async {
    try {
      print('🎵 Starting to play audio: $url');
      print('🎵 Current player state: $_playerState');
      
      // Only ensure clean state if we're switching to a different URL or if no player exists
      if (_currentUrl != url || _audioPlayer == null) {
        await _ensureCleanState();
      }
      
      _currentUrl = url;
      _isParentVoice = isParentVoice;
      
      String audioUrl = url;
      
      // Check if this is a text-only story (empty or invalid URL)
      bool isTextOnlyStory = url.isEmpty || url == 'null' || !url.startsWith('http');
      
      // For text-only stories or when parent voice is selected, generate custom audio
      if ((isTextOnlyStory || isParentVoice) && userId != null && storyId != null) {
        try {
          // Handle different voice types
          String? voiceId = selectedVoiceId;
          
          if (voiceType == 'ai_male') {
            // Use a predefined AI male voice ID
            voiceId = 'MV2lIGFO3SleI2bwL8Cp'; // ElevenLabs AI male voice
          } else if (voiceType == 'ai_female') {
            // Use a predefined AI female voice ID
            voiceId = 'wlmwDR77ptH6bKHZui0l'; // ElevenLabs AI female voice
          } else if (voiceType == 'custom' && selectedVoiceId != null) {
            // Use the selected custom voice
            voiceId = selectedVoiceId;
          } else if (voiceType == 'default') {
            // Use default voice or get user's default voice
            voiceId = await _voiceCloningService.getVoiceId(userId);
          } else if (voiceId == null) {
            // Fallback to default voice
            voiceId = await _voiceCloningService.getVoiceId(userId);
          }
          
          if (voiceId != null) {
            // Use the story passed directly, or fetch it if not provided
            Story? storyToUse = story;
            if (storyToUse == null) {
              try {
                // First try to get by ID (for regular stories)
                storyToUse = await _storyService.getStoryById(storyId);
              } catch (e) {
                try {
                  // If that fails, try to get by number (for Ramayana stories)
                  storyToUse = await _storyService.getRamayanaStoryByNumber(int.parse(storyId));
                } catch (e2) {
                  print('Failed to fetch story by ID or number: $e2');
                }
              }
            }
            
            if (storyToUse != null) {
              // Use comprehensive strategy service
              final generatedAudioPath = await _audioStrategyService.generatePersonalizedAudio(
                story: storyToUse,
                userId: userId,
                voiceId: voiceId,
                preferBackgroundMusic: !isTextOnlyStory, // Only prefer BGM if not text-only
              );
              audioUrl = generatedAudioPath;
            }
          }
        } catch (e) {
          print('Failed to generate custom audio: $e');
          throw Exception('Failed to generate audio for story: $e');
        }
      } else if (isTextOnlyStory) {
        // If it's a text-only story and no voice is selected, throw an error
        throw Exception('This is a text-only story. Please select a voice to generate audio.');
      }
      
      print('🎵 Final audio URL: $audioUrl');
      
      // Play the audio with error handling
      try {
        print('🎵 Playing audio URL: $audioUrl');
        
        // Set up listeners before playing
        _setupListeners();
        
        await _audioPlayer!.play(UrlSource(audioUrl));
        _setPlayerState(PlayerState.playing);
        
        print('✅ Audio playback started successfully');
        
        // Wait a bit for duration to be available
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Force duration update if still zero
        if (_duration == Duration.zero) {
          // Duration will be updated via the stream listener
          print('🎵 Waiting for duration from stream...');
        }
        
      } catch (playError) {
        print('❌ Audio play failed: $playError');
        await _ensureCleanState();
        throw Exception('Failed to start audio playback: $playError');
      }
      
    } catch (e) {
      print('❌ Play method failed: $e');
      await _ensureCleanState();
      throw Exception('Failed to play audio: $e');
    }
  }

  /// Ensure the audio player is in a clean state
  Future<void> _ensureCleanState() async {
    try {
      print('🧹 Ensuring clean audio player state...');
      
      // Clean up listeners first
      _cleanupListeners();
      
      // Dispose current audio player if it exists
      if (_audioPlayer != null) {
        print('🛑 Disposing current audio player...');
        await _audioPlayer!.dispose();
        _audioPlayer = null;
      }
      
      // Reset all state
      _setPlayerState(PlayerState.stopped);
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentUrl = null;
      
      // Create new audio player instance
      _audioPlayer = AudioPlayer();
      
      // Small delay to ensure audio player is ready
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('✅ Audio player state cleaned and new instance created');
    } catch (e) {
      print('❌ Error cleaning audio player state: $e');
      // Force reset state even if cleanup fails
      _setPlayerState(PlayerState.stopped);
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentUrl = null;
      _cleanupListeners();
      // Create new instance even if cleanup failed
      _audioPlayer = AudioPlayer();
    }
  }

  Future<void> pause() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
        _setPlayerState(PlayerState.paused);
      }
    } catch (e) {
      throw Exception('Failed to pause audio: $e');
    }
  }

  Future<void> resume() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.resume();
        _setPlayerState(PlayerState.playing);
      }
    } catch (e) {
      throw Exception('Failed to resume audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      print('🛑 Stopping audio player...');
      
      // Clean up listeners first
      _cleanupListeners();
      
      // Stop the audio player
      await _audioPlayer!.stop();
      
      // Reset all state
      _setPlayerState(PlayerState.stopped);
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentUrl = null;
      
      print('✅ Audio player stopped successfully');
    } catch (e) {
      print('❌ Error stopping audio: $e');
      // Even if stop fails, clean up our state
      _setPlayerState(PlayerState.stopped);
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentUrl = null;
      _cleanupListeners();
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer!.seek(position);
      _position = position;
    } catch (e) {
      throw Exception('Failed to seek audio: $e');
    }
  }

  Future<void> skipForward({Duration duration = const Duration(seconds: 10)}) async {
    final newPosition = _position + duration;
    if (newPosition > _duration) {
      await seek(_duration);
    } else {
      await seek(newPosition);
    }
  }

  Future<void> skipBackward({Duration duration = const Duration(seconds: 10)}) async {
    final newPosition = _position - duration;
    if (newPosition.isNegative) {
      await seek(Duration.zero);
    } else {
      await seek(newPosition);
    }
  }

  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer?.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      throw Exception('Failed to set volume: $e');
    }
  }

  void toggleRepeatMode() {
    _isRepeatMode = !_isRepeatMode;
  }

  void setSleepTimer(int? minutes) {
    _sleepTimerMinutes = minutes;
    if (minutes != null) {
      // Start sleep timer
      Future.delayed(Duration(minutes: minutes), () {
        if (_sleepTimerMinutes == minutes) {
          print('⏰ Sleep timer triggered - stopping audio');
          stop();
          _sleepTimerMinutes = null;
        }
      });
    }
  }

  void cancelSleepTimer() {
    _sleepTimerMinutes = null;
  }

  Future<void> dispose() async {
    _cleanupListeners();
    await _audioPlayer?.dispose();
  }
}
