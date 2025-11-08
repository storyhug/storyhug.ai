import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:math';
import '../services/audio_player_service.dart';
import '../../../shared/models/story.dart';
import '../../../shared/models/user_voice.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../voice_cloning/services/voice_cloning_service.dart';

/// A polished Spotify-style music player screen with modern UI/UX
/// 
/// Features:
/// - Real-time audio position and duration updates
/// - Smooth draggable progress bar with seek functionality
/// - Compact and modern voice selection with chips
/// - Elegant animations for play/pause transitions
/// - Responsive design for all device sizes
/// - Professional audio controls and error handling
/// 
/// Asset Requirements:
/// - Audio files should be placed in assets/audio/ directory
/// - Example: assets/audio/sample_song_1.mp3, assets/audio/sample_song_2.mp3
class MusicPlayerScreen extends StatefulWidget {
  final Story story;
  
  const MusicPlayerScreen({super.key, required this.story});

  @override
  State<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen>
    with TickerProviderStateMixin {
  final AudioPlayerService _audioPlayer = AudioPlayerService();
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  
  // Audio state
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isLoading = false;
  bool _isSeeking = false;
  
  // Voice selection
  String? _selectedVoiceId;
  String _selectedVoiceType = 'default';
  List<UserVoice> _userVoices = [];
  bool _isLoadingVoices = true;
  
  // UI state
  double _volume = 0.8;
  bool _isRepeatMode = false;
  int? _sleepTimerMinutes;
  
  // Animation controllers
  late AnimationController _playPauseAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _playPauseAnimation;
  late Animation<double> _pulseAnimation;
  
  // Stream subscriptions
  StreamSubscription<Duration>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupAudioPlayer();
    _loadUserVoices();
  }

