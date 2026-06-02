import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../auth/app_session.dart';
import '../config/api_config.dart';
import '../network/gateway_health.dart';
import '../services/app_realtime.dart';
import '../services/active_call_service.dart';
import 'realtime_debug_log.dart';

class DiagnosticLine {
  final String label;
  final String value;
  final bool? ok;

  const DiagnosticLine({required this.label, required this.value, this.ok});
}

/// Pruebas de conectividad API + gateway + socket (para el panel debug).
class GatewayDebugDiagnostics {
  GatewayDebugDiagnostics._();

  static final _log = RealtimeDebugLog.instance;

  static Future<List<DiagnosticLine>> runFullSuite() async {
    _log.log('Diagnostics', 'Iniciando pruebas…', level: RealtimeDebugLevel.info);

    final lines = <DiagnosticLine>[
      ..._environmentLines(),
      ...await _httpLines(),
      ...await _socketLines(),
      ..._callLines(),
      // Sesión al final para reflejar estado tras la prueba socket (sin reset previo).
      ..._sessionLines(),
    ];

    _log.log('Diagnostics', 'Pruebas finalizadas (${lines.length} líneas)',
        level: RealtimeDebugLevel.success);
    return lines;
  }

  static List<DiagnosticLine> _environmentLines() {
    final platform = kIsWeb
        ? 'Web'
        : () {
            try {
              if (Platform.isIOS) return 'iOS';
              if (Platform.isAndroid) return 'Android';
              if (Platform.isMacOS) return 'macOS';
              return Platform.operatingSystem;
            } catch (_) {
              return 'desconocido';
            }
          }();

    return [
      DiagnosticLine(label: 'Plataforma', value: platform),
      DiagnosticLine(label: 'API_BASE_URL', value: ApiConfig.baseUrl),
      DiagnosticLine(label: 'SOCKET_URL', value: ApiConfig.socketUrl),
      DiagnosticLine(
        label: 'PUBLIC_API_URL',
        value: () {
          final u = dotenv.env['PUBLIC_API_URL']?.trim();
          return u != null && u.isNotEmpty ? u : '(vacío — usar en Dev Tunnels)';
        }(),
      ),
      DiagnosticLine(
        label: 'DEV_HOST (.env)',
        value: ApiConfig.devHost ?? '(vacío — necesario para web/móvil en LAN)',
      ),
      DiagnosticLine(
        label: 'URL app (LAN)',
        value: ApiConfig.lanWebAppUrl ?? '(define DEV_HOST + FLUTTER_WEB_PORT)',
      ),
      DiagnosticLine(
        label: 'Puerto web',
        value: '${ApiConfig.flutterWebPort} (FLUTTER_WEB_PORT)',
      ),
    ];
  }

  static List<DiagnosticLine> _callLines() {
    final active = ActiveCallService.instance;
    return [
      DiagnosticLine(
        label: 'WebRTC TURN',
        value: ApiConfig.hasTurnServer
            ? 'Configurado (${dotenv.env['WEBRTC_TURN_URL']?.trim() ?? ""})'
            : 'Solo STUN — llamadas entre redes distintas pueden fallar',
        ok: ApiConfig.hasTurnServer ? true : null,
      ),
      DiagnosticLine(
        label: 'Llamada activa',
        value: active.hasActiveCall
            ? '${active.peerName} (${active.isVideo ? "video" : "audio"}) — ${active.status}'
            : 'Ninguna',
      ),
      DiagnosticLine(
        label: 'Conv. en llamada',
        value: active.hasActiveCall ? active.conversationId : '—',
      ),
    ];
  }

