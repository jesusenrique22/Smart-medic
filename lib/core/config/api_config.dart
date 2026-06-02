import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  /// True si la app web se abrió desde un Dev Tunnel (Cursor/VS Code), no localhost.
  static bool get openedViaDevTunnel {
    if (!kIsWeb) return false;
    final host = Uri.base.host.toLowerCase();
    return host.contains('devtunnels.ms') ||
        host.contains('github.dev') ||
        host.contains('githubpreview.dev');
  }

  /// Deriva URL del túnel para otro puerto: `…-8088….devtunnels.ms` → `…-3000….devtunnels.ms`
  static String? devTunnelUrlForPort(int port) {
    if (!openedViaDevTunnel) return null;
    final uri = Uri.base;
    final match = RegExp(r'^(.+)-(\d+)\.(.+)$').firstMatch(uri.host);
    if (match == null) return null;
    return '${uri.scheme}://${match.group(1)}-$port.${match.group(3)}';
  }

  static String get baseUrl {
    final tunnelApi = devTunnelUrlForPort(3000);
    if (tunnelApi != null) return tunnelApi;

    if (openedViaDevTunnel) {
      final public = dotenv.env['PUBLIC_API_URL']?.trim();
      if (public != null && public.isNotEmpty) return public;
    }
    return _deviceLoopback(_readUrl('API_BASE_URL', 'http://localhost:3000'));
  }

  /// Gateway Socket.IO (puerto 3001 por defecto).
  static String get socketUrl {
    final tunnelSocket = devTunnelUrlForPort(3001);
    if (tunnelSocket != null) return tunnelSocket;

    if (openedViaDevTunnel) {
      final public = dotenv.env['PUBLIC_SOCKET_URL']?.trim();
      if (public != null && public.isNotEmpty) return public;
    }

    final fromEnv = dotenv.env['SOCKET_URL'];
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return _deviceLoopback(fromEnv);
    }
    final api = _readUrl('API_BASE_URL', 'http://localhost:3000');
    if (api.contains(':3000')) {
      return _deviceLoopback(api.replaceFirst(':3000', ':3001'));
    }
    return _deviceLoopback('$api:3001');
  }

  static String _readUrl(String key, String fallback) {
    final fromEnv = dotenv.env[key];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    return fallback;
  }

  /// Puerto fijo del servidor Flutter web en LAN (ver `scripts/run-web-lan.sh`).
  static int get flutterWebPort {
    final fromEnv = dotenv.env['FLUTTER_WEB_PORT']?.trim();
    return int.tryParse(fromEnv ?? '') ?? 8080;
  }

  /// IP/host del Mac en Wi‑Fi para probar desde otro dispositivo (`.env` → DEV_HOST).
  static String? get devHost {
    final h = dotenv.env['DEV_HOST']?.trim();
    return h != null && h.isNotEmpty ? h : null;
  }

  /// URL para abrir la app en móvil/tablet (misma Wi‑Fi). Requiere [devHost].
  static String? get lanWebAppUrl {
    final host = devHost;
    if (host == null) return null;
    return 'http://$host:$flutterWebPort';
  }

  /// Reescribe localhost/127.0.0.1 → [DEV_HOST] (web, simulador y dispositivo físico).
  static String _deviceLoopback(String url) {
    final uri = Uri.parse(url);
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);

    final hostOverride = devHost;
    final isLoopback =
        uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (hostOverride != null && isLoopback) {
      return '${uri.scheme}://$hostOverride:$port';
    }

    if (kIsWeb) return url;

    try {
      if (Platform.isAndroid) {
        final host = uri.host == 'localhost' || uri.host == '127.0.0.1'
            ? '10.0.2.2'
            : uri.host;
        return uri.replace(host: host).toString();
      }
      if (Platform.isIOS) {
        // Simulador iOS: 127.0.0.1 apunta al Mac host (no uses solo "localhost").
        final host = uri.host == 'localhost' ? '127.0.0.1' : uri.host;
        return uri.replace(host: host).toString();
      }
    } catch (_) {
      // Plataformas sin dart:io
    }
    return url;
  }

  /// STUN por defecto + TURN opcional vía [.env] (mejora audio/video entre redes).
  static List<Map<String, dynamic>> get webRtcIceServers {
    final servers = <Map<String, dynamic>>[
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ];
    final turnUrl = dotenv.env['WEBRTC_TURN_URL']?.trim();
    if (turnUrl == null || turnUrl.isEmpty) return servers;

    final turn = <String, dynamic>{'urls': turnUrl};
    final username = dotenv.env['WEBRTC_TURN_USERNAME']?.trim();
    final credential = dotenv.env['WEBRTC_TURN_CREDENTIAL']?.trim();
    if (username != null && username.isNotEmpty) {
      turn['username'] = username;
      turn['credential'] = credential ?? '';
    }
    servers.add(turn);
    return servers;
  }

  static bool get hasTurnServer =>
      dotenv.env['WEBRTC_TURN_URL']?.trim().isNotEmpty == true;

  /// Origen de la página web; [Uri.origin] solo admite http/https.
  static String get webOriginLabel {
    final base = Uri.base;
    if (base.scheme == 'http' || base.scheme == 'https') return base.origin;
    return base.toString();
  }

  /// Log útil al depurar simulador vs web (solo debug).
  static void logResolvedEndpoints() {
    if (!kDebugMode) return;
    debugPrint('[ApiConfig] API_BASE_URL → $baseUrl');
    debugPrint('[ApiConfig] SOCKET_URL   → $socketUrl');
    if (kIsWeb) debugPrint('[ApiConfig] Origen web   → $webOriginLabel');
    if (openedViaDevTunnel) {
      debugPrint('[ApiConfig] Dev Tunnel   → URLs auto (${devTunnelUrlForPort(3000) ?? "fallback .env"})');
    }
    debugPrint('[ApiConfig] Web (LAN)    → ${lanWebAppUrl ?? "define DEV_HOST o usa Dev Tunnel"}');
    debugPrint('[ApiConfig] WebRTC TURN  → ${hasTurnServer ? "configurado" : "solo STUN"}');
  }
}
