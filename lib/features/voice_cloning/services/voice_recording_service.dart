import 'dart:io';
import 'dart:async';
import 'package:record/record.dart';
import 'voice_cloning_service.dart';

class VoiceRecordingService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  
  bool _isRecording = false;
  String? _currentRecordingPath;
  Duration _recordingDuration = Duration.zero;
  Timer? _recordingTimer;
  Timer? _autoStopTimer;
  StreamSubscription<Duration>? _durationSubscription;

  bool get isRecording => _isRecording;
  String? get currentRecordingPath => _currentRecordingPath;
  Duration get recordingDuration => _recordingDuration;
  bool get isAutoStopTimerActive => _autoStopTimer?.isActive ?? false;

  /// Start voice recording
  Future<bool> startRecording() async {
    try {
      print('🎤 VoiceRecordingService: Starting recording...');
      
      // Reset any previous state first
      resetRecordingState();
      
      // Check microphone permission
      if (!await _voiceCloningService.checkMicrophonePermission()) {
        print('⚠️ Microphone permission not granted, requesting...');
        final granted = await _voiceCloningService.requestMicrophonePermission();
        if (!granted) {
          throw Exception('Microphone permission is required for voice recording');
        }
        print('✅ Microphone permission granted');
      } else {
        print('✅ Microphone permission already granted');
      }

      // Get temporary file path
      final filePath = await _voiceCloningService.getTemporaryFilePath();
      print('📁 Recording file path: $filePath');
      
      // Get optimal recording settings
      final settings = _voiceCloningService.getOptimalRecordingSettings();
      print('⚙️ Recording settings: $settings');
      
      // Start recording
      print('🎙️ Starting audio recorder...');
      await _audioRecorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav,
          bitRate: settings['bitRate'] as int,
          sampleRate: settings['sampleRate'] as int,
          numChannels: settings['channels'] as int,
        ),
        path: filePath,
      );

      // Only set recording state if start was successful
      _isRecording = true;
      _currentRecordingPath = filePath;
      _recordingDuration = Duration.zero;
      
      print('🎤 Recording state set to: $_isRecording');
      
      // Start duration tracking
      _startDurationTracking();
      
      // Auto-stop after maximum duration
      _autoStopTimer = Timer(Duration(seconds: settings['duration'] as int), () async {
        if (_isRecording) {
          print('⏰ Auto-stopping recording after ${settings['duration']} seconds');
          try {
            // Direct auto-stop without going through stopRecording() method
            await _performAutoStop();
            print('✅ Auto-stop completed successfully');
          } catch (e) {
            print('❌ Auto-stop failed: $e');
            // Force reset state if auto-stop fails
            resetRecordingState();
          }
        }
      });
      
      print('✅ Recording started successfully');
      return true;
    } catch (e) {
      print('❌ Recording start failed: $e');
      resetRecordingState(); // Ensure clean state on failure
      throw Exception('Failed to start recording: $e');
    }
  }

  /// Check if recording is actually active
  Future<bool> checkRecordingStatus() async {
    try {
      // Check if we have a recording state and the recorder is active
      return _isRecording && await _audioRecorder.isRecording();
    } catch (e) {
      print('❌ Error checking recording state: $e');
      return false;
    }
  }

  /// Stop voice recording
  Future<String?> stopRecording() async {
    try {
      print('🛑 VoiceRecordingService: Stopping recording...');
      print('📊 Current recording state: $_isRecording');
      
      // Check if we're actually recording
      final isActuallyRecording = await checkRecordingStatus();
      print('🎙️ Actually recording: $isActuallyRecording');
      
      if (!_isRecording && !isActuallyRecording) {
        print('⚠️ No active recording to stop');
        throw Exception('No active recording to stop');
      }

      // Stop duration tracking
      _stopDurationTracking();
      
      // Cancel auto-stop timer
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      print('📹 Calling audioRecorder.stop()...');
      final recordingPath = await _audioRecorder.stop();
      _isRecording = false;
      
      if (recordingPath != null) {
        _currentRecordingPath = recordingPath;
        print('✅ Recording stopped successfully: $recordingPath');
        return recordingPath;
      } else {
        print('❌ Failed to get recording path');
        throw Exception('Failed to get recording path');
      }
    } catch (e) {
      print('❌ Stop recording failed: $e');
      _isRecording = false;
      _stopDurationTracking();
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      throw Exception('Failed to stop recording: $e');
    }
  }

  /// Perform auto-stop without going through stopRecording() method
  Future<void> _performAutoStop() async {
    try {
      print('🛑 Performing auto-stop...');
      
      // Stop duration tracking
      _stopDurationTracking();
      
      // Cancel auto-stop timer
      _autoStopTimer?.cancel();
      _autoStopTimer = null;

      // Stop the audio recorder directly
      print('📹 Calling audioRecorder.stop() for auto-stop...');
      final recordingPath = await _audioRecorder.stop();
      
      // Update state
      _isRecording = false;
      
      if (recordingPath != null) {
        _currentRecordingPath = recordingPath;
        print('✅ Auto-stop successful: $recordingPath');
      } else {
        print('❌ Auto-stop failed to get recording path');
        throw Exception('Failed to get recording path during auto-stop');
      }
    } catch (e) {
      print('❌ Auto-stop failed: $e');
      // Force reset state
      _isRecording = false;
      _stopDurationTracking();
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      throw e;
    }
  }

  /// Cancel current recording
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
      }
      
      // Stop duration tracking
      _stopDurationTracking();
      
      // Cancel auto-stop timer
      _autoStopTimer?.cancel();
      _autoStopTimer = null;
      
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        _currentRecordingPath = null;
      }
    } catch (e) {
      // Ignore errors during cancellation
    }
  }

  /// Get recording duration
  Future<Duration> getRecordingDuration() async {
    return _recordingDuration;
  }

  /// Start duration tracking
  void _startDurationTracking() {
    // Simple timer-based duration tracking
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _recordingDuration = Duration(seconds: timer.tick);
    });
  }

  /// Stop duration tracking
  void _stopDurationTracking() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  /// Check if recording is valid for voice cloning
  Future<bool> isRecordingValid() async {
    try {
      if (_currentRecordingPath == null) return false;
      
      final file = File(_currentRecordingPath!);
      if (!await file.exists()) return false;
      
      // Check file size (more lenient requirements)
      final fileSize = await file.length();
      if (fileSize < 10000) return false; // At least 10KB
      
      // Check duration (at least 5 seconds)
      if (_recordingDuration.inSeconds < 5) return false;
      
      // Basic validation - if file exists and has reasonable size, it's probably valid
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Process recorded audio for voice cloning
  Future<String> processRecording(String userId) async {
    try {
      if (_currentRecordingPath == null) {
        throw Exception('No recording to process');
      }

      final audioFile = File(_currentRecordingPath!);
      
      // Validate recording quality
      final isValid = await isRecordingValid();
      if (!isValid) {
        throw Exception('Recording quality is not suitable for voice cloning');
      }

      // Clone voice using ElevenLabs
      final voiceModelUrl = await _voiceCloningService.cloneVoice(audioFile, userId, 'Default Voice');
      
      // Save voice model URL
      await _voiceCloningService.saveVoiceModelUrl(userId, voiceModelUrl);
      
      return voiceModelUrl;
    } catch (e) {
      throw Exception('Failed to process recording: $e');
    }
  }

  /// Get recording instructions
  List<String> getRecordingInstructions() {
    return _voiceCloningService.getRecordingInstructions();
  }

  /// Get sample text for recording
  String getSampleRecordingText() {
    return _voiceCloningService.getSampleRecordingText();
  }

  /// Check if user has a cloned voice
  Future<bool> hasClonedVoice(String userId) async {
    return await _voiceCloningService.hasClonedVoice(userId);
  }

  /// Get voice model URL for user
  Future<String?> getVoiceModelUrl(String userId) async {
    return await _voiceCloningService.getVoiceModelUrl(userId);
  }

  /// Delete voice model
  Future<void> deleteVoiceModel(String userId) async {
    await _voiceCloningService.deleteVoiceModel(userId);
  }

  /// Get current recording path
  Future<String?> getCurrentRecordingPath() async {
    return _currentRecordingPath;
  }

  /// Generate story audio with cloned voice
  Future<String> generateStoryAudio(String storyText, String userId) async {
    try {
      final voiceModelUrl = await getVoiceModelUrl(userId);
      if (voiceModelUrl == null) {
        throw Exception('No voice model found for user');
      }
      
      return await _voiceCloningService.generateStoryAudio(storyText, voiceModelUrl);
    } catch (e) {
      throw Exception('Failed to generate story audio: $e');
    }
  }

  /// Reset recording state (useful for debugging)
  void resetRecordingState() {
    print('🔄 Resetting recording state...');
    _isRecording = false;
    _currentRecordingPath = null;
    _recordingDuration = Duration.zero;
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _durationSubscription?.cancel();
    _durationSubscription = null;
    print('✅ Recording state reset');
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      if (_isRecording) {
        await cancelRecording();
      }
      
      // Clean up timers and subscriptions
      _recordingTimer?.cancel();
      _autoStopTimer?.cancel();
      _durationSubscription?.cancel();
      
      await _audioRecorder.dispose();
    } catch (e) {
      // Ignore disposal errors
    }
  }
}
