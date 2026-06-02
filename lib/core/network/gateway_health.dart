import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../debug/realtime_debug_log.dart';

class GatewayHealthResult {
  final bool reachable;
  final Uri uri;
  final int? statusCode;
  final String? responseBody;
  final Object? error;
  final Duration elapsed;

  const GatewayHealthResult({
    required this.reachable,
    required this.uri,
    this.statusCode,
    this.responseBody,
    this.error,
    this.elapsed = Duration.zero,
  });

  String get summary {
    if (reachable) {
      final body = responseBody ?? '';
      final preview =
          body.length > 100 ? '${body.substring(0, 100)}…' : body;
      return 'HTTP $statusCode en ${elapsed.inMilliseconds}ms — $preview';
    }
    return error?.toString() ?? 'Sin respuesta';
  }
}

/// Comprueba si el gateway WebSocket responde (GET /health).
Future<bool> isGatewayReachable({
  Duration timeout = const Duration(seconds: 3),
}) async {
  final result = await checkGatewayHealthDetailed(timeout: timeout);
  return result.reachable;
}

Future<GatewayHealthResult> checkGatewayHealthDetailed({
  Duration timeout = const Duration(seconds: 5),
}) async {
  final uri = Uri.parse('${ApiConfig.socketUrl}/health');
  final sw = Stopwatch()..start();
  try {
    final res = await http.get(uri).timeout(timeout);
    sw.stop();
    final ok = res.statusCode == 200;
    final result = GatewayHealthResult(
      reachable: ok,
      uri: uri,
      statusCode: res.statusCode,
      responseBody: res.body,
      elapsed: sw.elapsed,
    );
    RealtimeDebugLog.instance.log(
      'Health',
      ok ? 'Gateway OK' : 'Gateway HTTP ${res.statusCode}',
      level: ok ? RealtimeDebugLevel.success : RealtimeDebugLevel.warn,
      detail: result.summary,
    );
    return result;
  } catch (e, st) {
    sw.stop();
    final result = GatewayHealthResult(
      reachable: false,
      uri: uri,
      error: e,
      elapsed: sw.elapsed,
    );
    RealtimeDebugLog.instance.log(
      'Health',
      'Gateway no alcanzable',
      level: RealtimeDebugLevel.error,
      detail: '$e\n$st',
    );
    return result;
  }
}
