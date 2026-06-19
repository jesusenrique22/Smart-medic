import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Fondo animado con burbujas flotantes y partículas (login, headers).
class AnimatedBlobsBackground extends StatefulWidget {
  final List<Color>? colors;
  final Widget? child;

  const AnimatedBlobsBackground({super.key, this.colors, this.child});

  @override
  State<AnimatedBlobsBackground> createState() =>
      _AnimatedBlobsBackgroundState();
}

class _AnimatedBlobsBackgroundState extends State<AnimatedBlobsBackground>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = widget.colors ?? AppColors.loginGradient;

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _floatController]),
      builder: (context, child) {
        final t = _controller.value;
        final f = _floatController.value;
        return Stack(
          fit: StackFit.expand,
          children: [
            // Fondo base con gradiente rico y múltiples stops
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradient.length >= 3
                      ? gradient
                      : [gradient.first, ...gradient, gradient.last],
                  stops: gradient.length >= 3
                      ? const [0.0, 0.45, 1.0]
                      : const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Blob grande superior derecho
            _blob(
              top: -80 + t * 30,
              right: -60 + math.sin(t * math.pi) * 20,
              size: 300,
              opacity: 0.12,
            ),
            // Blob mediano izquierdo
            _blob(
              top: 100 + math.cos(t * math.pi) * 35,
              left: -90,
              size: 220,
              opacity: 0.08,
            ),
            // Blob pequeño inferior derecho
            _blob(
              bottom: 80 - t * 40,
              right: 10,
              size: 160,
              opacity: 0.10,
            ),
            // Blob sutil central superior
            _blob(
              top: 60 + f * 20,
              left: MediaQuery.sizeOf(context).width * 0.35,
              size: 100,
              opacity: 0.06,
            ),
            // Blob inferior izquierdo
            _blob(
              bottom: -30 + f * 15,
              left: 40,
              size: 140,
              opacity: 0.07,
            ),
            // Efecto de brillo en la parte superior (shimmer)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 200,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.07 + t * 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Partículas flotantes pequeñas
            _particle(
              top: 80 + f * 25,
              left: MediaQuery.sizeOf(context).width * 0.15,
              size: 6,
              opacity: 0.15 + f * 0.1,
            ),
            _particle(
              top: 200 + t * 20,
              right: MediaQuery.sizeOf(context).width * 0.2,
              size: 4,
              opacity: 0.12 + t * 0.08,
            ),
            _particle(
              bottom: 200 - f * 15,
              left: MediaQuery.sizeOf(context).width * 0.6,
              size: 8,
              opacity: 0.10 + f * 0.06,
            ),
            if (widget.child != null) widget.child!,
          ],
        );
      },
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

  Widget _particle({
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
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: opacity * 0.5),
              blurRadius: size * 2,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
