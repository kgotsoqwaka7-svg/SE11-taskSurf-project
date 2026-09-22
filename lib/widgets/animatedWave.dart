import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedWaveHeader extends StatefulWidget {
  final double height;
  final Widget child;

  const AnimatedWaveHeader({
    super.key,
    required this.height,
    required this.child,
  });

  @override
  State<AnimatedWaveHeader> createState() => _AnimatedWaveHeaderState();
}

class _AnimatedWaveHeaderState extends State<AnimatedWaveHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipPath(
                clipper: WaveClipper(_controller.value),
                child: Container(
                  height: widget.height,
                  width: double.infinity,
                  color: const Color(0xFF2859D9),
                ),
              );
            },
          ),

          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;

  WaveClipper(this.animationValue);

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(0, size.height * 0.82);

    for (double x = 0; x <= size.width; x++) {
      final normalizedX = x / size.width;

      final wave = math.sin(
        normalizedX * math.pi * 2 +
            animationValue * math.pi * 2,
      );

      final y = size.height * 0.82 + wave * 8;

      path.lineTo(x, y);
    }

    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) {
    return oldClipper.animationValue != animationValue;
  }
}