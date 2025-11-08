import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/storyhug_branding.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/logo_video.dart';

/// Professional Animated Splash Screen for StoryHug.ai
/// Features:
/// - Brand logo with scale-up + fade-in animation
/// - Smooth gradient background
/// - Auto-navigation after animation completes
class SplashScreenPage extends ConsumerStatefulWidget {
  const SplashScreenPage({super.key});

  @override
  ConsumerState<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends ConsumerState<SplashScreenPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _controller = AnimationController(
      duration: StoryHugBranding.splashDuration,
      vsync: this,
    );

    // Scale animation: starts at 0.8, scales up to 1.0
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    // Fade animation: fades in from 0.0 to 1.0
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    // Start animation
    _controller.forward();

    // Navigate after animation completes
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    await Future.delayed(
      StoryHugBranding.splashDuration + const Duration(milliseconds: 500),
    );

    if (!mounted) return;

    // Check authentication status
    final session = SupabaseService.client.auth.currentSession;
    
    if (session != null) {
      // User is logged in, go to home
      context.go('/home');
    } else {
      // User is not logged in, go to login
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StoryHugBranding.gradientContainer(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const LogoVideo(
                        assetPath: 'assets/audio/Logo_animation.mp4',
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // App Name
                      const Text(
                        'StoryHug',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: StoryHugBranding.textPrimary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Tagline
                      Text(
                        'Your stories, in their voice',
                        style: TextStyle(
                          fontSize: 16,
                          color: StoryHugBranding.textPrimary.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Loading indicator
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            StoryHugBranding.primaryYellow,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
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
}

