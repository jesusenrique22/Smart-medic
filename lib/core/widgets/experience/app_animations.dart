import 'package:flutter/material.dart';

/// Curvas y duraciones unificadas para toda la app.
abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 220);
  static const Duration normal = Duration(milliseconds: 380);
  static const Duration slow = Duration(milliseconds: 560);
  static const Duration carousel = Duration(milliseconds: 480);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve bounce = Curves.elasticOut;

  static Duration stagger(int index, {int baseMs = 55}) {
    return Duration(milliseconds: (index * baseMs).clamp(0, 400));
  }
}
