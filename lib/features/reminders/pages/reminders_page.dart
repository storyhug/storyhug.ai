import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class RemindersPage extends StatefulWidget {
  const RemindersPage({super.key});

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  bool _bedtimeReminderEnabled = true;
  bool _dailyStoryReminderEnabled = true;
  TimeOfDay _bedtimeReminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay _dailyStoryReminderTime = const TimeOfDay(hour: 19, minute: 0);
  List<String> _selectedDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  final List<String> _weekdays = [
    'Monday',
    'Tuesday', 
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
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

                // Bedtime Reminder
                _buildReminderSection(
                  title: 'Bedtime Stories',
                  subtitle: 'Get reminded to read bedtime stories',
                  icon: Icons.bedtime,
                  enabled: _bedtimeReminderEnabled,
                  onEnabledChanged: (value) => setState(() => _bedtimeReminderEnabled = value),
                  time: _bedtimeReminderTime,
                  onTimeChanged: (time) => setState(() => _bedtimeReminderTime = time),
                  selectedDays: _selectedDays,
                  onDaysChanged: (days) => setState(() => _selectedDays = days),
                ),
                const SizedBox(height: 24),

                // Daily Story Reminder
                _buildReminderSection(
                  title: 'Daily Stories',
                  subtitle: 'Get reminded to discover new stories',
                  icon: Icons.book,
                  enabled: _dailyStoryReminderEnabled,
                  onEnabledChanged: (value) => setState(() => _dailyStoryReminderEnabled = value),
                  time: _dailyStoryReminderTime,
                  onTimeChanged: (time) => setState(() => _dailyStoryReminderTime = time),
                  selectedDays: _selectedDays,
                  onDaysChanged: (days) => setState(() => _selectedDays = days),
                ),
                const SizedBox(height: 32),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveReminders,
                    child: const Text('SAVE REMINDERS'),
                  ),
                ),
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
          'Story Reminders',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Set up reminders to never miss a story time with your child',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white70,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
    required ValueChanged<bool> onEnabledChanged,
    required TimeOfDay time,
    required ValueChanged<TimeOfDay> onTimeChanged,
    required List<String> selectedDays,
    required ValueChanged<List<String>> onDaysChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onEnabledChanged,
                  activeThumbColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          if (enabled) ...[
            const Divider(color: Colors.white24),
            
            // Time Selection
            ListTile(
              title: const Text(
                'Reminder Time',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              subtitle: Text(
                _formatTime(time),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              trailing: const Icon(
                Icons.access_time,
                color: Colors.white70,
              ),
              onTap: () => _selectTime(context, onTimeChanged),
            ),

            const Divider(color: Colors.white24),

            // Days Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Repeat Days',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _weekdays.map((day) {
                      final isSelected = selectedDays.contains(day);
                      return GestureDetector(
                        onTap: () {
                          final newDays = List<String>.from(selectedDays);
                          if (isSelected) {
                            newDays.remove(day);
                          } else {
                            newDays.add(day);
                          }
                          onDaysChanged(newDays);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppTheme.primaryColor 
                                : Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected 
                                  ? AppTheme.primaryColor 
                                  : Colors.white54,
                            ),
                          ),
                          child: Text(
                            day.substring(0, 3), // Show abbreviated day names
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.white70,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: AppTheme.accentColor,
                  size: 24,
                ),
                SizedBox(width: 12),
                Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          _buildActionTile(
            title: 'Test Reminder',
            subtitle: 'Send a test reminder now',
            icon: Icons.send,
            onTap: _testReminder,
          ),
          _buildActionTile(
            title: 'Clear All Reminders',
            subtitle: 'Remove all scheduled reminders',
            icon: Icons.clear_all,
            onTap: _clearAllReminders,
            isDestructive: true,
          ),
        ],
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Future<void> _selectTime(BuildContext context, ValueChanged<TimeOfDay> onTimeChanged) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _bedtimeReminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      onTimeChanged(picked);
    }
  }

  Future<void> _saveReminders() async {
    try {
      // TODO: Save reminders to local storage and schedule notifications
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminders saved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reminders: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _testReminder() async {
    try {
      // TODO: Send test notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test reminder sent!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send test reminder: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _clearAllReminders() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Reminders'),
        content: const Text(
          'Are you sure you want to clear all reminders? This action cannot be undone.',
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
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() {
          _bedtimeReminderEnabled = false;
          _dailyStoryReminderEnabled = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All reminders cleared!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to clear reminders: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
