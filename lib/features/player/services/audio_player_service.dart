import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../shared/models/story.dart';
import '../../voice_cloning/services/voice_cloning_service.dart';
import '../../voice_cloning/services/audio_strategy_service.dart';
import '../../voice_cloning/services/voice_change_event.dart';
import '../../stories/services/story_service.dart';
import '../../../core/services/supabase_service.dart';
import 'voice_generation_worker.dart';
import 'listen_cache_service.dart';

enum VoiceChangeResult { success, noActivePlayback, failed }

class AudioPlayerService {
  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;
  AudioPlayerService._internal() {
    _voiceChangeSubscription = VoiceCloningService.voiceChangeStream.listen(
      _handleVoiceChangeEvent,
    );
    _positionController.add(Duration.zero);
    _durationController.add(Duration.zero);
    _playerStateController.add(PlayerState.stopped);
  }

  AudioPlayer? _audioPlayer;
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<PlayerState> _playerStateController =
      StreamController<PlayerState>.broadcast();
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
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<VoiceChangeEvent>? _voiceChangeSubscription;

  Story? _activeStory;
  String? _activeStoryId;
  String? _activeUserId;
  String? _activeVoiceId;
  String? _activeVoiceType;
  String? _activeOriginalUrl;
  bool _activePreferBackgroundMusic = true;
  bool _isChangingVoice = false;
  bool _hasFreshPlayer = false;

  // Listen tracking
  DateTime? _playbackStartTime;
  Duration _totalListeningDuration = Duration.zero;
  bool _hasRecordedListen = false;

  // Getters
  PlayerState get playerState => _playerState;
  Duration get duration => _duration;
  Duration get position => _position;
  String? get currentUrl => _currentUrl;
  bool get isParentVoice => _isParentVoice;
  bool get isRepeatMode => _isRepeatMode;
  int? get sleepTimerMinutes => _sleepTimerMinutes;

