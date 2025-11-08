import 'package:flutter/material.dart';

class ThemedBackground extends StatelessWidget {
  final Widget child;
  final String assetPath;
  final AlignmentGeometry alignment;

  const ThemedBackground({
    super.key,
    required this.child,
    required this.assetPath,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: alignment,
        ),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x33000000)],
            ),
          ),
        ),
        child,
      ],
    );
  }
}


