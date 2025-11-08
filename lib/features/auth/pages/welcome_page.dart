import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/responsive.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double gapS = Responsive.spacingSmall(context);
    final double gapM = Responsive.spacingMedium(context);
    final double gapL = Responsive.spacingLarge(context);
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final screenHeight = constraints.maxHeight;
              final logoSize = Responsive.logoSize(context);
              final topGap = screenHeight * 0.08;
              final bottomGap = screenHeight * 0.06;
              
              return Padding(
                padding: EdgeInsets.all(gapM),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: topGap),
                      // App Logo - StoryHug Logo (responsive size with rounded corners)
                      Center(
                        child: Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(logoSize * 0.3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.2),
                                blurRadius: logoSize * 0.14,
                                offset: Offset(0, logoSize * 0.07),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(logoSize * 0.3),
                            child: Image.asset(
                              'assets/branding/storyhug_logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to icon if logo fails to load
                                return Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(logoSize * 0.3),
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  child: Icon(
                                    Icons.auto_stories,
                                    size: logoSize * 0.5,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: gapL),
                      // Main Slogan with responsive text size
                      Text(
                        'Your stories, in their voice.\nSweet dreams every night.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.06, // ~6% of screen width
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: gapM),
                      // Features with responsive text size
                      Text(
                        'Endless Stories • Hear Mom/Dad\'s Voice • Learn & Imagine',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: screenWidth * 0.037, // ~3.7% of screen width
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: gapL),
                      // Feature highlights
                      _buildFeatureHighlight(
                        icon: Icons.library_books,
                        title: 'Endless Stories',
                        description: 'Moral tales, Indian mythology, and adventures',
                      ),
                      SizedBox(height: gapM),
                      _buildFeatureHighlight(
                        icon: Icons.record_voice_over,
                        title: 'Hear Mom/Dad\'s Voice',
                        description: 'AI voice cloning for personalized storytelling',
                      ),
                      SizedBox(height: gapM),
                      _buildFeatureHighlight(
                        icon: Icons.auto_awesome,
                        title: 'Learn & Imagine',
                        description: 'Educational content that sparks creativity',
                      ),
                      SizedBox(height: bottomGap),
                      // CTA Button with responsive height
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.07 < 56 ? 56 : screenHeight * 0.07,
                        child: ElevatedButton(
                          onPressed: () => context.go('/auth'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'BEGIN THE MAGIC',
                            style: TextStyle(
                              fontSize: screenWidth * 0.042, // ~4.2% of screen width
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: gapM),
                      // Terms and Privacy
                      TextButton(
                        onPressed: () {
                          // TODO: Show terms and privacy policy
                        },
                        child: Text(
                          'Terms & Privacy Policy',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: screenWidth * 0.035, // ~3.5% of screen width
                          ),
                        ),
                      ),
                      SizedBox(height: bottomGap * 0.5),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeatureHighlight({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.accentColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
