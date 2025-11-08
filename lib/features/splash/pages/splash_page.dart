import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/supabase_service.dart';
import '../../../shared/widgets/logo_video.dart';
import '../../../shared/widgets/storyhug_background.dart';
import '../../../shared/responsive.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNext();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutBack),
    ));

    _animationController.forward();
  }

  void _navigateToNext() async {
    // Wait for animations to complete, then check authentication
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (mounted) {
      try {
        // Check if user is already authenticated
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          // User is authenticated, go to home page (without child profile for now)
          context.go('/home');
        } else {
          // User is not authenticated, go to welcome page
          context.go('/');
        }
      } catch (e) {
        // If there's an error, go to welcome page
        debugPrint('Error checking auth status: $e');
        context.go('/');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: StoryHugBackground(
        showStars: true,
        animateStars: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate responsive sizes based on screen dimensions
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final logoSize = Responsive.logoSize(context);
            final gapS = Responsive.spacingSmall(context);
            final gapM = Responsive.spacingMedium(context);
            final gapL = Responsive.spacingLarge(context);
            
            // Use vertical bias to center content (0.45 = slightly above center)
            final verticalBias = 0.45;
            
            return SafeArea(
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 1.0,
                  heightFactor: 1.0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gapM),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animated logo video with responsive sizing
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: logoSize,
                                  height: logoSize,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(logoSize * 0.22),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFFD85A).withOpacity(0.6),
                                        blurRadius: logoSize * 0.22,
                                        spreadRadius: logoSize * 0.083,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFFFF8CB3).withOpacity(0.3),
                                        blurRadius: logoSize * 0.11,
                                        spreadRadius: logoSize * 0.028,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(logoSize * 0.22),
                                    child: LogoVideo(
                                      assetPath: 'assets/audio/Logo_animation.mp4',
                                      size: logoSize,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: gapL),
                        
                        // App Name with responsive text size
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'StoryHug.ai',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.09, // ~9% of screen width
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: gapS),
                        
                        // Tagline with responsive text size
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Text(
                                'Your stories, in their voice.\nSweet dreams every night.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04, // ~4% of screen width
                                  color: Colors.white,
                                  height: 1.5,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: gapL + gapM),
                        
                        // Loading Indicator with responsive size
                        AnimatedBuilder(
                          animation: _fadeAnimation,
                          builder: (context, child) {
                            return FadeTransition(
                              opacity: _fadeAnimation,
                              child: Container(
                                padding: EdgeInsets.all(gapS),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: Responsive.widthFraction(context, 0.06, min: 20, max: 28),
                                  height: Responsive.widthFraction(context, 0.06, min: 20, max: 28),
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
