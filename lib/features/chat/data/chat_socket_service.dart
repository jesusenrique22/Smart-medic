import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/auth/app_session.dart';
import '../../../core/config/api_config.dart';
import '../../../core/debug/call_debug_log.dart';
import '../../../core/debug/realtime_debug_log.dart';
import '../../../core/network/gateway_health.dart';
import 'chat_api_service.dart';

typedef MessageHandler = void Function(Map<String, dynamic> payload);
typedef ConversationUpdateHandler = void Function(Map<String, dynamic> payload);
typedef IncomingCallHandler = void Function(IncomingCallEvent event);

class IncomingCallEvent {
  final String conversationId;
  final String callType;
  final String callerId;
  final String callerName;

  const IncomingCallEvent({
    required this.conversationId,
    required this.callType,
    required this.callerId,
    required this.callerName,
  });
}

/// Cliente Socket.IO para chat en tiempo real y señalización WebRTC.
class ChatSocketService {
  io.Socket? _socket;
  bool _connecting = false;
  bool _authRejected = false;
  String? lastConnectionError;
  DateTime? _lastGatewayUnreachableLog;
  final _debug = RealtimeDebugLog.instance;

  bool get authRejected => _authRejected;
  bool get isConnecting => _connecting;
  Timer? _connectDebounce;
  int _connectGeneration = 0;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _incomingCallController = StreamController<IncomingCallEvent>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _clinicRosterController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<bool> get onConnectionChanged => _connectionController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated =>
      _conversationController.stream;
  Stream<IncomingCallEvent> get onIncomingCall => _incomingCallController.stream;
  Stream<Map<String, dynamic>> get onNotificationNew =>
      _notificationController.stream;
  Stream<Map<String, dynamic>> get onClinicRosterUpdated =>
      _clinicRosterController.stream;

  bool get isConnected => _socket?.connected ?? false;

  /// Espera a que el socket esté listo (p. ej. antes de una llamada).
  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (!AppSession.isLoggedIn || AppSession.token == null) return false;
    if (isConnected) return true;

    final gatewayUp = await isGatewayReachable();
    if (!gatewayUp) {
      debugPrint(
        '[ChatSocket] Gateway no responde en ${ApiConfig.socketUrl}/health',
      );
      return false;
    }

    connect();
    if (isConnected) return true;

