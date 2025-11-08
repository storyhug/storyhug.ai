import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../services/story_import_service.dart';
import '../../../shared/models/story.dart';
import '../providers/story_provider.dart';
import '../services/story_service.dart';

class StoryImportPage extends ConsumerStatefulWidget {
  const StoryImportPage({super.key});

  @override
  ConsumerState<StoryImportPage> createState() => _StoryImportPageState();
}

class _StoryImportPageState extends ConsumerState<StoryImportPage> {
  final StoryImportService _importService = StoryImportService();
  
  bool _isLoading = false;
  String _statusMessage = '';
  List<Map<String, dynamic>> _parsedStories = [];
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final stats = await _importService.getStoryStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Ramayana Stories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/parental-dashboard'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Statistics
                if (_statistics.isNotEmpty) ...[
                  _buildStatistics(),
                  const SizedBox(height: 32),
                ],

                // Import Section
                _buildImportSection(),
                const SizedBox(height: 32),

                // Parsed Stories Preview
                if (_parsedStories.isNotEmpty) ...[
                  _buildStoriesPreview(),
                  const SizedBox(height: 32),
                ],

                // Status Message
                if (_statusMessage.isNotEmpty) ...[
                  _buildStatusMessage(),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Import Ramayana Stories',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Upload your Word document containing 100 Ramayana stories and make them available for audio playback.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.accentColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Current Stories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Stories',
                  '${_statistics['total_stories'] ?? 0}',
                  Icons.book,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Total Duration',
                  '${_statistics['total_duration_minutes'] ?? 0} min',
                  Icons.timer,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildImportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.upload_file,
                color: AppTheme.accentColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Import Stories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Select your Word document (.docx) containing the Ramayana stories. The system will automatically parse and upload them to the database.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickAndParseDocument,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.file_upload),
                  label: Text(_isLoading ? 'Processing...' : 'Pick & Parse Document'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_parsedStories.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _uploadToDatabase,
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload to Database'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentColor,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.preview,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Parsed Stories (${_parsedStories.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _parsedStories.length > 10 ? 10 : _parsedStories.length,
              itemBuilder: (context, index) {
                final story = _parsedStories[index];
                return Card(
                  color: Colors.white.withValues(alpha: 0.05),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        '${story['story_number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      story['title'],
                      style: const TextStyle(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${story['estimated_duration_minutes']} min • ${story['difficulty_level']}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: Text(
                      '${story['keywords'].length} keywords',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_parsedStories.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '... and ${_parsedStories.length - 10} more stories',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
            ? Colors.red.withValues(alpha: 0.2)
            : Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
              ? Colors.red
              : Colors.green,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                ? Icons.error
                : Icons.check_circle,
            color: _statusMessage.contains('Error') || _statusMessage.contains('Failed')
                ? Colors.red
                : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusMessage,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndParseDocument() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
      _parsedStories = [];
    });

    try {
      final stories = await _importService.pickAndProcessDocument();
      setState(() {
        _parsedStories = stories;
        _statusMessage = 'Successfully parsed ${stories.length} stories from document';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error parsing document: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadToDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    final storiesCount = _parsedStories.length;
    String? categoryName;
    
    try {
      await _importService.uploadStoriesToDatabase(_parsedStories);
      
      // Extract category for success message
      if (_parsedStories.isNotEmpty) {
        categoryName = _parsedStories.first['category'] as String?;
      }
      
      setState(() {
        _statusMessage = 'Successfully uploaded $storiesCount stories to database';
        _parsedStories = [];
      });
      
      // Reload statistics
      await _loadStatistics();
      
      // Refresh story provider to show new stories immediately
      await ref.read(storyProvider.notifier).refresh();
      
      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '✅ $storiesCount ${storiesCount == 1 ? 'story' : 'stories'} added successfully'
                    '${categoryName != null ? ' to Featured and $categoryName!' : '!'}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('Import Successful'),
            content: Text(
              'Successfully imported $storiesCount ${storiesCount == 1 ? 'story' : 'stories'} to the database.\n\n'
              '${categoryName != null ? 'They now appear in Featured Stories and the $categoryName category.' : 'They are now available for audio playback.'}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('View in App'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/home');
                },
                child: const Text('Go to Home'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error uploading to database: $e';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
