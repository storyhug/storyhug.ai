import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';
import '../services/audio_player_service.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_voice.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../voice_cloning/services/voice_cloning_service.dart';

class StoryPlayerScreen extends StatefulWidget {
  final Story story;
  
  const StoryPlayerScreen({super.key, required this.story});

  @override
  State<StoryPlayerScreen> createState() => _StoryPlayerScreenState();
}

class _StoryPlayerScreenState extends State<StoryPlayerScreen> {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _selectedVoiceId;
  String? _selectedVoiceType; // null (not selected), 'ai_male', 'ai_female', 'custom'
  bool _isRepeatMode = false;
  int? _sleepTimerMinutes;
  bool _isLoading = false;
  List<UserVoice> _userVoices = [];
  bool _isLoadingVoices = true;
  double _volume = 0.8;

  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  Timer? _positionTimer;
  
  // Manual time tracking like Android approach
  Timer? _timeUpdateTimer;

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
    _positionTimer?.cancel();
    _timeUpdateTimer?.cancel();
    _durationSubscription = null;
    _positionSubscription = null;
    _playerStateSubscription = null;
    _positionTimer = null;
    _timeUpdateTimer = null;
  }

  void _setupAudioPlayer() {
    _cleanupListeners();
    
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      debugPrint('🎵 Position updated: ${position.inSeconds}s');
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      debugPrint('🎵 Duration updated: ${duration.inSeconds}s');
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      debugPrint('🎵 Player state changed: $state');
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
      
      // Start/stop time update timer based on playing state (Android approach)
      if (state == PlayerState.playing) {
        _startTimeUpdateTimer();
      } else {
        _stopTimeUpdateTimer();
      }
    });
  }

  // Android-style time update using Timer.periodic (like Handler.postDelayed)
  void _startTimeUpdateTimer() {
    _stopTimeUpdateTimer();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _playerState == PlayerState.playing) {
        // Update position every second like Android
        setState(() {
          // This will trigger a rebuild and update the time display
          // The actual position will come from the stream
        });
      }
    });
  }

  void _stopTimeUpdateTimer() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = null;
  }

  Future<void> _loadUserVoices() async {
    try {
      setState(() {
        _isLoadingVoices = true;
      });
      
      final userId = SupabaseService.client.auth.currentUser?.id;
      debugPrint('📢 Loading voices for user: $userId');
      
      if (userId != null) {
        final voices = await _voiceCloningService.getUserVoices(userId);
        debugPrint('📢 Loaded ${voices.length} voices: ${voices.map((v) => v.voiceName).toList()}');
        
        // Debug: Print detailed voice info
        for (var voice in voices) {
          debugPrint('📢 Voice: ${voice.voiceName} | ID: ${voice.voiceId} | Default: ${voice.isDefault} | Active: ${voice.isActive}');
        }
        
        if (mounted) {
          setState(() {
            _userVoices = voices;
            _isLoadingVoices = false;
          });
          
          // Show user-friendly message if voices were loaded
          if (voices.isNotEmpty && _selectedVoiceType == 'custom') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${voices.length} custom voice(s) loaded'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        debugPrint('📢 No user ID found');
        if (mounted) {
          setState(() {
            _isLoadingVoices = false;
          });
        }
      }
    } catch (e, stackTrace) {
      debugPrint('📢 Error loading voices: $e');
      debugPrint('📢 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoadingVoices = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading voices: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    // Don't allow play if no voice is selected
    if (_selectedVoiceType == null && _playerState != PlayerState.playing) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a voice type first'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      if (mounted) {
        setState(() {
          _playerState = PlayerState.paused; // instant UI update
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _playerState = PlayerState.playing; // optimistic update
        });
      }

      try {
        final userId = SupabaseService.client.auth.currentUser?.id;

        if (widget.story.audioDefaultUrl.isNotEmpty &&
            widget.story.audioDefaultUrl.startsWith('http')) {
          await _audioPlayer.play(
            widget.story.audioDefaultUrl,
            isParentVoice: _selectedVoiceType != null,
            userId: userId,
            storyId: widget.story.id,
            selectedVoiceId:
                _selectedVoiceType == 'custom' ? _selectedVoiceId : null,
            story: widget.story,
            voiceType: _selectedVoiceType ?? 'ai_male',
          );
        } else {
          await _audioPlayer.play(
            '',
            isParentVoice: _selectedVoiceType != null,
            userId: userId,
            storyId: widget.story.id,
            selectedVoiceId:
                _selectedVoiceType == 'custom' ? _selectedVoiceId : null,
            story: widget.story,
            voiceType: _selectedVoiceType ?? 'ai_male',
          );
        }
      } catch (e) {
        debugPrint('Error playing audio: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing audio: $e'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _playerState = PlayerState.stopped;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up, color: Colors.white),
              title: const Text('Volume', style: TextStyle(color: Colors.white)),
              trailing: Slider(
                value: _volume,
                onChanged: (value) {
                  setState(() {
                    _volume = value;
                  });
                  _audioPlayer.setVolume(value);
                },
                activeColor: Colors.white,
                inactiveColor: Colors.grey,
              ),
            ),
            ListTile(
              leading: Icon(
                _isRepeatMode ? Icons.repeat_on : Icons.repeat,
                color: Colors.white,
              ),
              title: const Text('Repeat', style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: _isRepeatMode,
                onChanged: (value) {
                  setState(() {
                    _isRepeatMode = value;
                  });
                },
                activeThumbColor: Colors.deepPurple,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: Colors.white),
              title: const Text('Sleep Timer', style: TextStyle(color: Colors.white)),
              trailing: DropdownButton<int?>(
                value: _sleepTimerMinutes,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Off')),
                  const DropdownMenuItem(value: 5, child: Text('5 min')),
                  const DropdownMenuItem(value: 10, child: Text('10 min')),
                  const DropdownMenuItem(value: 15, child: Text('15 min')),
                  const DropdownMenuItem(value: 30, child: Text('30 min')),
                  const DropdownMenuItem(value: 60, child: Text('1 hour')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sleepTimerMinutes = value;
                  });
                },
                dropdownColor: Colors.grey.shade800,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceSelection() {
    if (_isLoadingVoices) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: const Center(
          child: SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
        ),
      );
    }

    // Ultra Compact Voice Selection with Custom Voices Support
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          // Main voice type row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.record_voice_over, size: 12, color: AppTheme.accentColor),
              ),
              const SizedBox(width: 6),
              const Text(
                'Voice:',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _selectedVoiceType,
                      isExpanded: true,
                      dropdownColor: Colors.grey.shade900,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                      hint: const Text('Select Voice', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 12),
                      items: const [
                        DropdownMenuItem(value: 'ai_male', child: Text('AI Male')),
                        DropdownMenuItem(value: 'ai_female', child: Text('AI Female')),
                        DropdownMenuItem(value: 'custom', child: Text('Custom')),
                      ],
                      onChanged: (value) async {
                        if (value == null) return;
                        debugPrint('📢 Voice type selected: $value');
                        setState(() {
                          _selectedVoiceType = value;
                          if (value != 'custom') {
                            _selectedVoiceId = null;
                          } else {
                            // Reload voices when custom is selected
                            _loadUserVoices();
                          }
                        });
                        if (_playerState != PlayerState.playing) {
                          await _togglePlayPause();
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Custom voices dropdown when custom is selected
          if (_selectedVoiceType == 'custom' && _userVoices.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedVoiceId,
                  isExpanded: true,
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                  hint: const Text('Select Voice', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 12),
                  items: _userVoices
                      .map((v) => DropdownMenuItem(
                            value: v.voiceId, // Use voiceId instead of id
                            child: Text(v.voiceName),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    debugPrint('📢 Custom voice selected: $value');
                    setState(() => _selectedVoiceId = value);
                    if (value != null && _playerState != PlayerState.playing) {
                      await _togglePlayPause();
                    }
                  },
                ),
              ),
            ),
          ],
          // Show message if no custom voices available
          if (_selectedVoiceType == 'custom' && _userVoices.isEmpty && !_isLoadingVoices) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 10, color: Colors.orange),
                  const SizedBox(width: 4),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.go('/voice-cloning'),
                      child: const Text(
                        'No custom voices. Tap to create one.',
                        style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Show loading indicator when loading voices
          if (_selectedVoiceType == 'custom' && _isLoadingVoices) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      color: Colors.white70,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Loading voices...',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedVoiceType == type;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedVoiceType = type;
          if (type != 'custom') {
            _selectedVoiceId = null;
          }
        });
        
        // Auto-play audio after voice selection
        if (_playerState != PlayerState.playing) {
          await _togglePlayPause();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    AppTheme.accentColor.withValues(alpha: 0.3),
                    AppTheme.accentColor.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected 
                ? AppTheme.accentColor
                : Colors.white.withValues(alpha: 0.4),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.accentColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentColor : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentColor : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _seekRelative(int seconds) async {
    if (_duration.inSeconds > 0) {
      final newPosition = _position + Duration(seconds: seconds);
      final clampedPosition = Duration(
        seconds: newPosition.inSeconds.clamp(0, _duration.inSeconds),
      );
      await _audioPlayer.seek(clampedPosition);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.purple.shade800,
              Colors.deepPurple.shade700,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        _audioPlayer.stop();
                        context.go('/home');
                      },
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PLAYING FROM STORYHUG',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _showMoreOptions,
                      icon: const Icon(
                        Icons.more_vert,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Story Illustration (Album Art Style) - Smaller
                Center(
                  child: Container(
                    width: min(MediaQuery.of(context).size.width * 0.6, 250),
                    height: min(MediaQuery.of(context).size.width * 0.6, 250),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: widget.story.thumbnailUrl != null
                          ? Image.network(
                              widget.story.thumbnailUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.purple.shade600,
                                        Colors.pink.shade500,
                                      ],
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.book,
                                    size: 80,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.blue.shade400,
                                    Colors.purple.shade600,
                                    Colors.pink.shade500,
                                  ],
                                ),
                              ),
                              child: const Icon(
                                Icons.book,
                                size: 80,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Story Title and Description - Smaller
                Text(
                  widget.story.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'StoryHug Bedtime Stories',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Voice Selection - Improved Layout
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildVoiceSelection(),
                ),
                
                const SizedBox(height: 15),
                
                // Control Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Previous Button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 32),
                        onPressed: () {
                          _audioPlayer.seek(Duration.zero);
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 20),

                    // Play/Pause Button (Circular Button)
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            _playerState == PlayerState.playing
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            key: ValueKey(_playerState),
                            size: 45,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),

                    // Next Button
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 32),
                        onPressed: () {
                          _audioPlayer.seek(_duration);
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
