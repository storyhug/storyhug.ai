import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../services/voice_cloning_service.dart';
import '../../../shared/models/user_voice.dart';

/// Diagnostic page to check voice database status
class VoiceDiagnosticsPage extends StatefulWidget {
  const VoiceDiagnosticsPage({super.key});

  @override
  State<VoiceDiagnosticsPage> createState() => _VoiceDiagnosticsPageState();
}

class _VoiceDiagnosticsPageState extends State<VoiceDiagnosticsPage> {
  final VoiceCloningService _voiceCloningService = VoiceCloningService();
  
  bool _isLoading = true;
  String? _userId;
  List<UserVoice> _voices = [];
  String? _errorMessage;
  Map<String, dynamic>? _rawData;

  @override
  void initState() {
    super.initState();
    _loadDiagnostics();
  }

  Future<void> _loadDiagnostics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _userId = SupabaseService.client.auth.currentUser?.id;
      
      if (_userId != null) {
        // Load voices using the service
        _voices = await _voiceCloningService.getUserVoices(_userId!);
        
        // Load raw data directly from Supabase
        final response = await SupabaseService.client
            .from('user_voices')
            .select('*')
            .eq('user_id', _userId!);
        
        setState(() {
          _rawData = {
            'total_records': (response as List).length,
            'active_records': (response as List).where((v) => v['is_active'] == true).length,
            'inactive_records': (response as List).where((v) => v['is_active'] == false).length,
            'all_records': response,
          };
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'No user logged in';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _errorMessage = 'Error: $e\n\nStack: $stackTrace';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Diagnostics'),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDiagnostics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfo(),
                      const SizedBox(height: 20),
                      _buildVoicesInfo(),
                      const SizedBox(height: 20),
                      _buildRawDataInfo(),
                      const SizedBox(height: 20),
                      if (_errorMessage != null) _buildErrorInfo(),
                      const SizedBox(height: 20),
                      _buildActions(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.person, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Text(
                  'User Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('User ID', _userId ?? 'Not logged in'),
            _buildInfoRow('Email', SupabaseService.client.auth.currentUser?.email ?? 'N/A'),
          ],
        ),
      ),
    );
  }

  Widget _buildVoicesInfo() {
    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.record_voice_over, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Text(
                  'Loaded Voices (from Service)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Total Voices', '${_voices.length}'),
            const SizedBox(height: 12),
            if (_voices.isEmpty)
              const Text(
                'No voices found. This could mean:\n• No voices recorded yet\n• Voices are marked as inactive\n• Database query error',
                style: TextStyle(color: Colors.orange, fontSize: 14),
              )
            else
              ..._voices.map((voice) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  voice.voiceName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: voice.voiceId));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Voice ID copied')),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Voice ID: ${voice.voiceId}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          if (voice.voiceDescription != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              voice.voiceDescription!,
                              style: const TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                          const SizedBox(height: 4),
                          _buildChip('Active: ${voice.isActive}', voice.isActive ? Colors.green : Colors.red),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildRawDataInfo() {
    if (_rawData == null) return const SizedBox.shrink();

    return Card(
      color: Colors.white.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.storage, color: AppTheme.accentColor),
                SizedBox(width: 8),
                Text(
                  'Database Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Total Records', '${_rawData!['total_records']}'),
            _buildInfoRow('Active Records', '${_rawData!['active_records']}'),
            _buildInfoRow('Inactive Records', '${_rawData!['inactive_records']}'),
            const SizedBox(height: 12),
            if (_rawData!['total_records'] != _voices.length)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mismatch! DB has ${_rawData!['active_records']} active records but service loaded ${_voices.length} voices.',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorInfo() {
    return Card(
      color: Colors.red.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SelectableText(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    final hasInactiveVoices = _rawData != null && (_rawData!['inactive_records'] as int) > 0;
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadDiagnostics,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Diagnostics'),
          ),
        ),
        const SizedBox(height: 12),
        if (hasInactiveVoices)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _cleanupInactiveVoices,
              icon: const Icon(Icons.delete_forever),
              label: Text('Delete ${_rawData!['inactive_records']} Inactive Voice(s)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (hasInactiveVoices) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go('/voice-cloning'),
            icon: const Icon(Icons.mic),
            label: const Text('Go to Voice Cloning'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white54),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cleanupInactiveVoices() async {
    if (_userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permanently Delete Inactive Voices?'),
        content: Text(
          'This will permanently delete ${_rawData!['inactive_records']} inactive voice(s) from the database.\n\n'
          'This action cannot be undone, but it will allow you to reuse those voice names.',
        ),
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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _voiceCloningService.cleanupInactiveVoices(_userId!);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inactive voices deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Reload diagnostics
        await _loadDiagnostics();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete inactive voices: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

