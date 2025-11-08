import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LogoVideo extends StatefulWidget {
  final String assetPath;
  final double size;

  const LogoVideo({
    super.key,
    required this.assetPath,
    this.size = 200,
  });

  @override
  State<LogoVideo> createState() => _LogoVideoState();
}

class _LogoVideoState extends State<LogoVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final controller = VideoPlayerController.asset(widget.assetPath);
      await controller.initialize();
      controller.setLooping(false);
      controller.setVolume(0);
      controller.play();
      if (!mounted) return;
      setState(() {
        _controller = controller;
      });
    } catch (_) {
      setState(() {
        _failed = true;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double size = widget.size;
    final borderRadius = BorderRadius.circular(40);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: _failed
            ? Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: borderRadius,
                ),
                child: Image.asset('assets/branding/storyhug_logo.png', fit: BoxFit.contain),
              )
            : (_controller == null
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: borderRadius,
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: _controller!.value.size.width,
                      height: _controller!.value.size.height,
                      child: VideoPlayer(_controller!),
                    ),
                  )),
      ),
    );
  }
}


