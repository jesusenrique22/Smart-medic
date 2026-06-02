import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../config/api_config.dart';

/// Activa panel debug, logs en memoria e icono 🐛 fuera de `flutter run` debug.
///
/// - `flutter run` / simulador: [kDebugMode]
/// - Web por Dev Tunnel: [ApiConfig.openedViaDevTunnel]
/// - Build túnel: `--dart-define=ENABLE_DEV_TOOLS=true` (ver `serve-web-tunnel.sh`)
/// - `.env`: `ENABLE_DEV_TOOLS=true`
class DevToolsConfig {
  DevToolsConfig._();

  static const bool _dartDefineEnabled = bool.fromEnvironment(
    'ENABLE_DEV_TOOLS',
    defaultValue: false,
  );

  static bool get enabled {
    if (kDebugMode) return true;
    if (_dartDefineEnabled) return true;
    if (_envEnabled) return true;
    if (kIsWeb && ApiConfig.openedViaDevTunnel) return true;
    return false;
  }

  static bool get _envEnabled {
    final v = dotenv.env['ENABLE_DEV_TOOLS']?.trim().toLowerCase();
    return v == '1' || v == 'true' || v == 'yes';
  }
}
