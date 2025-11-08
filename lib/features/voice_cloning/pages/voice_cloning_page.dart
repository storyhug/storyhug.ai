import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:async';
import '../services/voice_cloning_service.dart';
import '../services/voice_recording_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/models/user_voice.dart';
import '../../../shared/widgets/storyhug_background.dart';

class VoiceCloningPage extends StatefulWidget {
  const VoiceCloningPage({super.key});

  @override
  State<VoiceCloningPage> createState() => _VoiceCloningPageState();
}

class _VoiceCloningPageState extends State<VoiceCloningPage> {
  final VoiceRecordingService _recordingService = VoiceRecordingService();
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  
  String? _currentUserId;
  String _recordingStatus = '';
  int _recordingStep = 0; // 0: instructions, 1: recording, 2: processing, 3: complete
  
  // Voice naming
  final TextEditingController _voiceNameController = TextEditingController();
  final TextEditingController _voiceDescriptionController = TextEditingController();
  List<UserVoice> _userVoices = [];

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId != null) {
        setState(() {
          _currentUserId = userId;
        });
        
        // Load existing voices
        await _loadUserVoices();
      }
    } catch (e) {
      print('Error initializing voice cloning page: $e');
    }
  }

  /// Monitor recording state for auto-stop transitions
  void _monitorRecordingState() {
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      // Check if recording was auto-stopped
      if (_recordingStep == 1 && !_recordingService.isRecording) {
        timer.cancel();
        print('🔄 Auto-stop detected, transitioning to processing...');
        
        setState(() {
          _recordingStep = 2;
          _recordingStatus = 'Auto-stopped. Validating recording quality...';
        });
        
        // Process the recording
        _processRecording();
      }
    });
  }

  Future<void> _loadUserVoices() async {
    if (_currentUserId == null) return;
    
    try {
      final voices = await _voiceCloningService.getUserVoices(_currentUserId!);
      setState(() {
        _userVoices = voices;
      });
    } catch (e) {
      print('Error loading user voices: $e');
    }
  }

  Future<void> _handleVoiceAction(String action, UserVoice voice) async {
    switch (action) {
      case 'rename':
        await _renameVoice(voice);
        break;
      case 'delete':
        await _deleteVoice(voice);
        break;
    }
  }

  Future<void> _renameVoice(UserVoice voice) async {
    final nameController = TextEditingController(text: voice.voiceName);
    final descriptionController = TextEditingController(text: voice.voiceDescription ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Voice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Voice Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _voiceCloningService.updateVoice(
          _currentUserId!,
          voice.voiceId,
          nameController.text.trim(),
          voiceDescription: descriptionController.text.trim().isNotEmpty ? descriptionController.text.trim() : null,
        );
        await _loadUserVoices(); // Reload to update UI
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice renamed to ${nameController.text.trim()}'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to rename voice: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteVoice(UserVoice voice) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice'),
        content: Text('Are you sure you want to delete "${voice.voiceName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _voiceCloningService.deleteVoice(_currentUserId!, voice.voiceId);
        await _loadUserVoices(); // Reload to update UI
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${voice.voiceName} has been deleted'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete voice: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _recordingService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Cloning'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/parental-dashboard');
            }
          },
        ),
      ),
      body: StoryHugBackground(
        showStars: true,
        animateStars: false,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                _buildMainContent(),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                _buildActionButtons(),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    switch (_recordingStep) {
      case 0:
        return _buildInstructions();
      case 1:
        return _buildRecording();
      case 2:
        return _buildProcessing();
      case 3:
        return _buildComplete();
      default:
        return _buildInstructions();
    }
  }

  Widget _buildInstructions() {
    return Column(
      children: [
        // Illustration
        Container(
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
          child: const Icon(
            Icons.mic,
            size: 80,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),
        
        // Title
        const Text(
          'Record Your Voice',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        // Description
        const Text(
          'Create your personalized voice for storytelling. Your child will hear your voice in every story.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        
        // Instructions
        _buildInstructionsList(),
        const SizedBox(height: 32),
        
        // Sample Text
        _buildSampleText(),
      ],
    );
  }

  Widget _buildInstructionsList() {
    final instructions = _voiceCloningService.getRecordingInstructions();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recording Tips:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...instructions.map((instruction) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    instruction,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSampleText() {
    final sampleText = _voiceCloningService.getSampleRecordingText();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.text_fields,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Read this text aloud:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              sampleText.trim(),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            '💡 Tip: Read naturally and clearly. Don\'t rush!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecording() {
    return Column(
      children: [
        // Recording Animation
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.withValues(alpha: 0.2),
            border: Border.all(
              color: Colors.red,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.mic,
            size: 80,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 32),
        
        // Recording Status
        const Text(
          'Recording...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        const SizedBox(height: 16),
        
        Text(
          _recordingStatus,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 24),
        
        // Sample text (prominently displayed)
        _buildSampleText(),
        const SizedBox(height: 24),
        
        // Recording Tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recording Tips:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              _buildInstructionsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProcessing() {
    return Column(
      children: [
        // Processing Animation
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
          ),
          child: const CircularProgressIndicator(
            color: AppTheme.primaryColor,
            strokeWidth: 4,
          ),
        ),
        const SizedBox(height: 32),
        
        // Processing Status
        const Text(
          'Processing Your Voice',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        Text(
          _recordingStatus,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 32),
        
        // Processing Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'This may take a few minutes. Your voice is being processed to create a personalized model.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildComplete() {
    return Column(
      children: [
        // Success Illustration
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.successColor.withValues(alpha: 0.2),
            border: Border.all(
              color: AppTheme.successColor,
              width: 3,
            ),
          ),
          child: const Icon(
            Icons.check,
            size: 80,
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(height: 32),
        
        // Success Message
        const Text(
          'Voice Cloned Successfully!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        
        const Text(
          'Your personalized voice is ready. Your child will now hear your voice in every story.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
        
        // Show existing voices
        if (_userVoices.isNotEmpty) ...[
          const Text(
            'Your Voices:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          _buildVoicesList(),
          const SizedBox(height: 24),
        ],
        
        // Features
        _buildSuccessFeatures(),
      ],
    );
  }

  Widget _buildVoicesList() {
    if (_userVoices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'No voices recorded yet. Record your first voice above!',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: _userVoices.length,
        itemBuilder: (context, index) {
          final voice = _userVoices[index];
          return Card(
            color: Colors.white.withValues(alpha: 0.1),
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(
                Icons.record_voice_over,
                color: Colors.white70,
              ),
              title: Text(
                voice.voiceName,
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: voice.voiceDescription != null
                  ? Text(
                      voice.voiceDescription!,
                      style: const TextStyle(color: Colors.white70),
                    )
                  : null,
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (value) => _handleVoiceAction(value, voice),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Rename'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSuccessFeatures() {
    final features = [
      'Your voice in every story',
      'Natural storytelling tone',
      'Personalized bedtime experience',
      'Available for all story categories',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s Next:',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          ...features.map((feature) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.star,
                  color: AppTheme.accentColor,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    feature,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (_recordingStep) {
      case 0:
        return _buildStartRecordingButton();
      case 1:
        return _buildStopRecordingButton();
      case 2:
        return const SizedBox.shrink(); // Processing, no buttons
      case 3:
        return _buildCompleteButtons();
      default:
        return _buildStartRecordingButton();
    }
  }

  Widget _buildStartRecordingButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _startRecording,
        child: const Text('START RECORDING'),
      ),
    );
  }

  Widget _buildStopRecordingButton() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: _cancelRecording,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
              child: const Text('CANCEL'),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _stopRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('STOP'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('GO TO STORIES'),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _reRecordVoice,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
            child: const Text('RECORD AGAIN'),
          ),
        ),
      ],
    );
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _recordingStep = 1;
        _recordingStatus = 'Preparing to record...';
      });

      print('🎤 Starting recording...');
      
      // Reset any previous recording state
      _recordingService.resetRecordingState();
      
      final success = await _recordingService.startRecording();
      
      if (success) {
        setState(() {
          _recordingStatus = 'Recording in progress... Speak clearly!';
        });
        print('✅ Recording started successfully');
        
        // Start monitoring for auto-stop
        _monitorRecordingState();
      } else {
        throw Exception('Failed to start recording');
      }
    } catch (e) {
      print('❌ Recording start failed: $e');
      setState(() {
        _recordingStep = 0;
      });
      
      if (mounted) {
        String errorMessage = 'Recording failed: $e';
        
        // Provide specific error messages
        if (e.toString().contains('permission')) {
          errorMessage = 'Microphone permission denied. Please enable microphone access in settings.';
        } else if (e.toString().contains('audio')) {
          errorMessage = 'Audio recording error. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _recordingStatus = 'Stopping recording...';
      });

      print('🛑 Stopping recording...');
      final recordingPath = await _recordingService.stopRecording();
      
      if (recordingPath != null) {
        print('✅ Recording stopped successfully: $recordingPath');
        setState(() {
          _recordingStep = 2;
          _recordingStatus = 'Validating recording quality...';
        });

        await _processRecording();
      } else {
        throw Exception('Failed to stop recording');
      }
    } catch (e) {
      print('❌ Stop recording failed: $e');
      setState(() {
        _recordingStep = 0;
      });
      
      if (mounted) {
        String errorMessage = 'Stop recording failed: $e';
        
        // Show specific error message for API permission issues
        if (e.toString().contains('missing_permissions')) {
          errorMessage = 'API Permission Error: Please check your ElevenLabs API key has voices_write permission.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Authentication Error: Invalid ElevenLabs API key.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _recordingService.cancelRecording();
      setState(() {
        _recordingStep = 0;
        _recordingStatus = '';
      });
    } catch (e) {
      // Handle cancellation error
    }
  }

  Future<void> _processRecording() async {
    try {
      if (_currentUserId == null) {
        throw Exception('User not authenticated');
      }

      setState(() {
        _recordingStatus = 'Processing your voice with AI...';
      });

      // Get the recording file path
      final recordingPath = await _recordingService.getCurrentRecordingPath();
      if (recordingPath == null) {
        throw Exception('No recording found');
      }

      // Show voice naming dialog
      final voiceName = await _showVoiceNamingDialog();
      if (voiceName == null) {
        setState(() {
          _recordingStep = 0;
          _recordingStatus = 'Recording cancelled';
        });
        return;
      }

      setState(() {
        _recordingStatus = 'Cloning your voice...';
      });

      // Clone voice using ElevenLabs with custom name
      await _voiceCloningService.cloneVoice(
        File(recordingPath), 
        _currentUserId!,
        voiceName,
        voiceDescription: _voiceDescriptionController.text.isNotEmpty 
            ? _voiceDescriptionController.text 
            : null,
      );
      
      setState(() {
        _recordingStep = 3;
        _recordingStatus = 'Voice cloning completed successfully!';
      });

      // Reload voices
      await _loadUserVoices();
      
      // Clear text controllers
      _voiceNameController.clear();
      _voiceDescriptionController.clear();

      // Show success dialog
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _recordingStep = 0;
      });
      
      if (mounted) {
        String errorMessage = 'Voice processing failed: $e';
        
        // Handle specific error cases
        if (e.toString().contains('duplicate key value') || 
            e.toString().contains('unique constraint') ||
            e.toString().contains('user_voices_user_id_voice_name_key')) {
          errorMessage = 'A voice with this name already exists. Please use a different name or delete the existing voice first.';
        } else if (e.toString().contains('missing_permissions')) {
          errorMessage = 'API Permission Error: Please check your ElevenLabs API key has voices_write permission.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Authentication Error: Invalid ElevenLabs API key.';
        } else if (e.toString().contains('quota')) {
          errorMessage = 'API Quota Exceeded: You have reached your ElevenLabs API quota.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _reRecordVoice() async {
    try {
      if (_currentUserId != null) {
        await _voiceCloningService.deleteClonedVoice(_currentUserId!);
      }
      
      setState(() {
        _recordingStep = 0;
        _recordingStatus = '';
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<String?> _showVoiceNamingDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Name Your Voice'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Give your voice a name so you can easily identify it later.'),
            const SizedBox(height: 16),
            TextField(
              controller: _voiceNameController,
              decoration: const InputDecoration(
                labelText: 'Voice Name',
                hintText: 'e.g., Mom, Dad, Grandma',
                border: OutlineInputBorder(),
                helperText: 'Must be unique',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _voiceDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g., Perfect for bedtime stories',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Show existing voice names
            if (_userVoices.isNotEmpty) ...[
              const Text(
                'Existing voices:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _userVoices.map((v) => v.voiceName).join(', '),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final voiceName = _voiceNameController.text.trim();
              if (voiceName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a voice name'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              // Check if name already exists
              final isDuplicate = _userVoices.any((v) => 
                v.voiceName.toLowerCase() == voiceName.toLowerCase()
              );
              
              if (isDuplicate) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Voice name "$voiceName" already exists. Please use a different name.'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              
              Navigator.pop(context, voiceName);
            },
            child: const Text('Save Voice'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Voice Cloning Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Your voice has been successfully cloned!'),
            SizedBox(height: 16),
            Text(
              'Now you can use your voice for all stories in the app. '
              'Simply toggle the "Parent Voice" option when playing any story.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: Text('Start Listening'),
          ),
        ],
      ),
    );
  }
}
