import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

import 'geo_math.dart';
import 'geo_point.dart';

/// Rutas por calle vía OSRM (gratuito, sin API key).
class RouteService {
  RouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<RouteResult> fetchDrivingRoute(GeoPoint from, GeoPoint to) async {
    if (!from.isValid || !to.isValid) {
      return RouteResult.straightLineResult(from, to);
    }

    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final resp = await _client.get(url).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) {
        return RouteResult.straightLineResult(from, to);
      }

      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      final routes = body['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return RouteResult.straightLineResult(from, to);
      }

      final route = routes.first as Map<String, dynamic>;
      final coords = route['geometry']?['coordinates'] as List<dynamic>?;
      if (coords == null || coords.isEmpty) {
        return RouteResult.straightLineResult(from, to);
      }

      final points = coords
          .map(
            (c) => GeoPoint(
              latitude: (c[1] as num).toDouble(),
              longitude: (c[0] as num).toDouble(),
            ),
          )
          .toList(growable: false);

      final distanceKm =
          ((route['distance'] as num?)?.toDouble() ?? 0) / 1000;
      final durationSec = (route['duration'] as num?)?.toDouble() ?? 0;
      final etaMinutes = durationSec > 0
          ? math.max(2, (durationSec / 60).round())
          : GeoMath.estimateEtaMinutes(distanceKm);

      return RouteResult(
        points,
        distanceKm: distanceKm,
        etaMinutes: etaMinutes,
      );
    } catch (_) {
      return RouteResult.straightLineResult(from, to);
    }
  }

  static List<GeoPoint> straightLine(GeoPoint from, GeoPoint to) {
    return [from, to];
  }
}

class RouteResult {
  const RouteResult(
    this.points, {
    this.distanceKm,
    this.etaMinutes,
  });

  final List<GeoPoint> points;
  final double? distanceKm;
  final int? etaMinutes;

  factory RouteResult.straightLineResult(GeoPoint from, GeoPoint to) {
    final km = GeoMath.distanceKm(from, to);
    return RouteResult(
      RouteService.straightLine(from, to),
      distanceKm: km,
      etaMinutes: GeoMath.estimateEtaMinutes(km),
    );
  }
}
