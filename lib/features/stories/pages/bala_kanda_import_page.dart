import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../providers/story_provider.dart';

class BalaKandaImportPage extends ConsumerStatefulWidget {
  const BalaKandaImportPage({super.key});

  @override
  ConsumerState<BalaKandaImportPage> createState() => _BalaKandaImportPageState();
}

class _BalaKandaImportPageState extends ConsumerState<BalaKandaImportPage> {
  bool _isLoading = false;
  String _statusMessage = '';

  // Bala Kanda Stories Data
  final List<Map<String, dynamic>> _balaKandaStories = [
    {
      'story_number': 1,
      'title': 'The Miracle Baby in Ayodhya',
      'content': '''Once upon a time, in the beautiful kingdom of Ayodhya, the king and queen wished for a child.
The palace glowed with happiness when little Rama was born, his eyes bright like morning stars.
All the people cheered, and flowers seemed to rain from the sky.
Rama smiled, and the city felt peaceful and joyful.''',
      'summary': 'The story of Rama\'s birth in Ayodhya and the joy it brought to everyone.',
      'keywords': ['Rama', 'birth', 'Ayodhya', 'king', 'queen', 'palace', 'joy'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Every child is a blessing and brings joy.',
      'prayer': 'Om Shri Ramaya Namah',
    },
    {
      'story_number': 2,
      'title': 'Baby Rama\'s Smile',
      'content': '''Rama's first smile was magical.
The baby giggled softly, and the royal palace seemed brighter.
The birds outside chirped more sweetly, and the flowers swayed happily in the breeze.
Even the king and queen felt their hearts fill with love.''',
      'summary': 'The magical moment when baby Rama smiled for the first time.',
      'keywords': ['Rama', 'smile', 'magical', 'palace', 'birds', 'flowers', 'love'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'A simple smile can bring happiness to everyone.',
      'prayer': 'Jai Shri Ram',
    },
    {
      'story_number': 3,
      'title': 'Rama and the Playful Monkeys',
      'content': '''Little Rama loved playing in the palace gardens.
One day, a group of playful monkeys joined him, swinging from the trees.
Rama laughed and tried to catch them gently.
The monkeys laughed too, jumping and tumbling — everyone giggled together.''',
      'summary': 'Rama\'s playful adventure with monkeys in the palace garden.',
      'keywords': ['Rama', 'monkeys', 'garden', 'playful', 'trees', 'laughter'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Friendship makes playtime more fun.',
      'prayer': 'Om Shri Ramaya Namah',
    },
    {
      'story_number': 4,
      'title': 'Rama Learns to Bow',
      'content': '''Rama's mother taught him to bow to elders.
At first, little Rama giggled, unsure how to bend.
But he tried carefully, and the elders smiled warmly.
Rama felt proud and happy that he could show love and respect.''',
      'summary': 'Rama learning the important lesson of showing respect to elders.',
      'keywords': ['Rama', 'bow', 'respect', 'elders', 'mother', 'love'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Respect and humility make you shine inside.',
      'prayer': 'Jai Shri Ram',
    },
    {
      'story_number': 5,
      'title': 'Rama and the Mango Tree',
      'content': '''Rama climbed a mango tree with his friends.
He found a big, sweet mango at the top.
Instead of keeping it, he shared it with his friends.
All the friends laughed and enjoyed the juicy fruit together.''',
      'summary': 'Rama learns the joy of sharing with friends.',
      'keywords': ['Rama', 'mango', 'tree', 'friends', 'sharing', 'fruit'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Sharing brings joy to friends.',
      'prayer': 'Om Shri Ramaya Namah',
    },
    {
      'story_number': 6,
      'title': 'Rama\'s First Bow and Arrow',
      'content': '''Little Rama picked up his first bow and arrow.
He aimed carefully at a target and missed at first.
He tried again, and soon the arrow hit the mark!
Rama clapped and smiled — he knew practice made him strong.''',
      'summary': 'Rama\'s first lesson in archery and the importance of practice.',
      'keywords': ['Rama', 'bow', 'arrow', 'target', 'practice', 'strong'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Practice makes you strong and confident.',
      'prayer': 'Jai Shri Ram',
    },
    {
      'story_number': 7,
      'title': 'Rama and the Talking Parrot',
      'content': '''Rama saw a parrot perched on a branch.
The parrot said, "Good morning, little prince!"
Rama listened carefully and answered politely.
He learned how the parrot remembered the songs of the forest and shared them with friends.''',
      'summary': 'Rama\'s encounter with a talking parrot and learning about forest songs.',
      'keywords': ['Rama', 'parrot', 'talking', 'songs', 'forest', 'learning'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Listening carefully helps you learn new things.',
      'prayer': 'Om Shri Ramaya Namah',
    },
    {
      'story_number': 8,
      'title': 'Rama Helps the Little Deer',
      'content': '''A little deer got stuck in the bushes.
Rama carefully helped free it without hurting it.
The deer ran happily, and Rama felt his heart glow with kindness.''',
      'summary': 'Rama\'s act of kindness in helping a trapped deer.',
      'keywords': ['Rama', 'deer', 'help', 'kindness', 'bushes', 'free'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Helping those in need is always good.',
      'prayer': 'Jai Shri Ram',
    },
    {
      'story_number': 9,
      'title': 'Rama and the Playful Clouds',
      'content': '''Rama looked up at the sky and saw clouds dancing.
He imagined them as soft pillows and giggled.
He clapped his hands and the clouds seemed to bounce with him.
Rama laughed, happy to see joy in simple things.''',
      'summary': 'Rama\'s joyful imagination while watching clouds in the sky.',
      'keywords': ['Rama', 'clouds', 'sky', 'imagination', 'joy', 'simple'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Joy can be found even in the sky above.',
      'prayer': 'Om Shri Ramaya Namah',
    },
    {
      'story_number': 10,
      'title': 'Rama\'s First Little Lesson',
      'content': '''Rama's teacher taught him a new word each day.
Little Rama repeated it carefully, trying to get it right.
When he finally said it perfectly, everyone clapped.
Rama's eyes sparkled — learning was fun!''',
      'summary': 'Rama\'s first learning experience and discovering that learning is fun.',
      'keywords': ['Rama', 'teacher', 'learning', 'word', 'lesson', 'fun'],
      'estimated_duration_minutes': 3,
      'difficulty_level': 'Easy',
      'age_range': '3-6',
      'category': 'Bala Kanda',
      'moral': 'Learning something new is always exciting.',
      'prayer': 'Jai Shri Ram',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Bala Kanda Stories'),
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

                // Stories Preview
                _buildStoriesPreview(),
                const SizedBox(height: 32),

                // Import Button
                _buildImportButton(),
                const SizedBox(height: 32),

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
          'Bala Kanda Stories',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Import the first 10 stories of Ramayana - Bala Kanda (Childhood Stories)',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'These stories will replace the hardcoded stories in the home page and will be available for audio playback with your cloned voices.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
                Icons.book,
                color: AppTheme.accentColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Bala Kanda Stories (${_balaKandaStories.length})',
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
            constraints: const BoxConstraints(maxHeight: 400),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _balaKandaStories.length,
              itemBuilder: (context, index) {
                final story = _balaKandaStories[index];
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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${story['estimated_duration_minutes']} min • ${story['difficulty_level']} • ${story['age_range']}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          story['moral'],
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Text(
                      story['prayer'],
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
        ],
      ),
    );
  }

  Widget _buildImportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _importStories,
        icon: _isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.upload),
        label: Text(_isLoading ? 'Importing...' : 'Import Bala Kanda Stories'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
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

  Future<void> _importStories() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    final storiesCount = _balaKandaStories.length;
    
    try {
      print('📚 Starting Bala Kanda stories import...');
      
      // Upload stories to database
      for (int i = 0; i < _balaKandaStories.length; i++) {
        final story = _balaKandaStories[i];
        print('📝 Uploading story ${i + 1}/$storiesCount: ${story['title']}');
        
        // Use upsert to handle existing stories
        await SupabaseService.client
            .from('ramayana_stories')
            .upsert(story, onConflict: 'story_number');
      }
      
      setState(() {
        _statusMessage = 'Successfully imported $storiesCount Bala Kanda stories!';
      });
      
      print('✅ Bala Kanda stories import completed successfully');
      
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
                    '✅ $storiesCount ${storiesCount == 1 ? 'story' : 'stories'} added successfully to Featured and Bala Kanda!',
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
              'Successfully imported $storiesCount Bala Kanda ${storiesCount == 1 ? 'story' : 'stories'} to the database.\n\n'
              'They now appear in Featured Stories and the Bala Kanda category, ready for audio playback with your cloned voices!',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Stay Here'),
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
      print('❌ Error importing Bala Kanda stories: $e');
      setState(() {
        _statusMessage = 'Error importing stories: $e';
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
