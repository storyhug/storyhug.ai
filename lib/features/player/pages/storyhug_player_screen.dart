import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';
import 'package:rxdart/rxdart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audio_session/audio_session.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_voice.dart';
import '../../voice_cloning/services/voice_cloning_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:math';

/// Modern StoryHug Bedtime Stories Audio Player Screen
/// 
/// Features:
/// - Dynamic time labels with proper duration formatting
/// - Smooth seek bar with drag functionality
/// - Compact voice selection dropdown (AI Male, AI Female, Custom)
/// - Google Fonts typography (Poppins)
/// - Gradient background with centered content
/// - Smooth play/pause animations
/// - Responsive design for Android and iOS
/// 
/// Asset Requirements:
/// - Audio files should be placed in assets/audio/ directory
/// - Example: assets/audio/sample_story.mp3
class StoryhugPlayerScreen extends StatefulWidget {
  final String storyTitle;
  final String storyArtist;
  final String audioPath;
  
  const StoryhugPlayerScreen({
    super.key,
    required this.storyTitle,
    required this.storyArtist,
    required this.audioPath,
  });

  @override
  State<StoryhugPlayerScreen> createState() => _StoryhugPlayerScreenState();
}

class _StoryhugPlayerScreenState extends State<StoryhugPlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  late AnimationController _playPauseAnimationController;
  late Animation<double> _playPauseAnimation;
  
  // Voice selection
  String _selectedVoice = 'AI Male';
  bool _isCustomVoiceAvailable = true; // Simulate custom voice availability
  String? _selectedCustomVoice; // For custom voice dropdown
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  List<UserVoice> _userVoices = [];
  
  // Audio state
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _isSeeking = false;
  bool _sourceLoaded = false;
  
  // Stream subscriptions
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    _initializeAnimations();
    _loadUserVoices();
  }

  @override
  void dispose() {
    _cleanupSubscriptions();
    _audioPlayer.dispose();
    _playPauseAnimationController.dispose();
    super.dispose();
  }

  void _initializeAudioPlayer() {
    _audioPlayer = AudioPlayer();
    
    // Listen to duration changes
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    });
    
    // Listen to position changes
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      if (mounted && !_isSeeking) {
        setState(() {
          _position = position;
        });
      }
    });
    
    // Listen to player state changes
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading = state.processingState == ProcessingState.loading ||
                      state.processingState == ProcessingState.buffering;
        });
      }
    });
    
    // Configure audio session for Android/iOS playback
    () async {
      try {
        final session = await AudioSession.instance;
        await session.configure(const AudioSessionConfiguration.music());
      } catch (_) {}
      // Load the audio file
      _loadAudio();
    }();
  }

  Future<void> _loadUserVoices() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        final voices = await _voiceCloningService.getUserVoices(userId);
        if (mounted) {
          setState(() {
            _userVoices = voices;
            _isCustomVoiceAvailable = voices.isNotEmpty;
          });
        }
      }
    } catch (_) {
      // If fetching fails, keep existing simulated state
    }
  }

  Future<String> _downloadToCache(String url) async {
    final directory = await getTemporaryDirectory();
    final fileName = Uri.parse(url).pathSegments.isNotEmpty
        ? Uri.parse(url).pathSegments.last
        : 'audio_cache.mp3';
    final file = File('${directory.path}/$fileName');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
        print('⬇️ Downloaded to ${file.path}');
        return file.path;
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Download failed: $e');
      rethrow;
    }
  }

  void _initializeAnimations() {
    _playPauseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _playPauseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _playPauseAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _cleanupSubscriptions() {
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
  }

  Future<void> _loadAudio() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // FORCE ASSET PLAYBACK for all voices to isolate issues
      String sourcePath;
      switch (_selectedVoice) {
        case 'AI Male':
          sourcePath = 'assets/audio/sample_song_1.mp3';
          break;
        case 'AI Female':
        case 'Custom Voice':
          sourcePath = 'assets/audio/sample_song_2.mp3';
          break;
        default:
          sourcePath = 'assets/audio/sample_song_1.mp3';
      }

      print('🎵 Loading forced asset audio: $sourcePath');
      // Validate asset exists; fallback to sample 1
      try {
        await rootBundle.load(sourcePath);
      } catch (_) {
        sourcePath = 'assets/audio/sample_song_1.mp3';
      }
      await _audioPlayer.setAudioSource(AudioSource.asset(sourcePath));
      _sourceLoaded = true;
      
      setState(() {
        _isLoading = false;
      });
      
      print('✅ Audio loaded successfully');
    } on PlayerException catch (e) {
      setState(() {
        _isLoading = false;
      });
      final message = 'PlayerException code: ${e.code}, message: ${e.message}';
      print('❌ $message');
      // Hard fallback to bundled asset to guarantee playback
      try {
        final fallback = 'assets/audio/sample_song_1.mp3';
        await _audioPlayer.setAudioSource(AudioSource.asset(fallback));
        _sourceLoaded = true;
        setState(() { _isLoading = false; });
        print('✅ Fallback asset loaded');
        return;
      } catch (_) {}
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading audio: $message'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      print('❌ Error loading audio: $e');
      // Final fallback to asset
      try {
        final fallback = 'assets/audio/sample_song_1.mp3';
        await _audioPlayer.setAudioSource(AudioSource.asset(fallback));
        _sourceLoaded = true;
        setState(() { _isLoading = false; });
        print('✅ Fallback asset loaded (generic catch)');
        return;
      } catch (_) {}
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading audio: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        _playPauseAnimationController.reverse();
      } else {
        if (!_sourceLoaded || _audioPlayer.duration == null) {
          await _loadAudio();
        }
        await _audioPlayer.play();
        _playPauseAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error controlling playback: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
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

  void _onVoiceChanged(String? newVoice) {
    if (newVoice != null) {
      setState(() {
        _selectedVoice = newVoice;
      });
      
      // Load different audio for different voices
      _loadAudio();
    }
  }

  void _onCustomVoiceChanged(String? customVoice) {
    setState(() {
      _selectedCustomVoice = customVoice;
    });
    
    // If we have voices from dashboard, try streaming their URL
    final selected = _userVoices.firstWhere(
      (v) => v.voiceName == customVoice,
      orElse: () => _userVoices.isNotEmpty ? _userVoices.first : UserVoice(
        id: 'tmp',
        userId: 'tmp',
        voiceId: 'tmp',
        voiceName: 'Custom',
        voiceDescription: null,
        isDefault: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    // For MVP: reload using asset sample 2; if you have per-voice URLs, swap to setUrl here
    _loadAudio();
  }

  List<String> _getVoiceOptions() {
    // All voice options
    return ['AI Male', 'AI Female', 'Custom Voice'];
  }

  List<String> _getCustomVoiceOptions() {
    if (_userVoices.isNotEmpty) {
      return _userVoices.map((v) => v.voiceName).toList();
    }
    return [];
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
              Colors.purple.shade800,
              Colors.pink.shade600,
              Colors.purple.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                // Header with back button and StoryHug title
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'StoryHug Bedtime Stories',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Album art placeholder
                AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
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
                          size: 92,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Story title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    widget.storyTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                      letterSpacing: 0.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Artist name
                Text(
                  widget.storyArtist,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Voice selection dropdown
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.18),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
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
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.record_voice_over,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Choose Voice',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Main voice dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedVoice,
                            isExpanded: true,
                            dropdownColor: Colors.grey.shade800,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                            items: _getVoiceOptions().map((voice) => DropdownMenuItem(
                              value: voice,
                              child: Text(voice),
                            )).toList(),
                            onChanged: _onVoiceChanged,
                          ),
                        ),
                      ),
                      
                      // Custom voice dropdown (only show when Custom Voice is selected)
                      if (_selectedVoice == 'Custom Voice' && _isCustomVoiceAvailable) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.16),
                              width: 1,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: _selectedCustomVoice,
                              isExpanded: true,
                              dropdownColor: Colors.grey.shade800,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              hint: Text(
                                'Select Custom Voice',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 16,
                              ),
                              items: _getCustomVoiceOptions().map((voice) => DropdownMenuItem(
                                value: voice,
                                child: Text(voice),
                              )).toList(),
                              onChanged: _onCustomVoiceChanged,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 22),
                
                // Progress bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.28),
                          thumbColor: Colors.white,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7,
                          ),
                          trackHeight: 4,
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
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
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              _formatDuration(_position),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              _formatDuration(_duration),
                              style: GoogleFonts.poppins(
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
                
                SizedBox(height: screenHeight * 0.04),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Previous button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: null, // Disabled for single story
                        icon: const Icon(
                          Icons.skip_previous,
                          color: Colors.black54,
                          size: 26,
                        ),
                        iconSize: 26,
                        padding: const EdgeInsets.all(12),
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
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
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
                                      strokeWidth: 2,
                                      color: Colors.purple,
                                    ),
                                  )
                                : AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Icon(
                                      _isPlaying ? Icons.pause : Icons.play_arrow,
                                      key: ValueKey(_isPlaying),
                                      color: Colors.purple,
                                      size: 34,
                                    ),
                                  ),
                            iconSize: 34,
                            padding: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                    
                    // Next button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: null, // Disabled for single story
                        icon: const Icon(
                          Icons.skip_next,
                          color: Colors.black54,
                          size: 26,
                        ),
                        iconSize: 26,
                        padding: const EdgeInsets.all(12),
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
      ),
    );
  }
}

/// Example usage widget for testing
class StoryhugPlayerExample extends StatelessWidget {
  const StoryhugPlayerExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoryhugPlayerScreen(
      storyTitle: "The Magic Forest Adventure",
      storyArtist: "StoryHug Bedtime Stories",
      audioPath: "assets/audio/ai_male_story.mp3", // Default to AI Male
    );
  }
}
