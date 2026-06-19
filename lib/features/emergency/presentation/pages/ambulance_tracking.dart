import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/emergency_tracking_controller.dart';
import '../../domain/models/emergency_models.dart';
import '../widgets/emergency_tracking_map.dart';

class AmbulanceTracking extends StatefulWidget {
  final String emergencyId;
  const AmbulanceTracking({super.key, this.emergencyId = ''});

  @override
  State<AmbulanceTracking> createState() => _AmbulanceTrackingState();
}

class _AmbulanceTrackingState extends State<AmbulanceTracking>
    with TickerProviderStateMixin {
  late final EmergencyTrackingController _controller;
  final MapController _mapController = MapController();

  // Radar / pulse animations for "searching" state
  late final AnimationController _radarController;
  late final AnimationController _pulseController;
  late final AnimationController _dotController;
  late final AnimationController _successController;
  late final Animation<double> _successScale;

  bool _wasRequested = true; // track state change for success anim

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _successScale = CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    );

    _controller = sl<EmergencyTrackingController>();
    _controller.addListener(_onChanged);
    unawaited(AppRealtime.connectIfNeeded());
    unawaited(_controller.start(widget.emergencyId));
  }

  void _onChanged() {
    if (!mounted) return;
    final em = _controller.emergency;
    if (em != null && _wasRequested && em.status != EmergencyStatus.requested) {
      _wasRequested = false;
      _successController.forward(from: 0);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _radarController.dispose();
    _pulseController.dispose();
    _dotController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.emergency.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cancel_outlined, size: 40, color: AppColors.emergency),
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Cancelar solicitud?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Esto cancelará la solicitud de ambulancia. ¿Estás seguro?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Mantener'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.emergency,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await _controller.cancel();
      if (!mounted) return;
      AppNavigation.safeBack(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading && _controller.emergency == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_controller.error != null && _controller.emergency == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(backgroundColor: Colors.transparent),
        body: Center(
          child: Text(_controller.error!, style: const TextStyle(color: Colors.white)),
        ),
      );
    }

    final emergency = _controller.emergency!;
    final isSearching = emergency.status == EmergencyStatus.requested;

    return Stack(
      children: [
        // Map background
        EmergencyTrackingMap(
          controller: _mapController,
          request: emergency,
        ),

        // Dark overlay when searching
        if (isSearching)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
          ),

        // Back button
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: Material(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(50),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => AppNavigation.safeBack(context),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),

        // Main content
        if (isSearching)
          _buildSearchingOverlay(emergency)
        else
          _buildDispatchedSheet(emergency),
      ],
    );
  }

  Widget _buildSearchingOverlay(EmergencyRequest emergency) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Radar animation
          _RadarWidget(
            radarController: _radarController,
            pulseController: _pulseController,
          ),
          const SizedBox(height: 40),
          // Title
          const Text(
            'Buscando ambulancia',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Esperando confirmación del conductor',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              AnimatedBuilder(
                animation: _dotController,
                builder: (_, __) {
                  final dots = _dotController.value > 0.66
                      ? '...'
                      : _dotController.value > 0.33
                          ? '..'
                          : '.';
                  return Text(
                    dots,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          // Info card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.local_hospital_rounded,
                  label: 'Clínica de destino',
                  value: emergency.facility?.name ?? 'Asignando...',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.attach_money_rounded,
                  label: 'Costo estimado',
                  value: emergency.quotedCost != null
                      ? '\$${emergency.quotedCost!.toStringAsFixed(2)}'
                      : 'Calculando...',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.timer_rounded,
                  label: 'ETA estimado',
                  value: '${emergency.etaMinutes ?? '?'} min',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.payment_rounded,
                  label: 'Método de pago',
                  value: emergency.paymentMethod ?? 'Efectivo',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Cancel button
          TextButton.icon(
            onPressed: _controller.cancelling ? null : _cancel,
            icon: _controller.cancelling
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2),
                  )
                : const Icon(Icons.cancel_outlined, color: Colors.white70, size: 18),
            label: const Text(
              'Cancelar solicitud',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDispatchedSheet(EmergencyRequest emergency) {
    final driver = emergency.ambulance?.driver;

    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _successScale,
        builder: (_, child) => Transform.scale(
          scale: 0.9 + (_successScale.value * 0.1),
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _statusGradient(emergency.status),
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_statusIcon(emergency.status), color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      emergency.status.label.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (emergency.etaMinutes != null) ...[ 
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${emergency.etaMinutes} min',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Driver info
                    if (driver != null) ...[
                      Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: AppColors.primaryLight,
                            backgroundImage: driver.profilePic != null
                                ? NetworkImage(driver.profilePic!)
                                : null,
                            child: driver.profilePic == null
                                ? Text(
                                    driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver.name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emergency.ambulance?.displayName ?? 'Unidad asignada',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Call button
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Llamada WebRTC próximamente')),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 28),
                    ],

                    // Facility info
                    if (emergency.facility != null)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.emergency.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_hospital_rounded,
                              color: AppColors.emergency,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Destino',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emergency.facility!.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 20),

                    // Cancel button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _controller.cancelling ? null : _cancel,
                        icon: _controller.cancelling
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancelar solicitud'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emergency,
                          side: const BorderSide(color: AppColors.emergency),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _statusGradient(EmergencyStatus status) {
    return switch (status) {
      EmergencyStatus.dispatched => [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      EmergencyStatus.onScene => [const Color(0xFFF97316), const Color(0xFFEA580C)],
      EmergencyStatus.patientOnboard => [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)],
      EmergencyStatus.enRoute => [const Color(0xFF10B981), const Color(0xFF059669)],
      EmergencyStatus.completed => [const Color(0xFF10B981), const Color(0xFF059669)],
      _ => [AppColors.primary, AppColors.primaryDark],
    };
  }

  IconData _statusIcon(EmergencyStatus status) {
    return switch (status) {
      EmergencyStatus.dispatched => Icons.directions_car_rounded,
      EmergencyStatus.onScene => Icons.location_on_rounded,
      EmergencyStatus.patientOnboard => Icons.airline_seat_flat_angled_rounded,
      EmergencyStatus.enRoute => Icons.speed_rounded,
      EmergencyStatus.completed => Icons.check_circle_rounded,
      _ => Icons.airport_shuttle_rounded,
    };
  }
}

// ── Radar widget ─────────────────────────────────────────────────────────────

class _RadarWidget extends StatelessWidget {
  const _RadarWidget({
    required this.radarController,
    required this.pulseController,
  });

  final AnimationController radarController;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: AnimatedBuilder(
        animation: Listenable.merge([radarController, pulseController]),
        builder: (_, __) {
          return CustomPaint(
            painter: _RadarPainter(
              sweepAngle: radarController.value * 2 * math.pi,
              pulseValue: pulseController.value,
            ),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({required this.sweepAngle, required this.pulseValue});

  final double sweepAngle;
  final double pulseValue;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circles
    for (int i = 1; i <= 4; i++) {
      final r = radius * (i / 4);
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.08 + (i == 4 ? 0.04 : 0))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Radar sweep gradient (sector)
    final sweepPaint = Paint()..shader = SweepGradient(
      startAngle: sweepAngle - math.pi / 3,
      endAngle: sweepAngle,
      colors: [
        Colors.transparent,
        AppColors.emergency.withValues(alpha: 0.0),
        AppColors.emergency.withValues(alpha: 0.55),
      ],
      stops: const [0.0, 0.6, 1.0],
      tileMode: TileMode.clamp,
      transform: GradientRotation(sweepAngle - math.pi / 3),
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Sweep line
    final lineEnd = Offset(
      center.dx + radius * math.cos(sweepAngle),
      center.dy + radius * math.sin(sweepAngle),
    );
    canvas.drawLine(
      center,
      lineEnd,
      Paint()
        ..color = AppColors.emergency.withValues(alpha: 0.8)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Center dot
    canvas.drawCircle(
      center,
      6 + pulseValue * 3,
      Paint()..color = AppColors.emergency,
    );

    // Ambulance icon placeholder (pulsing dot)
    canvas.drawCircle(
      center,
      4,
      Paint()..color = Colors.white,
    );

    // Blips (simulated ambulance positions)
    final blips = [
      Offset(center.dx + radius * 0.45, center.dy - radius * 0.3),
      Offset(center.dx - radius * 0.25, center.dy + radius * 0.5),
    ];
    for (final blip in blips) {
      canvas.drawCircle(
        blip,
        3 + pulseValue * 2,
        Paint()
          ..color = AppColors.primary.withValues(alpha: 0.85)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawCircle(blip, 2.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => true;
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(width: 10),
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
