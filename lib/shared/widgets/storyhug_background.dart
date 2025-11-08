import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

/// Reusable StoryHug magical night-sky background
/// Used consistently across all screens for cohesive UX
class StoryHugBackground extends StatefulWidget {
  final Widget child;
  final bool showStars;
  final bool animateStars;
  
  const StoryHugBackground({
    super.key,
    required this.child,
    this.showStars = true,
    this.animateStars = true,
  });

  @override
  State<StoryHugBackground> createState() => _StoryHugBackgroundState();
}

class _StoryHugBackgroundState extends State<StoryHugBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _starController;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF5D5CFD), // Deep twilight blue (top)
            Color(0xFF8B7ED8), // Purple-mid
            Color(0xFFFAD6C4), // Soft peach (bottom)
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          if (widget.showStars)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _starController,
                  builder: (context, child) => CustomPaint(
                    painter: _StarsPainter(
                      time: _starController.value,
                      animate: widget.animateStars,
                    ),
                  ),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );
  }
}

/// Custom painter for magical stars with subtle glow and twinkling
class _StarsPainter extends CustomPainter {
  final double time;
  final bool animate;
  
  _StarsPainter({required this.time, this.animate = false});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistent star positions
    
    // Generate more stars for a richer night sky
    final stars = <Map<String, dynamic>>[];
    for (int i = 0; i < 120; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.8; // Stars in upper 80% where dark blue is
      final brightness = 0.5 + random.nextDouble() * 0.5; // Varying brightness
      final radius = 1.0 + random.nextDouble() * 2.5;
      final twinkleSpeed = 0.8 + random.nextDouble() * 2.2;
      stars.add({
        'pos': Offset(x, y),
        'brightness': brightness,
        'radius': radius,
        'speed': twinkleSpeed,
        'isSparkle': i % 9 == 0, // Every 9th star is a sparkle
      });
    }

    // Draw stars with twinkling effect
    for (final star in stars) {
      final pos = star['pos'] as Offset;
      final baseBrightness = star['brightness'] as double;
      final radius = star['radius'] as double;
      final speed = star['speed'] as double;
      final isSparkle = star['isSparkle'] as bool;
      
      // Calculate twinkling opacity
      double opacity = baseBrightness;
      if (animate) {
        final twinkle = (math.sin(time * speed * math.pi * 2) + 1) / 2;
        opacity = baseBrightness * (0.7 + twinkle * 0.3);
      }
      
      final paint = Paint()..color = Colors.white.withOpacity(opacity);
      final softGlow = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final outerGlow = Paint()
        ..color = Colors.white.withOpacity(opacity * 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      
      // Draw glow layers
      canvas.drawCircle(pos, radius * 3, outerGlow);
      canvas.drawCircle(pos, radius * 1.5, softGlow);
      canvas.drawCircle(pos, radius, paint);
      
      // Sparkle effect for special stars
      if (isSparkle) {
        final sparkleOpacity = opacity * 0.7;
        final sparklePaint = Paint()..color = const Color(0xFFFFD85A).withOpacity(sparkleOpacity);
        final crossLength = radius * 2.5;
        
        // Horizontal sparkle line
        canvas.drawLine(
          Offset(pos.dx - crossLength, pos.dy),
          Offset(pos.dx + crossLength, pos.dy),
          sparklePaint,
        );
        // Vertical sparkle line
        canvas.drawLine(
          Offset(pos.dx, pos.dy - crossLength),
          Offset(pos.dx, pos.dy + crossLength),
          sparklePaint,
        );
        // Diagonal sparkle lines for extra magic
        final diagonalLength = crossLength * 0.707; // sqrt(2)/2 for 45 degrees
        canvas.drawLine(
          Offset(pos.dx - diagonalLength, pos.dy - diagonalLength),
          Offset(pos.dx + diagonalLength, pos.dy + diagonalLength),
          sparklePaint,
        );
        canvas.drawLine(
          Offset(pos.dx - diagonalLength, pos.dy + diagonalLength),
          Offset(pos.dx + diagonalLength, pos.dy - diagonalLength),
          sparklePaint,
        );
      }
    }
    
    // Draw constellation lines (only in upper portion)
    if (animate && time % 1.0 < 0.5) {
      final linePaint = Paint()
        ..color = const Color(0xFFB2E0F7).withOpacity(0.15)
        ..strokeWidth = 0.8;
      
      // Connect nearby stars to form constellations
      for (int i = 0; i < stars.length - 1; i++) {
        final star1 = stars[i]['pos'] as Offset;
        final star2 = stars[i + 1]['pos'] as Offset;
        final distance = (star1 - star2).distance;
        
        // Only connect stars that are close together
        if (distance < size.width * 0.15 && star1.dy < size.height * 0.5) {
          canvas.drawLine(star1, star2, linePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => 
      oldDelegate is! _StarsPainter || animate;
}

/// Glassmorphism card container for content over the magical background
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blur;
  final double opacity;
  
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blur = 20.0,
    this.opacity = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6D62D8).withOpacity(opacity),
                const Color(0xFF8B7ED8).withOpacity(opacity * 0.9),
              ],
            ),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

