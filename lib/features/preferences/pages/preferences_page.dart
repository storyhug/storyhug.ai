import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/storyhug_background.dart';

class PreferencesPage extends StatefulWidget {
  const PreferencesPage({super.key});

  @override
  State<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends State<PreferencesPage> {
  bool _notificationsEnabled = true;
  bool _autoPlayEnabled = false;
  bool _downloadOnWifiOnly = true;
  double _volumeLevel = 0.8;
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Dark';

  final List<String> _languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali'];
  final List<String> _themes = ['Dark', 'Light', 'Auto'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/parental-dashboard'),
        ),
      ),
      body: StoryHugBackground(
        showStars: true,
        animateStars: true,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // StoryHug Logo and Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/branding/storyhug_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              child: const Icon(
                                Icons.settings,
                                size: 40,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'StoryHug Settings',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Your stories, in their voice',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Audio Settings
                _buildSection(
                  title: 'Audio Settings',
                  icon: Icons.volume_up,
                  children: [
                    _buildSwitchTile(
                      title: 'Auto-play Stories',
                      subtitle: 'Automatically start playing stories',
                      value: _autoPlayEnabled,
                      onChanged: (value) => setState(() => _autoPlayEnabled = value),
                    ),
                    _buildSliderTile(
                      title: 'Default Volume',
                      subtitle: 'Set default playback volume',
                      value: _volumeLevel,
                      onChanged: (value) => setState(() => _volumeLevel = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Download Settings
                _buildSection(
                  title: 'Download Settings',
                  icon: Icons.download,
                  children: [
                    _buildSwitchTile(
                      title: 'Wi-Fi Only Downloads',
                      subtitle: 'Only download stories when connected to Wi-Fi',
                      value: _downloadOnWifiOnly,
                      onChanged: (value) => setState(() => _downloadOnWifiOnly = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Notification Settings
                _buildSection(
                  title: 'Notifications',
                  icon: Icons.notifications,
                  children: [
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Receive notifications about new stories',
                      value: _notificationsEnabled,
                      onChanged: (value) => setState(() => _notificationsEnabled = value),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // App Settings
                _buildSection(
                  title: 'App Settings',
                  icon: Icons.settings,
                  children: [
                    _buildDropdownTile(
                      title: 'Language',
                      subtitle: 'Select your preferred language',
                      value: _selectedLanguage,
                      items: _languages,
                      onChanged: (value) => setState(() => _selectedLanguage = value!),
                    ),
                    _buildDropdownTile(
                      title: 'Theme',
                      subtitle: 'Choose your preferred theme',
                      value: _selectedTheme,
                      items: _themes,
                      onChanged: (value) => setState(() => _selectedTheme = value!),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Account Settings
                _buildSection(
                  title: 'Account',
                  icon: Icons.person,
                  children: [
                    _buildActionTile(
                      title: 'Sign Out',
                      subtitle: 'Sign out of your account',
                      icon: Icons.logout,
                      onTap: _signOut,
                    ),
                    _buildActionTile(
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account',
                      icon: Icons.delete_forever,
                      onTap: _deleteAccount,
                      isDestructive: true,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _savePreferences,
                    child: const Text('SAVE PREFERENCES'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: AppTheme.accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.volume_down,
                color: Colors.white70,
                size: 20,
              ),
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              const Icon(
                Icons.volume_up,
                color: Colors.white70,
                size: 20,
              ),
            ],
          ),
          Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppTheme.surfaceColor,
        items: items.map((item) => DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: const TextStyle(color: Colors.white),
          ),
        )).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppTheme.errorColor : Colors.white70,
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorColor : Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.white54,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  Future<void> _savePreferences() async {
    try {
      // TODO: Save preferences to SharedPreferences or Supabase
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    try {
      await SupabaseService.client.auth.signOut();
      if (mounted) {
        context.go('/auth');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // TODO: Implement account deletion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deletion functionality coming soon!'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