  // Streams - broadcast from controllers to remain stable across player rebuilds
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration> get durationStream => _durationController.stream;
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  /// Get or create audio player instance
  AudioPlayer get _audioPlayerInstance {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
    }
    return _audioPlayer!;
  }

  void _setPlayerState(PlayerState state) {
    final previousState = _playerState;
    _playerState = state;
    if (!_playerStateController.isClosed) {
      _playerStateController.add(state);
    }

    // Track listening duration and record listens
    _handlePlayerStateChange(previousState, state);
  }

  void _handlePlayerStateChange(
    PlayerState previousState,
    PlayerState newState,
  ) {
    print('[LISTEN] State change: $previousState → $newState');
    print(
      '[LISTEN] Active context: storyId=$_activeStoryId, userId=$_activeUserId',
    );

    // Start tracking when playback begins
    if (newState == PlayerState.playing &&
        previousState != PlayerState.playing) {
      print('[LISTEN] ✅ Playback started - initializing tracking');
      print(
        '[LISTEN]   Context check: storyId=$_activeStoryId, userId=$_activeUserId',
      );
      _playbackStartTime = DateTime.now();
      _recordListenStart();
    }

    // Update duration when paused
    if (previousState == PlayerState.playing &&
        newState == PlayerState.paused) {
      print('[LISTEN] Paused - saving partial duration');
      _updateListeningDuration();
      _recordListenPartial();
    }

    // Update duration when stopped
    if (previousState == PlayerState.playing &&
        newState == PlayerState.stopped) {
      print('[LISTEN] Stopped - saving final duration');
      _updateListeningDuration();
      _recordListenComplete();
    }

    // Record completion when story finishes
    if (newState == PlayerState.completed) {
      print('[LISTEN] Completed - saving final duration');
      _updateListeningDuration();
      _recordListenComplete();
    }

    // Restart timer when resuming from paused
    if (newState == PlayerState.playing &&
        previousState == PlayerState.paused) {
      print('[LISTEN] Resuming from pause - restarting timer');
      _playbackStartTime = DateTime.now();
    }
  }

  void _updateListeningDuration() {
    if (_playbackStartTime != null) {
      final elapsed = DateTime.now().difference(_playbackStartTime!);
      _totalListeningDuration += elapsed;
      print(
        '[LISTEN] Update duration: +${elapsed.inSeconds}s, total=${_totalListeningDuration.inSeconds}s',
      );
      _playbackStartTime = null;
    }
  }

  Future<void> _recordListenPartial() async {
    if (_activeStoryId == null || _activeUserId == null) {
      return;
    }

    try {
      final durationSeconds = _totalListeningDuration.inSeconds;
      if (durationSeconds <= 0) return;

      print(
        '[LISTEN] Save partial: storyId=$_activeStoryId, duration=${durationSeconds}s',
      );
      await _recordListenEvent(
        storyId: _activeStoryId!,
        userId: _activeUserId!,
        listenDuration: _totalListeningDuration,
        completed: false,
      );
    } catch (e) {
      print('[LISTEN] Save partial ERROR: $e');
    }
  }

  Future<void> _recordListenStart() async {
    if (_activeStoryId == null || _activeUserId == null || _hasRecordedListen) {
      print(
        '[LISTEN] Start skipped: storyId=$_activeStoryId, userId=$_activeUserId, hasRecorded=$_hasRecordedListen',
      );
      return;
    }

    try {
      print('[LISTEN] Start: storyId=$_activeStoryId, userId=$_activeUserId');
      // Record initial listen when playback starts
      await _storyService.recordListen(_activeStoryId!);
      _hasRecordedListen = true;
      print('[LISTEN] Start saved successfully');
    } catch (e) {
      print('[LISTEN] Start ERROR: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _recordListenComplete() async {
    if (_activeStoryId == null || _activeUserId == null) {
      print(
        '[LISTEN] Complete skipped: storyId=$_activeStoryId, userId=$_activeUserId',
      );
      return;
    }

    try {
      _updateListeningDuration();
      final durationSeconds = _totalListeningDuration.inSeconds;

      if (durationSeconds <= 0) {
        print('[LISTEN] Complete skipped: duration is 0');
        return;
      }

      // Check if story was completed (90% of total duration)
      final completed =
          _duration.inSeconds > 0 &&
          (durationSeconds >= _duration.inSeconds * 0.9);

      print(
        '[LISTEN] Save final: storyId=$_activeStoryId, duration=${durationSeconds}s, completed=$completed, totalDuration=${_duration.inSeconds}s',
      );

      // Record listen with duration and completion status using direct Supabase write
      await _recordListenEvent(
        storyId: _activeStoryId!,
        userId: _activeUserId!,
        listenDuration: _totalListeningDuration,
        completed: completed,
      );

      print(
        '[LISTEN] Completed: true=$completed, duration=${durationSeconds}s',
      );

      // Reset tracking
      _totalListeningDuration = Duration.zero;
      _hasRecordedListen = false;
    } catch (e) {
      print('[LISTEN] Complete ERROR: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
    }
  }

  /// Direct Supabase write for reliable listen recording with local cache fallback
  Future<void> _recordListenEvent({
    required String storyId,
    required String userId,
    required Duration listenDuration,
    required bool completed,
  }) async {
    final listenedAt = DateTime.now().toIso8601String();

    try {
      print(
        '[LISTEN] Writing to Supabase: storyId=$storyId, userId=$userId, duration=${listenDuration.inSeconds}s, completed=$completed',
      );

      // Validate inputs
      if (storyId.isEmpty) {
        print('[LISTEN] ERROR: storyId is empty, cannot save listen');
        return;
      }

      if (userId.isEmpty) {
        print('[LISTEN] ERROR: userId is empty, cannot save listen');
        return;
      }

      // Try Supabase write first
      try {
        final response = await SupabaseService.client.from('listens').insert({
          'story_id': storyId,
          'user_id': userId,
          'duration_seconds': listenDuration.inSeconds,
          'completed': completed,
          'listened_at': listenedAt,
        }).select();

        print('[LISTEN] Supabase response: $response');
        print(
          '📌 Listen saved successfully - ID: ${response is List && response.isNotEmpty ? response[0]['id'] : 'unknown'}',
        );

        // Success - no need to cache
        return;
      } catch (supabaseError) {
        print('[LISTEN] Supabase write ERROR: $supabaseError');

        // Fallback: Cache locally for later sync
        print('[LISTEN] Caching listen locally for later sync...');
        await ListenCacheService.cacheListen(
          storyId: storyId,
          userId: userId,
          durationSeconds: listenDuration.inSeconds,
          completed: completed,
          listenedAt: listenedAt,
        );
        print('[LISTEN] ✅ Listen cached locally - will sync later');
      }
    } catch (e) {
      print('[LISTEN] ERROR in _recordListenEvent: $e');
      debugPrint('Stack trace: ${StackTrace.current}');

      // Last resort: Try to cache even if everything fails
      try {
        await ListenCacheService.cacheListen(
          storyId: storyId,
          userId: userId,
          durationSeconds: listenDuration.inSeconds,
          completed: completed,
          listenedAt: listenedAt,
        );
        print('[LISTEN] ✅ Listen cached as fallback');
      } catch (cacheError) {
        print('[LISTEN] ❌ Failed to cache listen: $cacheError');
      }
    }
  }

  void _emitPosition(Duration position) {
    if (!_positionController.isClosed) {
      _positionController.add(position);
    }
  }

  void _emitDuration(Duration duration) {
    if (!_durationController.isClosed) {
      _durationController.add(duration);
    }
  }

  /// Clean up existing listeners to prevent multiple subscriptions
  void _cleanupListeners() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription = null;
    _playerStateSubscription = null;
  }

  /// Set up listeners for duration and position changes
  void _setupListeners() {
    if (_audioPlayer == null) {
      return;
    }

    _cleanupListeners(); // Clean up any existing listeners first

    _durationSubscription = _audioPlayer!.onDurationChanged.listen((duration) {
      _duration = duration;
      _emitDuration(duration);
    });

    _positionSubscription = _audioPlayer!.onPositionChanged.listen((position) {
      _position = position;
      _emitPosition(position);
    });

    // Listen for completion to record finished listens
    _audioPlayer!.onPlayerComplete.listen((_) {
      print('🎵 Playback completed');
      _recordListenComplete();
      _setPlayerState(PlayerState.completed);
    });
  }

  Future<void> _prepareNewAudioPlayer() async {
    _cleanupListeners();
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.dispose();
      } catch (e) {
        print('⚠️ Error disposing audio player during prepare: $e');
      }
    }
    _audioPlayer = AudioPlayer();
    _hasFreshPlayer = true;
    _setupListeners();
  }

  Future<String> _resolveCachePath({
    required String storyId,
    required String voiceId,
    required String userId,
    required bool preferBackgroundMusic,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final audioDir = Directory(p.join(tempDir.path, 'personalized_audio'));
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    final variant = preferBackgroundMusic ? 'bgm' : 'voice';
    final fileName = 'story_${storyId}_${userId}_${voiceId}_$variant.mp3';
    return p.join(audioDir.path, fileName);
  }

  Future<bool> _waitForLocalFile(
    String path, {
    int attempts = 20,
    Duration delay = const Duration(milliseconds: 200),
  }) async {
    final file = File(path);
    for (var i = 0; i < attempts; i++) {
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          print('✅ Local audio ready ($length bytes): $path');
          return true;
        }
      }
      await Future.delayed(delay);
    }
    print(
      '❌ Local audio still missing after ${attempts * delay.inMilliseconds}ms: $path',
    );
    return false;
  }

  Future<void> _stopCurrentPlayback({bool release = false}) async {
    // Record listen before stopping
    if (_playerState == PlayerState.playing ||
        _playerState == PlayerState.paused) {
      _recordListenComplete();
    }

    _cleanupListeners();
    if (_audioPlayer != null) {
      try {
        print('[VOICE] Stop playback');
        await _audioPlayer!.stop();
        await _audioPlayer!.seek(Duration.zero);
      } catch (e) {
        print('⚠️ Error stopping playback: $e');
      }
      if (release) {
        try {
          await _audioPlayer!.release();
        } catch (e) {
          print('⚠️ Error releasing audio resources: $e');
        }
        try {
          await _audioPlayer!.dispose();
        } catch (e) {
          print('⚠️ Error disposing audio player: $e');
        }
        _audioPlayer = null;
      }
    }
    _setPlayerState(PlayerState.stopped);
    _position = Duration.zero;
    _duration = Duration.zero;
    _emitPosition(_position);
    _emitDuration(_duration);
    _currentUrl = null;
    _hasFreshPlayer = false;
  }

  Future<String> _generatePersonalizedAudioForActiveContext() async {
    if (_activeStory == null ||
        _activeUserId == null ||
        _activeVoiceId == null) {
      throw Exception('Missing context for personalized audio generation');
    }

    final story = _activeStory!;
    final userId = _activeUserId!;
    final voiceId = _activeVoiceId!;
    final preferBgm = _activePreferBackgroundMusic;
    final cachePath = await _resolveCachePath(
      storyId: story.id,
      voiceId: voiceId,
      userId: userId,
      preferBackgroundMusic: preferBgm,
    );

    final cachedFile = File(cachePath);
    if (await cachedFile.exists() && await cachedFile.length() > 0) {
      print('[VOICE] Using cached audio for story ${story.id} voice $voiceId');
      return cachePath;
    }

    print('[VOICE] Regenerating story for voice: $voiceId');
    final params = VoiceGenerationParams(
      storyJson: story.toJson(),
      voiceId: voiceId,
      outputPath: cachePath,
      userId: userId,
      storyId: story.id,
      preferBackgroundMusic: preferBgm,
    );

    final generatedPath = await compute(voiceGenerationWorker, params.toJson());
    print('[VOICE] Generated audio saved to: $generatedPath');
    return generatedPath;
  }

  Future<void> _startPlaybackWithUrl(
    String audioUrl, {
    required bool isParentVoice,
  }) async {
    final playbackStart = DateTime.now();
    print('[VOICE] Starting new playback for: $audioUrl');

    final isRemoteSource = audioUrl.startsWith('http');

    if (!isRemoteSource) {
      final ready = await _waitForLocalFile(audioUrl);
      if (!ready) {
        throw Exception('Generated audio not available at $audioUrl');
      }
    }

    if (_audioPlayer == null) {
      await _prepareNewAudioPlayer();
    } else {
      if (!_hasFreshPlayer) {
        try {
          await _audioPlayer!.stop();
        } catch (_) {}
      }
      _setupListeners();
    }

    _playerStateSubscription?.cancel();
    _playerStateSubscription = _audioPlayer!.onPlayerStateChanged.listen((
      state,
    ) {
      print('[VOICE] Player state changed → $state');
      _setPlayerState(state);
    });

    final source = isRemoteSource
        ? UrlSource(audioUrl)
        : DeviceFileSource(audioUrl);

    await _audioPlayer!.play(source);
    print('[VOICE] play() invoked successfully');

    // Wait for playback to start automatically
    final playingFuture = _audioPlayer!.onPlayerStateChanged
        .firstWhere((state) => state == PlayerState.playing)
        .timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            print('⚠️ Auto-start timeout — will force resume');
            return PlayerState.stopped;
          },
        );

    try {
      final state = await playingFuture;
      if (state == PlayerState.playing) {
        print('[VOICE] ✅ Playback started automatically');
      }
    } catch (e) {
      print('[VOICE] ⚠️ Waiting for playback: $e');
    }

    // Force resume if not playing after timeout
    if (_playerState != PlayerState.playing) {
      print('⚠️ Auto-start failed — forcing resume()');
      await _audioPlayer!.resume();
      _setPlayerState(PlayerState.playing);
    }

    _currentUrl = audioUrl;
    _isParentVoice = isParentVoice;
    _hasFreshPlayer = false;

    // Reset listen tracking for new playback
    _totalListeningDuration = Duration.zero;
    _hasRecordedListen = false;

    final elapsed = DateTime.now().difference(playbackStart);
    print('[VOICE] Playback start latency: ${elapsed.inMilliseconds}ms');
  }

  Future<void> _handleVoiceChangeEvent(VoiceChangeEvent event) async {
    print(
      '🔁 Voice change event received: user=${event.userId}, voice=${event.voiceId}',
    );
    if (_activeUserId == null || event.userId != _activeUserId) {
      return;
    }

    await handleVoiceChange(
      newVoiceId: event.voiceId,
      story: _activeStory,
      storyId: _activeStoryId,
      userId: _activeUserId,
      voiceType: _activeVoiceType,
      isParentVoice: true,
      preferBackgroundMusic: _activePreferBackgroundMusic,
    );
  }

  void _resetActiveContext() {
    print('[LISTEN] _resetActiveContext called');
    print('[LISTEN]   Current state: $_playerState');
    print(
      '[LISTEN]   Current context: storyId=$_activeStoryId, userId=$_activeUserId',
    );

    // Record listen before resetting if we were playing
    if (_playerState == PlayerState.playing ||
        _playerState == PlayerState.paused) {
      print('[LISTEN] Recording final listen before reset');
      _recordListenComplete();
    }

    _activeStory = null;
    _activeStoryId = null;
    _activeUserId = null;
    _activeVoiceId = null;
    _activeVoiceType = null;
    _activeOriginalUrl = null;
    _activePreferBackgroundMusic = true;
    _playbackStartTime = null;
    _totalListeningDuration = Duration.zero;
    _hasRecordedListen = false;

    print('[LISTEN] Context reset complete');
  }

  Future<void> play(
    String url, {
    bool isParentVoice = false,
    String? userId,
    String? storyId,
    String? selectedVoiceId,
    Story? story,
    String? voiceType,
  }) async {
    try {
      print('🎵 Starting to play audio: $url');
      print('🎵 Current player state: $_playerState');
      print(
        '🎵 Play params: userId=$userId, storyId=$storyId, story=${story?.id}',
      );

      // Set active context FIRST before any state changes
      bool isTextOnlyStory =
          url.isEmpty || url == 'null' || !url.startsWith('http');

      if (story != null) {
        _activeStory = story;
        _activeStoryId = story.id;
        print('🎵 Set activeStoryId from story: ${story.id}');
      } else if (storyId != null) {
        _activeStoryId = storyId;
        print('🎵 Set activeStoryId from storyId param: $storyId');
      }

      _activeOriginalUrl = url;
      _activeUserId = userId;
      _activeVoiceType = voiceType;
      _activePreferBackgroundMusic = !isTextOnlyStory;

      print(
        '🎵 Active context set: storyId=$_activeStoryId, userId=$_activeUserId',
      );

      // Only ensure clean state if we're switching to a different URL or if no player exists
      if (_currentUrl != url || _audioPlayer == null) {
        await _ensureCleanState();
      }

      _currentUrl = url;
      _isParentVoice = isParentVoice;

      // Reset tracking flags for new playback (but keep storyId/userId)
      _totalListeningDuration = Duration.zero;
      _hasRecordedListen = false;

      String audioUrl = url;

      // For text-only stories or when parent voice is selected, generate custom audio
      if ((isTextOnlyStory || isParentVoice) &&
          userId != null &&
          storyId != null) {
        try {
          // Handle different voice types
          String? voiceId = selectedVoiceId;

          if (voiceType == 'ai_male') {
            voiceId = 'MV2lIGFO3SleI2bwL8Cp';
          } else if (voiceType == 'ai_female') {
            voiceId = 'wlmwDR77ptH6bKHZui0l';
          } else if (voiceType == 'custom' && selectedVoiceId != null) {
            voiceId = selectedVoiceId;
          } else if (voiceType == 'default') {
            voiceId = await _voiceCloningService.getVoiceId(userId);
          } else if (voiceId == null) {
            voiceId = await _voiceCloningService.getVoiceId(userId);
          }

          _activeVoiceId = voiceId ?? _activeVoiceId;

          if (voiceId != null) {
            Story? storyToUse = story;
            if (storyToUse == null) {
              try {
                storyToUse = await _storyService.getStoryById(storyId);
              } catch (e) {
                try {
                  storyToUse = await _storyService.getRamayanaStoryByNumber(
                    int.parse(storyId),
                  );
                } catch (e2) {
                  print('Failed to fetch story by ID or number: $e2');
                }
              }
            }

            if (storyToUse != null) {
              final generatedAudioPath = await _audioStrategyService
                  .generatePersonalizedAudio(
                    story: storyToUse,
                    userId: userId,
                    voiceId: voiceId,
                    preferBackgroundMusic: !isTextOnlyStory,
                  );
              audioUrl = generatedAudioPath;
              _activeStory = storyToUse;
              _activeStoryId = storyToUse.id;
              _activeUserId = userId;
              _activeVoiceId = voiceId;
              _activeVoiceType = voiceType;
              _activeOriginalUrl = url;
              _activePreferBackgroundMusic = !isTextOnlyStory;
              _isParentVoice = true;
            }
          }
        } catch (e) {
          print('Failed to generate custom audio: $e');
          throw Exception('Failed to generate audio for story: $e');
        }
      } else if (story != null && userId != null) {
        _activeStory = story;
        _activeStoryId = story.id;
        _activeUserId = userId;
        _activePreferBackgroundMusic = !isTextOnlyStory;
      }

      print('🎵 Final audio URL: $audioUrl');

      try {
        await _startPlaybackWithUrl(audioUrl, isParentVoice: _isParentVoice);
      } catch (playError) {
        print('❌ Audio play failed: $playError');
        await _stopCurrentPlayback();
        _resetActiveContext();
        throw Exception('Failed to start audio playback: $playError');
      }
    } catch (e) {
      print('❌ Play method failed: $e');
      await _stopCurrentPlayback();
      _resetActiveContext();
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
      _emitPosition(_position);
      _emitDuration(_duration);

      // Clear reference so a fresh instance can be created later
      _audioPlayer = null;

      print('✅ Audio player state cleaned');
    } catch (e) {
      print('❌ Error cleaning audio player state: $e');
      // Force reset state even if cleanup fails
      _setPlayerState(PlayerState.stopped);
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentUrl = null;
      _emitPosition(_position);
      _emitDuration(_duration);
      _cleanupListeners();
      // Clear reference even if cleanup failed
      _audioPlayer = null;
    }
    _hasFreshPlayer = false;
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
        // Restart duration timer when resuming
        _playbackStartTime = DateTime.now();
        print('[LISTEN] Resumed - restarting timer');
        _setPlayerState(PlayerState.playing);
      }
    } catch (e) {
      throw Exception('Failed to resume audio: $e');
    }
  }

  Future<void> stop() async {
    try {
      print('🛑 Stopping audio player...');

      // Record listen before stopping
      if (_playerState == PlayerState.playing ||
          _playerState == PlayerState.paused) {
        _recordListenComplete();
      }

      // Clean up listeners first
      _cleanupListeners();

      // Stop the audio player
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }

      // Reset all state
      _setPlayerState(PlayerState.stopped);
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentUrl = null;
      _playbackStartTime = null;
      _totalListeningDuration = Duration.zero;
      _hasRecordedListen = false;
      _emitPosition(_position);
      _emitDuration(_duration);

      print('✅ Audio player stopped successfully');
    } catch (e) {
      print('❌ Error stopping audio: $e');
      // Even if stop fails, clean up our state
      _setPlayerState(PlayerState.stopped);
      _position = Duration.zero;
      _duration = Duration.zero;
      _currentUrl = null;
      _emitPosition(_position);
      _emitDuration(_duration);
      _cleanupListeners();
    }
  }

  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer!.seek(position);
      _position = position;
      _emitPosition(position);
    } catch (e) {
      throw Exception('Failed to seek audio: $e');
    }
  }

  Future<void> skipForward({
    Duration duration = const Duration(seconds: 10),
  }) async {
    final newPosition = _position + duration;
    if (newPosition > _duration) {
      await seek(_duration);
    } else {
      await seek(newPosition);
    }
  }

  Future<void> skipBackward({
    Duration duration = const Duration(seconds: 10),
  }) async {
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
    await _voiceChangeSubscription?.cancel();
    await _audioPlayer?.dispose();
    if (!_positionController.isClosed) {
      await _positionController.close();
    }
    if (!_durationController.isClosed) {
      await _durationController.close();
    }
    if (!_playerStateController.isClosed) {
      await _playerStateController.close();
    }
  }

  Stream<VoiceChangeEvent> subscribeToVoiceChanges() {
    return VoiceCloningService.voiceChangeStream;
  }

  Future<VoiceChangeResult> handleVoiceChange({
    required String newVoiceId,
    String? voiceType,
    String? userId,
    Story? story,
    String? storyId,
    bool isParentVoice = true,
    bool preferBackgroundMusic = true,
  }) async {
    if (_isChangingVoice) {
      print('ℹ️ Voice change already in progress. Ignoring new request.');
      return VoiceChangeResult.noActivePlayback;
    }

    final hasActivePlayback =
        _playerState == PlayerState.playing || _currentUrl != null;

    if (!hasActivePlayback && story == null && storyId == null) {
      _activeVoiceId = newVoiceId;
      if (voiceType != null) {
        _activeVoiceType = voiceType;
      }
      if (userId != null) {
        _activeUserId = userId;
      }
      return VoiceChangeResult.noActivePlayback;
    }

    _isChangingVoice = true;
    final previousVoiceId = _activeVoiceId;
    final previousVoiceType = _activeVoiceType;
    final previousParentFlag = _isParentVoice;

    try {
      _activeVoiceId = newVoiceId;
      if (voiceType != null) {
        _activeVoiceType = voiceType;
      }
      if (userId != null) {
        _activeUserId = userId;
      }
      _isParentVoice = isParentVoice;
      _activePreferBackgroundMusic = preferBackgroundMusic;

      if (story != null) {
        _activeStory = story;
        _activeStoryId = story.id;
      } else if (storyId != null) {
        _activeStoryId = storyId;
      }

      if (_activeStory == null && _activeStoryId != null) {
        try {
          _activeStory = await _storyService.getStoryById(_activeStoryId!);
        } catch (e) {
          print('⚠️ Unable to fetch story $_activeStoryId: $e');
        }
      }

      if (_activeStory == null ||
          _activeUserId == null ||
          _activeVoiceId == null) {
        print('⚠️ Missing context for voice change.');
        return VoiceChangeResult.noActivePlayback;
      }

      _activeOriginalUrl ??= _currentUrl ?? _activeStory!.audioDefaultUrl;

      final regenStopwatch = Stopwatch()..start();
      final regenerationFuture = _generatePersonalizedAudioForActiveContext();

      await _stopCurrentPlayback(release: true);
      await Future.delayed(const Duration(milliseconds: 150));
      await _prepareNewAudioPlayer();

      print('[VOICE] Waiting for regenerated audio...');
      final regeneratedUrl = await regenerationFuture;
      print('[VOICE] Regenerated URL: $regeneratedUrl');

      await _startPlaybackWithUrl(regeneratedUrl, isParentVoice: true);

      await _audioPlayer?.seek(Duration.zero);
      _position = Duration.zero;
      _emitPosition(_position);

      // Ensure playback is actually playing after voice change
      // Wait a bit for the player to settle
      await Future.delayed(const Duration(milliseconds: 300));

      if (_playerState != PlayerState.playing) {
        print(
          '[VOICE] ⚠️ Player not playing after voice change, forcing resume',
        );
        await _audioPlayer?.resume();
        _setPlayerState(PlayerState.playing);
      } else {
        print('[VOICE] ✅ Playback resumed automatically with new voice');
      }

      final elapsed = regenStopwatch.elapsed;
      print(
        '[VOICE] Regeneration + playback latency: ${elapsed.inMilliseconds}ms',
      );

      return VoiceChangeResult.success;
    } catch (e) {
      print('❌ Voice change failed: $e');
      _activeVoiceId = previousVoiceId;
      _activeVoiceType = previousVoiceType;
      _isParentVoice = previousParentFlag;
      return VoiceChangeResult.failed;
    } finally {
      _isChangingVoice = false;
    }
  }

  Future<VoiceChangeResult> changeVoiceDuringPlayback({
    required String voiceId,
    String? voiceType,
    String? userId,
    Story? story,
    String? storyId,
    bool isParentVoice = true,
    bool preferBackgroundMusic = true,
  }) {
    return handleVoiceChange(
      newVoiceId: voiceId,
      voiceType: voiceType,
      userId: userId,
      story: story,
      storyId: storyId,
      isParentVoice: isParentVoice,
      preferBackgroundMusic: preferBackgroundMusic,
    );
  }
}
