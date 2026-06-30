import 'package:flutter/material.dart';

import '../../../../core/geo/geo_point.dart';
import '../../../emergency/domain/models/emergency_models.dart';
import '../../../emergency/presentation/widgets/live_ambulance_tracking_map.dart';

/// Mapa para personal de ambulancia — delega al mapa en vivo profesional.
class AmbulanceEmergencyMap extends StatelessWidget {
  const AmbulanceEmergencyMap({
    super.key,
    required this.request,
    this.trail = const [],
    this.routePoints = const [],
    this.distanceRemainingKm,
    this.ambulanceBearing = 0,
    this.isDriverView = true,
  });

  final EmergencyRequest request;
  final List<GeoPoint> trail;
  final List<GeoPoint> routePoints;
  final double? distanceRemainingKm;
  final double ambulanceBearing;
  final bool isDriverView;

  @override
  Widget build(BuildContext context) {
    return LiveAmbulanceTrackingMap(
      request: request,
      trail: trail,
      routePoints: routePoints,
      distanceRemainingKm: distanceRemainingKm,
      ambulanceBearing: ambulanceBearing,
      isDriverView: isDriverView,
    );
  }
}
