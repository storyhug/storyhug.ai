import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/story_tuning/story_tuning.dart';
import '../../../core/theme/app_theme.dart';

/// Demo page to test StoryTuning Service
class StoryTuningDemoPage extends StatefulWidget {
  const StoryTuningDemoPage({Key? key}) : super(key: key);

  @override
  State<StoryTuningDemoPage> createState() => _StoryTuningDemoPageState();
}

class _StoryTuningDemoPageState extends State<StoryTuningDemoPage> {
  final _storyTuningService = StoryTuningService();
  final _textController = TextEditingController(
    text: '''Once upon a time, there was a brave prince named Rama. He was very happy and excited about his journey to the magical forest. Suddenly, a terrible demon appeared! Rama fought fearlessly with his mighty bow. Finally, he achieved a great victory! Everyone celebrated with joy.''',
  );
  
  final _childNameController = TextEditingController(text: 'Arjun');
  final _parentNameController = TextEditingController(text: 'Mom');
  
  List<TunedSegment> _tunedSegments = [];
  Map<String, dynamic>? _statistics;
  bool _isProcessing = false;
  bool _enableExpansion = true;
  bool _enablePersonalization = true;
  bool _enablePacing = true;

  @override
  void dispose() {
    _textController.dispose();
    _childNameController.dispose();
    _parentNameController.dispose();
    super.dispose();
  }

  Future<void> _processStory() async {
    if (_textController.text.isEmpty) {
      _showMessage('Please enter some story text', isError: true);
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Tune the story
      final segments = await _storyTuningService.tuneStory(
        storyText: _textController.text,
        childName: _childNameController.text.isEmpty ? null : _childNameController.text,
        parentName: _parentNameController.text.isEmpty ? null : _parentNameController.text,
        enableExpansion: _enableExpansion,
        enablePersonalization: _enablePersonalization,
        enablePacing: _enablePacing,
      );

      // Get statistics
      final stats = _storyTuningService.getTuningStatistics(segments);

      setState(() {
        _tunedSegments = segments;
        _statistics = stats;
      });

      _showMessage('✅ Processed ${segments.length} segments!', isError: false);
    } catch (e) {
      _showMessage('❌ Error: $e', isError: true);
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joyful':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'excited':
        return Colors.orange;
      case 'calm':
      case 'gentle':
        return Colors.teal;
      case 'fearful':
        return Colors.purple;
      case 'angry':
        return Colors.red;
      case 'surprised':
        return Colors.pink;
      case 'mysterious':
        return Colors.indigo;
      case 'dramatic':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joyful':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'excited':
        return Icons.celebration;
      case 'calm':
      case 'gentle':
        return Icons.self_improvement;
      case 'fearful':
        return Icons.warning;
      case 'angry':
        return Icons.sentiment_very_dissatisfied;
      case 'surprised':
        return Icons.lightbulb;
      case 'mysterious':
        return Icons.visibility_off;
      case 'dramatic':
        return Icons.theater_comedy;
      default:
        return Icons.sentiment_neutral;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/parental-dashboard'),
          tooltip: 'Back to Dashboard',
        ),
        title: Text(
          'Story Tuning Demo',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Story Input
                _buildCard(
                  title: '📝 Story Text',
                  child: TextField(
                    controller: _textController,
                    maxLines: 6,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Enter your story here...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Personalization Inputs
                _buildCard(
                  title: '👤 Personalization (Optional)',
                  child: Column(
                    children: [
                      TextField(
                        controller: _childNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Child Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., Arjun',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _parentNameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Parent Name',
                          labelStyle: TextStyle(color: Colors.white70),
                          hintText: 'e.g., Mom',
                          hintStyle: TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Feature Toggles
                _buildCard(
                  title: '⚙️ Features',
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Descriptive Expansion', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Make text more vivid', style: TextStyle(color: Colors.white70)),
                        value: _enableExpansion,
                        onChanged: (value) => setState(() => _enableExpansion = value),
                        activeColor: AppTheme.accentColor,
                      ),
                      SwitchListTile(
                        title: const Text('Personalization', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Inject names', style: TextStyle(color: Colors.white70)),
                        value: _enablePersonalization,
                        onChanged: (value) => setState(() => _enablePersonalization = value),
                        activeColor: AppTheme.accentColor,
                      ),
                      SwitchListTile(
                        title: const Text('Pacing & Pauses', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Natural rhythm', style: TextStyle(color: Colors.white70)),
                        value: _enablePacing,
                        onChanged: (value) => setState(() => _enablePacing = value),
                        activeColor: AppTheme.accentColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Process Button
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentColor,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : Text(
                          '🎯 Process Story',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Statistics
                if (_statistics != null) ...[
                  _buildCard(
                    title: '📊 Statistics',
                    child: Column(
                      children: [
                        _buildStatRow('Total Segments', '${_statistics!['total_segments']}'),
                        _buildStatRow('Total Words', '${_statistics!['total_words']}'),
                        _buildStatRow('Unique Emotions', '${_statistics!['unique_emotions']}'),
                        _buildStatRow('Duration', '${_statistics!['estimated_duration_minutes']} min'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: (_statistics!['emotion_list'] as List)
                              .map((emotion) => Chip(
                                    label: Text(emotion),
                                    backgroundColor: _getEmotionColor(emotion),
                                    labelStyle: const TextStyle(color: Colors.white),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tuned Segments
                if (_tunedSegments.isNotEmpty) ...[
                  _buildCard(
                    title: '🎭 Tuned Segments (${_tunedSegments.length})',
                    child: Column(
                      children: _tunedSegments.asMap().entries.map((entry) {
                        final index = entry.key;
                        final segment = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: Colors.white.withOpacity(0.1),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getEmotionColor(segment.emotion),
                              child: Icon(
                                _getEmotionIcon(segment.emotion),
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              segment.text.replaceAll(RegExp(r'<[^>]+>'), ''),
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'Emotion: ${segment.emotion} • Pause: ${segment.pauseAfter ?? 'none'}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: Text(
                              '#${index + 1}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Card(
      color: Colors.white.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