  @override
  void dispose() {
    _cleanupListeners();
    _playPauseAnimationController.dispose();
    _pulseAnimationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _playPauseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _playPauseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playPauseAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));
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
    _cleanupListeners();
    
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted && !_isSeeking) {
        setState(() {
          _position = position;
        });
      }
    });

    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
        
        // Handle animations
        if (state == PlayerState.playing) {
          _playPauseAnimationController.forward();
          _pulseAnimationController.repeat(reverse: true);
        } else {
          _playPauseAnimationController.reverse();
          _pulseAnimationController.stop();
          _pulseAnimationController.reset();
        }
      }
    });
  }

  Future<void> _loadUserVoices() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final voices = await _voiceCloningService.getUserVoices(userId);
        if (mounted) {
          setState(() {
            _userVoices = voices;
            _isLoadingVoices = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingVoices = false;
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final userId = SupabaseService.client.auth.currentUser?.id;
        
        if (widget.story.audioDefaultUrl.isNotEmpty && 
            widget.story.audioDefaultUrl.startsWith('http')) {
          await _audioPlayer.play(
            widget.story.audioDefaultUrl,
            isParentVoice: _selectedVoiceType != 'default',
            userId: userId,
            storyId: widget.story.id,
            selectedVoiceId: _selectedVoiceType == 'custom' ? _selectedVoiceId : null,
            story: widget.story,
            voiceType: _selectedVoiceType,
          );
        } else {
          await _audioPlayer.play(
            '',
            isParentVoice: _selectedVoiceType != 'default',
            userId: userId,
            storyId: widget.story.id,
            selectedVoiceId: _selectedVoiceType == 'custom' ? _selectedVoiceId : null,
            story: widget.story,
            voiceType: _selectedVoiceType,
          );
        }
      } catch (e) {
        debugPrint('Error playing audio: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error playing audio: $e'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
  }

  void _onSeekStart(double value) {
    setState(() {
      _isSeeking = true;
    });
  }

  void _onSeekEnd(double value) {
    final position = Duration(
      milliseconds: (value * _duration.inMilliseconds).round(),
    );
    _audioPlayer.seek(position);
    setState(() {
      _isSeeking = false;
    });
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
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Volume control
            ListTile(
              leading: const Icon(Icons.volume_up, color: Colors.white),
              title: const Text('Volume', style: TextStyle(color: Colors.white)),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _volume,
                  onChanged: (value) {
                    setState(() {
                      _volume = value;
                    });
                    _audioPlayer.setVolume(value);
                  },
                  activeColor: AppTheme.accentColor,
                  inactiveColor: Colors.grey,
                ),
              ),
            ),
            
            // Repeat mode
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
                  _audioPlayer.toggleRepeatMode();
                },
                activeThumbColor: AppTheme.accentColor,
                activeColor: AppTheme.accentColor.withOpacity(0.3),
              ),
            ),
            
            // Sleep timer
            ListTile(
              leading: const Icon(Icons.bedtime, color: Colors.white),
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
                  if (value != null) {
                    _audioPlayer.setSleepTimer(value);
                  } else {
                    _audioPlayer.cancelSleepTimer();
                  }
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
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: AppTheme.accentColor,
                strokeWidth: 2,
              ),
              SizedBox(height: 12),
              Text(
                'Loading voices...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.record_voice_over,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Choose Voice',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Voice type chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildVoiceChip('default', 'Default', Icons.volume_up),
              _buildVoiceChip('ai_male', 'AI Male', Icons.person),
              _buildVoiceChip('ai_female', 'AI Female', Icons.person_outline),
              if (_userVoices.isNotEmpty)
                _buildVoiceChip('custom', 'Custom', Icons.mic),
            ],
          ),
          
          // Custom voice dropdown
          if (_selectedVoiceType == 'custom' && _userVoices.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: _selectedVoiceId,
                  isExpanded: true,
                  dropdownColor: Colors.grey.shade800,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  items: _userVoices.map((voice) => DropdownMenuItem(
                    value: voice.id,
                    child: Text(voice.voiceName),
                  )).toList(),
                  onChanged: (value) async {
                    setState(() {
                      _selectedVoiceId = value;
                    });
                    
                    if (value != null && _playerState != PlayerState.playing) {
                      await _togglePlayPause();
                    }
                  },
                ),
              ),
            ),
          ],
          
          // Create voice button
          if (_userVoices.isEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/voice-cloning'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Custom Voice'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentColor,
                  side: BorderSide(color: AppTheme.accentColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceChip(String type, String label, IconData icon) {
    final isSelected = _selectedVoiceType == type;
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedVoiceType = type;
          if (type != 'custom') {
            _selectedVoiceId = null;
          }
        });
        
        if (_playerState != PlayerState.playing) {
          await _togglePlayPause();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected 
              ? LinearGradient(
                  colors: [
                    AppTheme.accentColor.withOpacity(0.3),
                    AppTheme.accentColor.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? AppTheme.accentColor
                : Colors.white.withOpacity(0.3),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppTheme.accentColor.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentColor : Colors.white70,
              size: 14,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.accentColor : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Header
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
                        size: 28,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'PLAYING FROM STORYHUG',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 11,
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
                        size: 24,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                
                // Album art
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _playerState == PlayerState.playing 
                          ? _pulseAnimation.value 
                          : 1.0,
                      child: Container(
                        width: min(screenWidth * 0.75, 320),
                        height: min(screenWidth * 0.75, 320),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: widget.story.thumbnailUrl != null
                              ? Image.network(
                                  widget.story.thumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return _buildDefaultAlbumArt();
                                  },
                                )
                              : _buildDefaultAlbumArt(),
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Title and artist
                Text(
                  widget.story.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
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
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          trackHeight: 3,
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 12,
                          ),
                        ),
                        child: Slider(
                          value: _duration.inMilliseconds > 0
                              ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: _onSeekStart,
                          onChangeEnd: _onSeekEnd,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(_position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatDuration(_duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Voice selection
                _buildVoiceSelection(),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle (disabled)
                    IconButton(
                      onPressed: null,
                      icon: const Icon(
                        Icons.shuffle,
                        color: Colors.white30,
                        size: 24,
                      ),
                    ),
                    
                    // Previous (disabled)
                    IconButton(
                      onPressed: null,
                      icon: const Icon(
                        Icons.skip_previous,
                        color: Colors.white30,
                        size: 32,
                      ),
                    ),
                    
                    // Play/Pause button
                    AnimatedBuilder(
                      animation: _playPauseAnimation,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : _togglePlayPause,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.deepPurple,
                                    ),
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      _playerState == PlayerState.playing 
                                          ? Icons.pause 
                                          : Icons.play_arrow,
                                      key: ValueKey(_playerState),
                                      color: Colors.deepPurple,
                                      size: 36,
                                    ),
                                  ),
                            iconSize: 36,
                            padding: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                    
                    // Next (disabled)
                    IconButton(
                      onPressed: null,
                      icon: const Icon(
                        Icons.skip_next,
                        color: Colors.white30,
                        size: 32,
                      ),
                    ),
                    
                    // Repeat
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isRepeatMode = !_isRepeatMode;
                        });
                        _audioPlayer.toggleRepeatMode();
                      },
                      icon: Icon(
                        _isRepeatMode ? Icons.repeat_on : Icons.repeat,
                        color: _isRepeatMode ? AppTheme.accentColor : Colors.white70,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAlbumArt() {
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
        size: 60,
        color: Colors.white,
      ),
    );
  }
}