    final completer = Completer<bool>();
    late StreamSubscription<bool> sub;
    sub = onConnectionChanged.listen((ok) {
      if (ok && !completer.isCompleted) {
        completer.complete(true);
        unawaited(sub.cancel());
      }
    });

    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete(isConnected);
        unawaited(sub.cancel());
      }
    });

    return completer.future;
  }

  /// En web: polling (XHR). En iOS/Android la librería `socket_io_client` solo
  /// implementa WebSocket en dart:io (`io_transports.dart`). Si se pide solo
  /// `polling`, el cliente abre `ws://` con `transport=polling` y el handshake
  /// hace timeout (HTTP /health sigue funcionando).
  List<String> get _socketTransports {
    if (kIsWeb) return const ['polling'];
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        return const ['websocket'];
      }
    } catch (_) {
      // Plataformas sin dart:io
    }
    return const ['polling', 'websocket'];
  }

  void connect() {
    if (!AppSession.isLoggedIn || AppSession.token == null) return;
    if (_authRejected) return;
    if (_socket?.connected == true) return;

    _connectDebounce?.cancel();
    _connectDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_connectNow());
    });
  }

  Future<void> _connectNow() async {
    if (!AppSession.isLoggedIn || AppSession.token == null) return;
    if (_authRejected) return;
    if (_socket?.connected == true) return;
    if (_connecting) return;

    final url = ApiConfig.socketUrl;
    final gatewayUp = await isGatewayReachable();
    if (!gatewayUp) {
      lastConnectionError = 'Gateway /health no responde en $url';
      _debug.log(
        'ChatSocket',
        lastConnectionError!,
        level: RealtimeDebugLevel.error,
      );
      final now = DateTime.now();
      if (_lastGatewayUnreachableLog == null ||
          now.difference(_lastGatewayUnreachableLog!) >
              const Duration(seconds: 15)) {
        _lastGatewayUnreachableLog = now;
        debugPrint(
          '[ChatSocket] Sin gateway en $url/health — '
          'ejecuta: cd realtime-gateway && pnpm run dev',
        );
      }
      return;
    }

    _tearDownSocket();
    _connecting = true;
    final generation = ++_connectGeneration;
    final token = AppSession.token!;

    debugPrint('[ChatSocket] Conectando a $url …');
    lastConnectionError = null;
    _debug.log('ChatSocket', 'Conectando…', detail: url);

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(_socketTransports)
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .setTimeout(20000)
          .setAuth({'token': token})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        if (generation != _connectGeneration) return;
        _connecting = false;
        lastConnectionError = null;
        developer.log('socket conectado', name: 'ChatSocket');
        debugPrint('[ChatSocket] Conectado a $url');
        _debug.log('ChatSocket', 'Conectado', level: RealtimeDebugLevel.success, detail: url);
        _connectionController.add(true);
      })
      ..onDisconnect((_) {
        if (generation != _connectGeneration) return;
        _connecting = false;
        developer.log('socket desconectado', name: 'ChatSocket');
        _debug.log('ChatSocket', 'Desconectado', level: RealtimeDebugLevel.warn);
        _connectionController.add(false);
      })
      ..onConnectError((err) {
        if (generation != _connectGeneration) return;
        _connecting = false;
        lastConnectionError = err.toString();
        developer.log('connect_error', name: 'ChatSocket', error: err);
        debugPrint('[ChatSocket] Error de conexión ($url): $err');
        _debug.log(
          'ChatSocket',
          'Error de conexión',
          level: RealtimeDebugLevel.error,
          detail: '$url — $err',
        );
        _connectionController.add(false);
        if (_isAuthError(err)) {
          _authRejected = true;
          _debug.log(
            'ChatSocket',
            'Token rechazado — cierra sesión y vuelve a entrar',
            level: RealtimeDebugLevel.error,
          );
          debugPrint(
            '[ChatSocket] Token rechazado; deteniendo reconexiones hasta nuevo login.',
          );
        }
        _tearDownSocket(disableReconnection: _authRejected);
      })
      ..on('message:new', (data) {
        if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('conversation:updated', (data) {
        if (data is Map) {
          _conversationController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('call:incoming', (data) {
        if (data is! Map) return;
        final map = Map<String, dynamic>.from(data);
        final event = IncomingCallEvent(
          conversationId: map['conversationId']?.toString() ?? '',
          callType: map['callType']?.toString() ?? 'video',
          callerId: map['callerId']?.toString() ?? '',
          callerName: map['callerName']?.toString() ?? 'Usuario',
        );
        developer.log('call:incoming ${event.conversationId}', name: 'ChatSocket');
        CallDebugLog.signal(
          'call:incoming de ${event.callerName}',
          level: RealtimeDebugLevel.success,
          detail: 'conv=${event.conversationId} tipo=${event.callType}',
        );
        _incomingCallController.add(event);
      })
      ..on('notification:new', (data) {
        if (data is Map) {
          _notificationController.add(Map<String, dynamic>.from(data));
        }
      })
      ..on('clinic:roster:updated', (data) {
        if (data is Map) {
          _clinicRosterController.add(Map<String, dynamic>.from(data));
        }
      });

    _socket!.connect();
  }

  bool _isAuthError(dynamic err) {
    if (err is Map) {
      final message = err['message']?.toString() ?? '';
      if (message.contains('Token inválido') ||
          message.toLowerCase().contains('invalid token') ||
          message.toLowerCase().contains('jwt')) {
        return true;
      }
    }
    final text = err?.toString() ?? '';
    return text.contains('Token inválido') ||
        text.toLowerCase().contains('invalid token');
  }

  void _tearDownSocket({bool disableReconnection = false}) {
    _connectDebounce?.cancel();
    final s = _socket;
    _socket = null;
    if (s != null) {
      try {
        if (disableReconnection) {
          s.io.options?['reconnection'] = false;
        }
        s.disconnect();
        s.dispose();
      } catch (_) {
        // ignore
      }
    }
  }

  void disconnect() {
    _connecting = false;
    _connectGeneration++;
    _tearDownSocket();
    _connectionController.add(false);
  }

  /// Limpia el bloqueo por JWT inválido (p. ej. tras login o hot restart con sesión nueva).
  void resetAuthState() {
    _authRejected = false;
    lastConnectionError = null;
    _debug.log('ChatSocket', 'Estado auth reseteado');
  }

  void joinConversation(String conversationId) {
    _socket?.emit('conversation:join', conversationId);
  }

  void leaveConversation(String conversationId) {
    _socket?.emit('conversation:leave', conversationId);
  }

  Future<ChatMessageItem?> sendMessage({
    required String conversationId,
    required String text,
    String kind = 'chat',
  }) async {
    final completer = Completer<ChatMessageItem?>();
    _socket?.emitWithAck(
      'message:send',
      {'conversationId': conversationId, 'text': text, 'kind': kind},
      ack: (data) {
        if (data is Map && data['ok'] == true && data['message'] is Map) {
          completer.complete(
            ChatMessageItem.fromJson(
              Map<String, dynamic>.from(data['message'] as Map),
            ),
          );
        } else {
          completer.complete(null);
        }
      },
    );
    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => null,
    );
  }

  void inviteCall({
    required String conversationId,
    required String callType,
    required String callerName,
  }) {
    CallDebugLog.signal(
      'call:invite →',
      detail: 'conv=$conversationId tipo=$callType',
    );
    _socket?.emit('call:invite', {
      'conversationId': conversationId,
      'callType': callType,
      'callerName': callerName,
    });
  }

  void acceptCall(String conversationId) {
    CallDebugLog.signal('call:accept →', detail: 'conv=$conversationId');
    _socket?.emit('call:accept', {'conversationId': conversationId});
  }

  /// Entra a la sala de señalización WebRTC (debe coincidir con el backend).
  void joinCallRoom(String conversationId) {
    CallDebugLog.signal('call:join →', detail: 'conv=$conversationId');
    _socket?.emit('call:join', {'conversationId': conversationId});
  }

  void leaveCallRoom(String conversationId) {
    CallDebugLog.signal('call:leave →', detail: 'conv=$conversationId');
    _socket?.emit('call:leave', {'conversationId': conversationId});
  }

  void rejectCall(String conversationId) {
    CallDebugLog.signal(
      'call:reject →',
      level: RealtimeDebugLevel.warn,
      detail: 'conv=$conversationId',
    );
    _socket?.emit('call:reject', {'conversationId': conversationId});
  }

  void sendOffer({
    required String conversationId,
    required Map<String, dynamic> sdp,
    required String callType,
  }) {
    CallDebugLog.signal(
      'call:offer →',
      detail: 'conv=$conversationId tipo=$callType',
    );
    _socket?.emit('call:offer', {
      'conversationId': conversationId,
      'sdp': sdp,
      'callType': callType,
    });
  }

  void sendAnswer({
    required String conversationId,
    required Map<String, dynamic> sdp,
  }) {
    CallDebugLog.signal('call:answer →', detail: 'conv=$conversationId');
    _socket?.emit('call:answer', {
      'conversationId': conversationId,
      'sdp': sdp,
    });
  }

  void sendIceCandidate({
    required String conversationId,
    required Map<String, dynamic> candidate,
  }) {
    CallDebugLog.iceSent(sdpMid: candidate['sdpMid']?.toString());
    _socket?.emit('call:ice', {
      'conversationId': conversationId,
      'candidate': candidate,
    });
  }

  void endCall(String conversationId) {
    CallDebugLog.signal(
      'call:end →',
      level: RealtimeDebugLevel.warn,
      detail: 'conv=$conversationId',
    );
    _socket?.emit('call:end', {'conversationId': conversationId});
  }

  void onCallAccepted(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:accepted', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        CallDebugLog.signal(
          'call:accepted ←',
          level: RealtimeDebugLevel.success,
          detail: 'conv=${map['conversationId']}',
        );
        handler(map);
      }
    });
  }

  void onCallOffer(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:offer', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        CallDebugLog.signal(
          'call:offer ←',
          detail: 'conv=${map['conversationId']} tipo=${map['callType'] ?? "?"}',
        );
        handler(map);
      }
    });
  }

  void onCallAnswer(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:answer', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        CallDebugLog.signal(
          'call:answer ←',
          level: RealtimeDebugLevel.success,
          detail: 'conv=${map['conversationId']}',
        );
        handler(map);
      }
    });
  }

  void onCallIce(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:ice', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        final c = map['candidate'];
        if (c is Map) {
          CallDebugLog.iceReceived(sdpMid: c['sdpMid']?.toString());
        }
        handler(map);
      }
    });
  }

  void onCallEnded(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:ended', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        CallDebugLog.signal(
          'call:ended ←',
          level: RealtimeDebugLevel.warn,
          detail: 'conv=${map['conversationId']}',
        );
        handler(map);
      }
    });
  }

  void onCallRejected(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:rejected', (data) {
      if (data is Map) {
        final map = Map<String, dynamic>.from(data);
        CallDebugLog.signal(
          'call:rejected ←',
          level: RealtimeDebugLevel.warn,
          detail: 'conv=${map['conversationId']}',
        );
        handler(map);
      }
    });
  }

  void offCallEvents() {
    _socket?.off('call:accepted');
    _socket?.off('call:offer');
    _socket?.off('call:answer');
    _socket?.off('call:ice');
    _socket?.off('call:ended');
    _socket?.off('call:rejected');
  }
}
