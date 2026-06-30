import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../application/emergency_tracking_controller.dart';
import '../../domain/models/emergency_models.dart';
import 'live_ambulance_tracking_map.dart';

/// Mapa de tracking reutilizable (paciente + ambulancia).
class EmergencyTrackingMap extends StatelessWidget {
  final MapController controller;
  final EmergencyRequest request;
  final VoidCallback? onMapReady;
  final EmergencyTrackingController? trackingController;

  const EmergencyTrackingMap({
    super.key,
    required this.controller,
    required this.request,
    this.onMapReady,
    this.trackingController,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => onMapReady?.call());
    return LiveAmbulanceTrackingMap(
      mapController: controller,
      request: request,
      trail: trackingController?.locationTrail ?? const [],
      routePoints: trackingController?.routePoints ?? const [],
      distanceRemainingKm: trackingController?.distanceRemainingKm,
      ambulanceBearing: trackingController?.ambulanceBearing ?? 0,
      followAmbulance: trackingController?.followAmbulance ?? true,
      onFollowChanged: trackingController?.setFollowAmbulance,
    );
  }
}
