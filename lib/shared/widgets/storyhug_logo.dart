import 'package:flutter/material.dart';
import '../../core/theme/storyhug_branding.dart';

/// Reusable StoryHug.ai Logo Widget
/// Use this component consistently across all screens
class StoryHugLogo extends StatelessWidget {
  final double size;
  final bool showShadow;
  final bool showText;
  
  const StoryHugLogo({
    super.key,
    this.size = 120,
    this.showShadow = true,
    this.showText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo Image
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.15),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: StoryHugBranding.primaryYellow.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.15),
            child: Image.asset(
              StoryHugBranding.logoPath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if logo not found
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(size * 0.15),
                  ),
                  child: Icon(
                    Icons.auto_stories,
                    size: size * 0.6,
                    color: StoryHugBranding.primaryYellow,
                  ),
                );
              },
            ),
          ),
        ),
        
        // Optional Text
        if (showText) ...[
          SizedBox(height: size * 0.15),
          Text(
            'StoryHug.ai',
            style: TextStyle(
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
              color: StoryHugBranding.textPrimary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: size * 0.05),
          Text(
            'Personalized stories in your voice',
            style: TextStyle(
              fontSize: size * 0.11,
              color: StoryHugBranding.textPrimary.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Compact Logo for AppBar
class StoryHugLogoCompact extends StatelessWidget {
  final double height;
  
  const StoryHugLogoCompact({
    super.key,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Image.asset(
        StoryHugBranding.logoPath,
        height: height,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            Icons.auto_stories,
            size: height * 0.8,
            color: StoryHugBranding.primaryYellow,
          );
        },
      ),
    );
  }
}

/// Logo Header for Settings/About pages
class StoryHugLogoHeader extends StatelessWidget {
  final String? subtitle;
  
  const StoryHugLogoHeader({
    super.key,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: StoryHugBranding.cardGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: StoryHugBranding.primaryYellow.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                StoryHugBranding.logoPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.white,
                    child: const Icon(
                      Icons.auto_stories,
                      size: 36,
                      color: StoryHugBranding.primaryYellow,
                    ),
                  );
                },
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'StoryHug.ai',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: StoryHugBranding.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      color: StoryHugBranding.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

