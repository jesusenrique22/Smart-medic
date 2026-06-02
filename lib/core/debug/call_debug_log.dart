import 'package:flutter/foundation.dart';

import 'dev_tools_config.dart';
import 'realtime_debug_log.dart';

export 'realtime_debug_log.dart' show RealtimeDebugLevel;

/// Eventos de señalización y WebRTC en [RealtimeDebugLog] (solo debug).
class CallDebugLog {
  CallDebugLog._();

  static final _log = RealtimeDebugLog.instance;
  static int _iceSent = 0;
  static int _iceReceived = 0;

  static void resetIceCounters() {
    _iceSent = 0;
    _iceReceived = 0;
  }

  /// Señalización Socket.IO (invite, offer, answer, etc.).
  static void signal(
    String message, {
    RealtimeDebugLevel level = RealtimeDebugLevel.info,
    Object? detail,
  }) {
    if (!DevToolsConfig.enabled) return;
    _log.log('Call', message, level: level, detail: detail);
  }

  /// Media / peer connection (tracks, ICE state, connection state).
  static void media(
    String message, {
    RealtimeDebugLevel level = RealtimeDebugLevel.info,
    Object? detail,
  }) {
    if (!DevToolsConfig.enabled) return;
    _log.log('WebRTC', message, level: level, detail: detail);
  }

  static void iceSent({String? sdpMid}) {
    if (!DevToolsConfig.enabled) return;
    _iceSent++;
    if (_iceSent == 1 || _iceSent % 5 == 0) {
      signal(
        'ICE local → peer (#$_iceSent)',
        detail: sdpMid != null ? 'sdpMid=$sdpMid' : null,
      );
    }
  }

  static void iceReceived({String? sdpMid}) {
    if (!DevToolsConfig.enabled) return;
    _iceReceived++;
    if (_iceReceived == 1 || _iceReceived % 5 == 0) {
      signal(
        'ICE peer → local (#$_iceReceived)',
        detail: sdpMid != null ? 'sdpMid=$sdpMid' : null,
      );
    }
  }
}
