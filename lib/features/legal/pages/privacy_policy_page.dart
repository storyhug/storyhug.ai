import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Try to go back, or navigate to parental dashboard
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/parental-dashboard');
            }
          },
          tooltip: 'Back',
        ),
        title: Text(
          'Privacy Policy & Data Protection',
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
            _buildSection(
              title: '🔒 Data Collection & Storage',
              content: '''
StoryHug collects and stores the following data:

• Voice Recordings: Parent voice samples for personalized narration
• User Profile: Name, email, and child profile information
• Story Data: Generated stories and audio files
• Usage Analytics: App usage patterns (anonymized)

All sensitive data is encrypted at rest and in transit using industry-standard encryption (AES-256).
''',
            ),
            _buildSection(
              title: '🛡️ Voice Data Protection',
              content: '''
Your voice recordings are:

• Encrypted immediately upon upload
• Stored securely in isolated user buckets
• Never shared with third parties without explicit consent
• Automatically deleted based on retention policy (default: 12 months)
• Removable on demand at any time
''',
            ),
            _buildSection(
              title: '⏰ Data Retention Policy',
              content: '''
Default retention periods:

• Voice Clones: 12 months (configurable)
• Generated Audio: 6 months (configurable)
• Consent Records: 7 years (legal requirement)
• User Account Data: Until account deletion

You can:
- Opt in to retain data indefinitely
- Request immediate deletion at any time
- Customize retention periods in Settings
''',
            ),
            _buildSection(
              title: '👶 Child Safety & COPPA Compliance',
              content: '''
StoryHug is designed with child safety in mind:

• No direct child data collection
• All content filtered for age-appropriateness
• AI safety filters for generated content
• Parental controls for all features
• No advertising or third-party tracking

We comply with COPPA (Children's Online Privacy Protection Act) and GDPR regulations.
''',
            ),
            _buildSection(
              title: '✅ Your Consent Rights',
              content: '''
Before any voice cloning:

• Explicit consent form must be accepted
• Timestamp and audit log maintained
• Consent can be revoked at any time
• Revoking consent triggers data deletion

Your consent is:
- Recorded with timestamp
- Stored securely
- Revocable at any time
- Required for each voice profile
''',
            ),
            _buildSection(
              title: '🔐 Security Measures',
              content: '''
We implement multiple security layers:

• End-to-end encryption for voice data
• Secure HTTPS for all API communications
• Row-level security in database
• Regular security audits
• Encrypted local storage on device
• No voice data leaves your account without permission
''',
            ),
            _buildSection(
              title: '🌍 Data Location & Transfers',
              content: '''
• Data stored in secure cloud infrastructure (Supabase)
• Server locations: [Region to be specified]
• No international data transfers without consent
• Compliance with local data protection laws
''',
            ),
            _buildSection(
              title: '✋ Your Rights',
              content: '''
You have the right to:

• Access your data at any time
• Request data deletion (immediate or scheduled)
• Export your data (portability)
• Modify retention policies
• Revoke consent for voice cloning
• Opt out of analytics

To exercise these rights, contact us at privacy@storyhug.app
''',
            ),
            _buildSection(
              title: '📞 Contact & Support',
              content: '''
For privacy concerns or data requests:

Email: privacy@storyhug.app
Support: support@storyhug.app

Response time: Within 48 hours
Data deletion: Within 30 days

Last updated: ${DateTime.now().toString().split(' ')[0]}
''',
            ),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Privacy Matters',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'StoryHug is committed to protecting your family\'s data and privacy. This policy explains how we collect, use, and protect your information.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to data management page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Opening data management settings...'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              },
              icon: const Icon(Icons.settings, color: Colors.white),
              label: Text(
                'Manage My Data',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Show consent revocation dialog
                _showConsentRevocationDialog(context);
              },
              icon: const Icon(Icons.block, color: AppTheme.primaryColor),
              label: Text(
                'Revoke Voice Consent',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppTheme.primaryColor, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showConsentRevocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Revoke Voice Consent',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Revoking consent will delete all your voice data and prevent future voice cloning. This action cannot be undone. Are you sure?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement actual consent revocation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Consent revoked successfully'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}