  static List<DiagnosticLine> _sessionLines() {
    final socket = AppRealtime.chatSocket;
    return [
      DiagnosticLine(
        label: 'Sesión',
        value: AppSession.isLoggedIn ? 'Iniciada' : 'No iniciada',
        ok: AppSession.isLoggedIn,
      ),
      DiagnosticLine(
        label: 'Usuario',
        value: AppSession.currentUser?.email ?? '—',
      ),
      DiagnosticLine(
        label: 'Rol',
        value: AppSession.activeRole.name,
      ),
      DiagnosticLine(
        label: 'JWT presente',
        value: AppSession.token != null
            ? 'Sí (${AppSession.token!.length} chars)'
            : 'No',
        ok: AppSession.token != null,
      ),
      DiagnosticLine(
        label: 'Socket conectado',
        value: socket.isConnected ? 'Sí' : 'No',
        ok: socket.isConnected,
      ),
      DiagnosticLine(
        label: 'Socket auth rechazado',
        value: socket.authRejected ? 'Sí (logout + login)' : 'No',
        ok: !socket.authRejected,
      ),
      DiagnosticLine(
        label: 'Último error socket',
        value: socket.lastConnectionError ?? '—',
        ok: socket.lastConnectionError == null,
      ),
    ];
  }

  static Future<List<DiagnosticLine>> _httpLines() async {
    final backendUri = Uri.parse('${ApiConfig.baseUrl}/health');
    final gatewayCheck = await checkGatewayHealthDetailed();

    _log.log(
      'HTTP',
      'Backend ${backendUri.host}:${backendUri.port}',
      level: gatewayCheck.reachable
          ? RealtimeDebugLevel.success
          : RealtimeDebugLevel.warn,
      detail: 'gateway health: ${gatewayCheck.summary}',
    );

    String backendResult;
    bool? backendOk;
    try {
      final sw = Stopwatch()..start();
      final res = await http.get(backendUri).timeout(const Duration(seconds: 5));
      sw.stop();
      backendOk = res.statusCode == 200;
      backendResult =
          'HTTP ${res.statusCode} en ${sw.elapsedMilliseconds}ms — ${res.body.length > 120 ? '${res.body.substring(0, 120)}…' : res.body}';
    } catch (e) {
      backendOk = false;
      backendResult = e.toString();
      _log.log('HTTP', 'Backend no alcanzable', level: RealtimeDebugLevel.error, detail: e);
    }

    return [
      DiagnosticLine(
        label: 'Backend /health',
        value: backendResult,
        ok: backendOk,
      ),
      DiagnosticLine(
        label: 'Gateway /health',
        value: gatewayCheck.summary,
        ok: gatewayCheck.reachable,
      ),
    ];
  }

  static Future<List<DiagnosticLine>> _socketLines() async {
    if (!AppSession.isLoggedIn) {
      return [
        const DiagnosticLine(
          label: 'Prueba socket',
          value: 'Inicia sesión para probar Socket.IO',
          ok: false,
        ),
      ];
    }

    final before = AppRealtime.chatSocket.isConnected;
    _log.log('Socket', 'Intentando connectIfNeeded…');

    await AppRealtime.connectIfNeeded();
    final connected = await AppRealtime.chatSocket.ensureConnected(
      timeout: const Duration(seconds: 12),
    );

    await Future<void>.delayed(const Duration(milliseconds: 500));

    final after = AppRealtime.chatSocket.isConnected || connected;
    final err = AppRealtime.chatSocket.lastConnectionError;

    final ok = after && err == null && !AppRealtime.chatSocket.authRejected;
    _log.log(
      'Socket',
      ok ? 'Conexión establecida' : 'Sin conexión tras espera',
      level: ok ? RealtimeDebugLevel.success : RealtimeDebugLevel.error,
      detail: err,
    );

    return [
      DiagnosticLine(
        label: 'Socket antes',
        value: before ? 'Conectado' : 'Desconectado',
      ),
      DiagnosticLine(
        label: 'Socket después (prueba)',
        value: after ? 'Conectado' : 'Desconectado',
        ok: after,
      ),
      if (err != null)
        DiagnosticLine(label: 'Error', value: err, ok: false),
    ];
  }
}
