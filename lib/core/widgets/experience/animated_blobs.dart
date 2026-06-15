import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Fondo animado con burbujas flotantes (login, headers).
class AnimatedBlobsBackground extends StatefulWidget {
  final List<Color>? colors;
  final Widget? child;

  const AnimatedBlobsBackground({super.key, this.colors, this.child});

  @override
  State<AnimatedBlobsBackground> createState() =>
      _AnimatedBlobsBackgroundState();
}

class _AnimatedBlobsBackgroundState extends State<AnimatedBlobsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.colors ?? AppColors.loginGradient;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            _blob(
              top: -60 + t * 20,
              right: -50 + math.sin(t * math.pi) * 15,
              size: 220,
              opacity: 0.09,
            ),
            _blob(
              top: 140 + math.cos(t * math.pi) * 25,
              left: -70,
              size: 170,
              opacity: 0.07,
            ),
            _blob(
              bottom: 120 - t * 30,
              right: 20,
              size: 130,
              opacity: 0.08,
            ),
            if (child != null) child,
          ],
        );
      },
      child: widget.child,
    );
  }

  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required double opacity,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
