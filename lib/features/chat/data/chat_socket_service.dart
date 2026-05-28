import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../core/auth/app_session.dart';
import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
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
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _conversationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _incomingCallController = StreamController<IncomingCallEvent>.broadcast();

  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  Stream<Map<String, dynamic>> get onConversationUpdated =>
      _conversationController.stream;
  Stream<IncomingCallEvent> get onIncomingCall => _incomingCallController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    if (!AppSession.isLoggedIn || AppSession.token == null) return;
    if (ApiClient.isInConnectionCooldown) return;
    if (_socket?.connected == true) return;

    _socket?.dispose();

    _socket = io.io(
      ApiConfig.socketUrl,
      io.OptionBuilder()
          // En web solo polling: evita "websocket error" en hot restart / DevTools.
          .setTransports(kIsWeb ? ['polling'] : ['websocket', 'polling'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setAuth({'token': AppSession.token})
          .build(),
    );

    _socket!
      ..onConnect((_) {
        developer.log('socket conectado', name: 'ChatSocket');
        debugPrint('[ChatSocket] Conectado a ${ApiConfig.socketUrl}');
      })
      ..onDisconnect((_) {
        developer.log('socket desconectado', name: 'ChatSocket');
      })
      ..onConnectError((err) {
        developer.log('connect_error', name: 'ChatSocket', error: err);
        debugPrint('[ChatSocket] Error de conexión: $err');
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
        _incomingCallController.add(event);
      });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
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
    _socket?.emit('call:invite', {
      'conversationId': conversationId,
      'callType': callType,
      'callerName': callerName,
    });
  }

  void acceptCall(String conversationId) {
    _socket?.emit('call:accept', {'conversationId': conversationId});
  }

  /// Entra a la sala de señalización WebRTC (debe coincidir con el backend).
  void joinCallRoom(String conversationId) {
    _socket?.emit('call:join', {'conversationId': conversationId});
  }

  void leaveCallRoom(String conversationId) {
    _socket?.emit('call:leave', {'conversationId': conversationId});
  }

  void rejectCall(String conversationId) {
    _socket?.emit('call:reject', {'conversationId': conversationId});
  }

  void sendOffer({
    required String conversationId,
    required Map<String, dynamic> sdp,
    required String callType,
  }) {
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
    _socket?.emit('call:answer', {
      'conversationId': conversationId,
      'sdp': sdp,
    });
  }

  void sendIceCandidate({
    required String conversationId,
    required Map<String, dynamic> candidate,
  }) {
    _socket?.emit('call:ice', {
      'conversationId': conversationId,
      'candidate': candidate,
    });
  }

  void endCall(String conversationId) {
    _socket?.emit('call:end', {'conversationId': conversationId});
  }

  void onCallAccepted(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:accepted', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onCallOffer(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:offer', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onCallAnswer(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:answer', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onCallIce(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:ice', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onCallEnded(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:ended', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
    });
  }

  void onCallRejected(void Function(Map<String, dynamic>) handler) {
    _socket?.on('call:rejected', (data) {
      if (data is Map) handler(Map<String, dynamic>.from(data));
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
