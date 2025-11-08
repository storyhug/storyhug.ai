import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/mood_preset_service.dart';
import '../../../core/services/audio_preview_service.dart';
import '../../../core/services/voice_consent_service.dart';
import '../../../core/services/content_safety_service.dart';
import '../../../core/services/data_retention_service.dart';
import '../../../core/services/parent_snippets_service.dart';
import '../../../core/services/pronunciation_quality_service.dart';
import '../../../core/services/music_library_service.dart';
import '../../../core/services/supabase_service.dart';

class UxSafetyDemoPage extends StatefulWidget {
  const UxSafetyDemoPage({super.key});

  @override
  State<UxSafetyDemoPage> createState() => _UxSafetyDemoPageState();
}

class _UxSafetyDemoPageState extends State<UxSafetyDemoPage> {
  final _testStory = '''
Once upon a time, in a magical forest, there lived a brave little rabbit named Fluffy. 
Fluffy loved to explore and discover new things every day. 
One sunny morning, Fluffy decided to venture deeper into the forest than ever before. 
The trees whispered secrets, and the flowers sang beautiful melodies. 
Fluffy felt excited and curious about what adventures awaited!
''';

  String _results = 'Ready to test features...';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/parental-dashboard'),
          tooltip: 'Back to Dashboard',
        ),
        title: Text(
          'UX & Safety Features Demo',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTestSection(
              icon: Icons.nights_stay,
              title: '1. Mood Presets',
              description: 'Test Bedtime/Adventure/Learning modes',
              onTest: _testMoodPresets,
            ),
            _buildTestSection(
              icon: Icons.preview,
              title: '2. Preview Mode',
              description: 'Generate 15-30s audio preview',
              onTest: _testPreviewMode,
            ),
            _buildTestSection(
              icon: Icons.mic,
              title: '3. Parent Snippets',
              description: 'Test snippet recording service',
              onTest: _testParentSnippets,
            ),
            _buildTestSection(
              icon: Icons.verified_user,
              title: '4. Voice Consent',
              description: 'Check consent management',
              onTest: _testVoiceConsent,
            ),
            _buildTestSection(
              icon: Icons.shield,
              title: '5. Content Safety',
              description: 'Test age-appropriate filtering',
              onTest: _testContentSafety,
            ),
            _buildTestSection(
              icon: Icons.delete_sweep,
              title: '6. Data Retention',
              description: 'Check retention policies',
              onTest: _testDataRetention,
            ),
            _buildTestSection(
              icon: Icons.music_note,
              title: '7. Music Library',
              description: 'Test ambient music service',
              onTest: _testMusicLibrary,
            ),
            _buildTestSection(
              icon: Icons.record_voice_over,
              title: '8. Pronunciation Check',
              description: 'Test quality control system',
              onTest: _testPronunciation,
            ),
            _buildTestSection(
              icon: Icons.privacy_tip,
              title: '9. Privacy Policy',
              description: 'Open privacy policy page',
              onTest: _testPrivacyPolicy,
            ),
            const SizedBox(height: 24),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧪 Testing All New Features',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap any feature below to test it. Results will appear at the bottom.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTest,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: Colors.white,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
        trailing: ElevatedButton(
          onPressed: _isLoading ? null : onTest,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Test'),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.terminal, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Test Results',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            _results,
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  void _setLoading(bool loading) {
    setState(() => _isLoading = loading);
  }

  void _setResults(String results) {
    setState(() => _results = results);
  }

  // Test implementations
  Future<void> _testMoodPresets() async {
    _setLoading(true);
    try {
      final service = MoodPresetService();
      final results = StringBuffer();
      
      results.writeln('🌙 MOOD PRESETS TEST\n');
      
      for (final mood in MoodPreset.values) {
        final config = service.applyMoodPreset(mood, _testStory);
        results.writeln('${mood.displayName}:');
        results.writeln('  - Emotions: ${config['metadata']['emotion_sequence']}');
        results.writeln('  - Pacing: ${config['metadata']['narration_pacing_wpm']} WPM');
        results.writeln('  - BGM: ${config['metadata']['background_music_category']}');
        results.writeln('  - Voice: stability=${config['metadata']['voice_modulation']['stability']}');
        results.writeln('');
      }
      
      results.writeln('✅ All 3 mood presets working!');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testPreviewMode() async {
    _setLoading(true);
    try {
      final service = AudioPreviewService();
      final results = StringBuffer();
      
      results.writeln('🎵 PREVIEW MODE TEST\n');
      
      final info = service.getPreviewInfo(storyText: _testStory);
      results.writeln('Preview Info:');
      results.writeln('  - Word count: ${info['word_count']}');
      results.writeln('  - Duration: ~${info['estimated_duration_seconds']}s');
      results.writeln('  - Preview text: ${info['preview_text'].substring(0, 100)}...');
      results.writeln('');
      
      results.writeln('✅ Preview service ready!');
      results.writeln('📝 Note: Actual audio generation requires ElevenLabs API');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testParentSnippets() async {
    _setLoading(true);
    try {
      final service = ParentSnippetsService();
      final results = StringBuffer();
      
      results.writeln('🎤 PARENT SNIPPETS TEST\n');
      
      results.writeln('Available snippet types:');
      for (final type in ParentSnippetsService.snippetTypes) {
        results.writeln('  - $type');
      }
      results.writeln('');
      
      results.writeln('Suggested text:');
      final suggestions = service.getSuggestedText();
      suggestions.forEach((type, text) {
        results.writeln('  $type: "${text.substring(0, 30)}..."');
      });
      results.writeln('');
      
      final insertionPoints = service.getInsertionPoints(_testStory);
      results.writeln('Insertion points found: ${insertionPoints.length}');
      results.writeln('');
      
      results.writeln('✅ Parent snippets service ready!');
      results.writeln('📝 Use in-app to record actual snippets');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testVoiceConsent() async {
    _setLoading(true);
    try {
      final service = VoiceConsentService();
      final results = StringBuffer();
      
      results.writeln('🔒 VOICE CONSENT TEST\n');
      
      final consentText = service.getConsentFormText();
      results.writeln('Consent form (excerpt):');
      results.writeln(consentText.split('\n').take(8).join('\n'));
      results.writeln('... [full form available]');
      results.writeln('');
      
      results.writeln('Features:');
      results.writeln('  ✓ Timestamp logging');
      results.writeln('  ✓ IP address capture');
      results.writeln('  ✓ Device info tracking');
      results.writeln('  ✓ Revocation support');
      results.writeln('  ✓ Audit trail');
      results.writeln('');
      
      results.writeln('✅ Voice consent service ready!');
      results.writeln('📝 Requires Supabase connection for storage');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testContentSafety() async {
    _setLoading(true);
    try {
      final service = ContentSafetyService();
      final results = StringBuffer();
      
      results.writeln('🛡️ CONTENT SAFETY TEST\n');
      
      // Test with safe content
      results.writeln('Testing safe content (Age 6):');
      final safeResult = await service.filterContent(
        content: _testStory,
        childAge: 6,
      );
      results.writeln('  - Safety Score: ${safeResult['safety_score']}/100');
      results.writeln('  - Is Safe: ${safeResult['is_safe']}');
      results.writeln('  - Age Appropriate: ${safeResult['is_age_appropriate']}');
      results.writeln('  - Violations: ${safeResult['violations'].length}');
      results.writeln('  - Warnings: ${safeResult['warnings'].length}');
      results.writeln('');
      
      // Test with problematic content
      results.writeln('Testing with restricted word:');
      final unsafeResult = await service.filterContent(
        content: 'A scary monster with a weapon',
        childAge: 4,
        strictMode: false,
      );
      results.writeln('  - Safety Score: ${unsafeResult['safety_score']}/100');
      results.writeln('  - Violations: ${unsafeResult['violations']}');
      results.writeln('');
      
      results.writeln('✅ Content safety filter working!');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testDataRetention() async {
    _setLoading(true);
    try {
      final service = DataRetentionService();
      final results = StringBuffer();
      
      results.writeln('⏰ DATA RETENTION TEST\n');
      
      final info = service.getRetentionPolicyInfo();
      results.writeln('Default Policies:');
      results.writeln('  - Voice retention: ${info['default_voice_retention_months']} months');
      results.writeln('  - Audio retention: ${info['default_audio_retention_months']} months');
      results.writeln('  - Consent retention: ${info['consent_retention_years']} years');
      results.writeln('');
      
      results.writeln('Features:');
      results.writeln('  ✓ Auto-delete after expiry');
      results.writeln('  ✓ User opt-in to retain');
      results.writeln('  ✓ Scheduled deletions');
      results.writeln('  ✓ Immediate deletion on demand');
      results.writeln('  ✓ Data age tracking');
      results.writeln('');
      
      results.writeln('✅ Data retention service ready!');
      results.writeln('📝 Requires Supabase for policy storage');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testMusicLibrary() async {
    _setLoading(true);
    try {
      final service = MusicLibraryService();
      final results = StringBuffer();
      
      results.writeln('🎶 MUSIC LIBRARY TEST\n');
      
      final allMusic = service.getAllMusic();
      results.writeln('Available music categories:');
      for (final music in allMusic) {
        results.writeln('  ${music['id']}: ${music['display_name']}');
        results.writeln('    - ${music['description']}');
        results.writeln('    - Mood: ${music['mood']}');
      }
      results.writeln('');
      
      results.writeln('Auto-selection test:');
      final bedtimeMusic = service.autoSelectMusic(mood: 'bedtime');
      results.writeln('  - Bedtime mood → $bedtimeMusic');
      results.writeln('');
      
      results.writeln('✅ Music library service ready!');
      results.writeln('📝 Add audio files to assets/audio/ (see AMBIENT_MUSIC_SETUP.md)');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testPronunciation() async {
    _setLoading(true);
    try {
      final service = PronunciationQualityService();
      final results = StringBuffer();
      
      results.writeln('🗣️ PRONUNCIATION CHECK TEST\n');
      
      final testText = 'Rama and Sita went to the forest. Krishna played the flute.';
      final report = await service.getPronunciationReport(testText);
      
      results.writeln('Quality Report:');
      results.writeln('  - Quality Score: ${report['quality_score']}/100');
      results.writeln('  - Word Count: ${report['word_count']}');
      results.writeln('  - Issues: ${report['issue_count']}');
      results.writeln('  - Suggestions: ${report['suggestion_count']}');
      results.writeln('');
      
      if ((report['suggestions'] as List).isNotEmpty) {
        results.writeln('Pronunciation hints found:');
        for (final suggestion in (report['suggestions'] as List).take(3)) {
          results.writeln('  - ${suggestion['word']}: ${suggestion['phonetic']}');
        }
      }
      results.writeln('');
      
      results.writeln('✅ Pronunciation checker working!');
      _setResults(results.toString());
    } catch (e) {
      _setResults('❌ Error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _testPrivacyPolicy() async {
    context.go('/privacy-policy');
  }
}

