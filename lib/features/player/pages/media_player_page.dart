import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async'; // Added for StreamSubscription
import '../services/audio_player_service.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_voice.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../voice_cloning/services/voice_cloning_service.dart';

class MediaPlayerPage extends StatefulWidget {
  final Story story;
  
  const MediaPlayerPage({super.key, required this.story});

  @override
  State<MediaPlayerPage> createState() => _MediaPlayerPageState();
}

class _MediaPlayerPageState extends State<MediaPlayerPage> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _selectedVoiceId; // Changed from bool _isParentVoice
  bool _isRepeatMode = false;
  int? _sleepTimerMinutes;
  bool _isLoading = false;
  List<UserVoice> _userVoices = [];
  bool _isLoadingVoices = true;
  double _volume = 0.8; // Add volume state

  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupAudioPlayer();
    _loadUserVoices();
  }

  @override
  void dispose() {
    _cleanupListeners();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _cleanupListeners() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _durationSubscription = null;
    _positionSubscription = null;
    _playerStateSubscription = null;
  }

  void _setupAudioPlayer() {
    // Clean up existing listeners first
    _cleanupListeners();
    
    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });
  }

  Future<void> _loadUserVoices() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final voices = await _voiceCloningService.getUserVoices(userId);
        print('🎤 Loaded ${voices.length} custom voices for user $userId');
        if (mounted) {
          setState(() {
            _userVoices = voices;
            _isLoadingVoices = false;
            // NO automatic voice selection - user must select manually
            print('✅ Voices loaded. User must select a voice manually.');
          });
        }
      }
    } catch (e) {
      print('❌ Error loading user voices: $e');
      if (mounted) {
        setState(() {
          _isLoadingVoices = false;
          // NO fallback to default voice
          print('✅ No automatic voice selection on error.');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.story.title,
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _audioPlayer.stop();
            context.go('/home');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                // Story Illustration
                _buildStoryIllustration(),
                const SizedBox(height: 32),
                // Story Title
                Text(
                  widget.story.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Story Category and Duration
                Text(
                  '${widget.story.category} • ${widget.story.durationMinutes} min',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 48),
                // Progress Bar
                _buildProgressBar(),
                const SizedBox(height: 32),
                // Voice Selection
                _buildVoiceSelection(),
                _buildVoiceStatusMessage(),
                const SizedBox(height: 32),
                // Control Buttons
                _buildControlButtons(),
                const SizedBox(height: 24),
                // Additional Controls
                _buildAdditionalControls(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryIllustration() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: widget.story.thumbnailUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.story.thumbnailUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.book,
                    size: 80,
                    color: Colors.white,
                  );
                },
              ),
            )
          : const Icon(
              Icons.book,
              size: 80,
              color: Colors.white,
            ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        // Time display
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Progress slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.accentColor,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: AppTheme.accentColor,
            overlayColor: AppTheme.accentColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _duration.inMilliseconds > 0
                ? _position.inMilliseconds.toDouble()
                : 0.0,
            max: _duration.inMilliseconds > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
            onChanged: (value) {
              _audioPlayer.seek(Duration(milliseconds: value.toInt()));
            },
          ),
        ),
      ],
    );
  }

  /// Format duration to MM:SS format
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildTimeDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(_position),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        Text(
          _formatDuration(_duration),
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSelection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.record_voice_over,
            color: Colors.white70,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'Voice: ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: _isLoadingVoices
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2,
                    ),
                  )
                : DropdownButton<String>(
                    value: _selectedVoiceId,
                    dropdownColor: AppTheme.surfaceColor,
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text(
                      'Select Voice',
                      style: TextStyle(color: Colors.white70),
                    ),
                    items: [
                      // Default AI voices
                      ..._voiceCloningService.getDefaultVoices().map((voice) => DropdownMenuItem(
                        value: voice['id'],
                        child: Row(
                          children: [
                            const Icon(
                              Icons.smart_toy,
                              color: Colors.blue,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                voice['name']!,
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                      // User's recorded voices
                      ..._userVoices.map((voice) => DropdownMenuItem(
                        value: voice.voiceId,
                        child: Row(
                          children: [
                            Icon(
                              voice.isDefault ? Icons.star : Icons.person,
                              color: voice.isDefault ? Colors.amber : Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                voice.voiceName,
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (voice.isDefault)
                              const Text(
                                ' (Default)',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedVoiceId = value;
                      });
                    },
                  ),
          ),
          const SizedBox(width: 8),
          // Refresh button to reload voices
          IconButton(
            onPressed: _loadUserVoices,
            icon: const Icon(
              Icons.refresh,
              color: Colors.white70,
              size: 20,
            ),
            tooltip: 'Refresh Voices',
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceStatusMessage() {
    // Show prompt when no voice is selected
    if (_selectedVoiceId == null && !_isLoadingVoices) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _userVoices.isEmpty 
                    ? 'Please select an AI voice or record your own voice in Voice Cloning'
                    : 'Please select a voice to continue',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    if (_userVoices.isNotEmpty && _selectedVoiceId != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Voice selected • ${_userVoices.length} custom voice${_userVoices.length == 1 ? '' : 's'} available',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Skip Backward
        IconButton(
          onPressed: _skipBackward,
          icon: const Icon(
            Icons.replay_10,
            color: Colors.white,
            size: 32,
          ),
        ),
        // Play/Pause Button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IconButton(
            onPressed: _isLoading ? null : _togglePlayPause,
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    _playerState == PlayerState.playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
            iconSize: 48,
          ),
        ),
        // Skip Forward
        IconButton(
          onPressed: _skipForward,
          icon: const Icon(
            Icons.forward_10,
            color: Colors.white,
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Sleep Timer
        IconButton(
          onPressed: _toggleSleepTimer,
          icon: Icon(
            Icons.bedtime,
            color: _sleepTimerMinutes != null ? AppTheme.accentColor : Colors.white,
            size: 24,
          ),
          tooltip: 'Sleep Timer',
        ),
        // Repeat Mode
        IconButton(
          onPressed: _toggleRepeatMode,
          icon: Icon(
            Icons.repeat,
            color: _isRepeatMode ? AppTheme.accentColor : Colors.white,
            size: 24,
          ),
          tooltip: 'Repeat Mode',
        ),
        // Volume Control
        IconButton(
          onPressed: _showVolumeControl,
          icon: const Icon(
            Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
          tooltip: 'Volume Control',
        ),
      ],
    );
  }

  Future<void> _play() async {
    // Validate that a voice is selected before playing
    if (_selectedVoiceId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a voice to continue'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      
      await _audioPlayer.play(
        widget.story.audioDefaultUrl,
        isParentVoice: _selectedVoiceId != null, // Use custom voice if selected
        userId: userId,
        storyId: widget.story.id,
        selectedVoiceId: _selectedVoiceId, // Pass the selected voice ID
        story: widget.story, // Pass the story directly
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error playing audio: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pause() {
    _audioPlayer.pause();
  }

  void _resume() {
    _audioPlayer.resume();
  }

  void _togglePlayPause() {
    print('🎮 Toggle play/pause called. Current state: $_playerState');
    
    if (_playerState == PlayerState.playing) {
      print('🎮 Pausing audio...');
      _pause();
    } else if (_playerState == PlayerState.paused) {
      print('🎮 Resuming audio...');
      _resume();
    } else if (_playerState == PlayerState.stopped || _playerState == PlayerState.completed) {
      print('🎮 Starting new playback...');
      _play();
    }
  }

  void _skipBackward() {
    _audioPlayer.skipBackward();
  }

  void _skipForward() {
    _audioPlayer.skipForward();
  }

  void _toggleSleepTimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sleep Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set sleep timer to automatically stop playback'),
            const SizedBox(height: 16),
            ...([15, 30, 45, 60].map((minutes) => ListTile(
              title: Text('$minutes minutes'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sleepTimerMinutes = minutes;
                });
                _audioPlayer.setSleepTimer(minutes);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Sleep timer set for $minutes minutes'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ))),
            ListTile(
              title: const Text('Cancel Timer'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _sleepTimerMinutes = null;
                });
                _audioPlayer.cancelSleepTimer();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleRepeatMode() {
    setState(() {
      _isRepeatMode = !_isRepeatMode;
    });
    _audioPlayer.toggleRepeatMode();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isRepeatMode ? 'Repeat mode ON' : 'Repeat mode OFF'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showVolumeControl() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Volume Control'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Adjust playback volume'),
            const SizedBox(height: 16),
            Slider(
              value: _volume,
              onChanged: (value) {
                setState(() {
                  _volume = value;
                });
                _audioPlayer.setVolume(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white),
              title: const Text('Story Details', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showStoryDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share Story', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _shareStory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.white),
              title: const Text('Download for Offline', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _downloadForOffline();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStoryDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.story.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${widget.story.category}'),
            Text('Age Range: ${widget.story.ageRange}'),
            Text('Duration: ${widget.story.durationMinutes} minutes'),
            const SizedBox(height: 16),
            const Text('Description:'),
            Text(widget.story.body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareStory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _downloadForOffline() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offline download coming soon!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
