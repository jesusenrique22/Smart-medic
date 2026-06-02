import 'dart:async';

import 'package:flutter/foundation.dart';

import 'dev_tools_config.dart';

enum RealtimeDebugLevel { info, warn, error, success }

class RealtimeDebugEntry {
  final DateTime at;
  final String tag;
  final RealtimeDebugLevel level;
  final String message;
  final String? detail;

  const RealtimeDebugEntry({
    required this.at,
    required this.tag,
    required this.level,
    required this.message,
    this.detail,
  });

  String get levelLabel => switch (level) {
        RealtimeDebugLevel.info => 'INFO',
        RealtimeDebugLevel.warn => 'WARN',
        RealtimeDebugLevel.error => 'ERROR',
        RealtimeDebugLevel.success => 'OK',
      };

  String formatLine() {
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}:${at.second.toString().padLeft(2, '0')}';
    final base = '[$time] [$levelLabel] [$tag] $message';
    if (detail == null || detail!.isEmpty) return base;
    return '$base\n    $detail';
  }
}

/// Registro en memoria de eventos de red / Socket.IO (solo builds debug).
class RealtimeDebugLog {
  RealtimeDebugLog._();

  static final RealtimeDebugLog instance = RealtimeDebugLog._();

  static const int _maxEntries = 250;

  final List<RealtimeDebugEntry> _entries = [];
  final _updates = StreamController<void>.broadcast();

  Stream<void> get onUpdate => _updates.stream;

  List<RealtimeDebugEntry> get entries =>
      List<RealtimeDebugEntry>.unmodifiable(_entries.reversed);

  void log(
    String tag,
    String message, {
    RealtimeDebugLevel level = RealtimeDebugLevel.info,
    Object? detail,
  }) {
    if (!DevToolsConfig.enabled) return;

    final text = detail?.toString();
    _entries.add(
      RealtimeDebugEntry(
        at: DateTime.now(),
        tag: tag,
        level: level,
        message: message,
        detail: text,
      ),
    );
    while (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    debugPrint('[RealtimeDebug] [$tag] $message${text != null ? ' — $text' : ''}');
    if (!_updates.isClosed) _updates.add(null);
  }

  void clear() {
    _entries.clear();
    if (!_updates.isClosed) _updates.add(null);
  }

  String exportText() => entries.map((e) => e.formatLine()).join('\n\n');
}
