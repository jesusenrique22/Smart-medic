import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../auth/app_session.dart';
import '../navigation/app_routes.dart';
import '../../features/chat/data/chat_socket_service.dart';
import '../../features/chat/presentation/widgets/incoming_call_dialog.dart';

/// Conexión Socket.IO global y manejo de llamadas entrantes.
class AppRealtime {
  AppRealtime._();

  static const _logName = 'AppRealtime';

  static final ChatSocketService chatSocket = ChatSocketService();
  static GlobalKey<NavigatorState>? navigatorKey;
  static bool _incomingListenerAttached = false;
  static String? _showingIncomingForConversationId;
  static IncomingCallEvent? _pendingIncoming;

  static void bindNavigator(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
    _attachIncomingCallListener();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      syncConnectionWithCurrentRoute();
    });
    _tryShowPendingIncomingCall();
  }

  /// Conecta solo fuera de login; desconecta en login o sin sesión.
  static void syncConnectionWithCurrentRoute() {
    final nav = navigatorKey?.currentState;
    if (nav == null) return;
    final route = ModalRoute.of(nav.context)?.settings.name;
    if (!AppSession.isLoggedIn || route == AppRoutes.login) {
      disconnect();
      return;
    }
    connectIfNeeded();
  }

  static void connectIfNeeded() {
    if (!AppSession.isLoggedIn) return;
    chatSocket.connect();
    _attachIncomingCallListener();
  }

  static void disconnect() {
    chatSocket.disconnect();
    _showingIncomingForConversationId = null;
    _pendingIncoming = null;
  }

  static void _attachIncomingCallListener() {
    if (_incomingListenerAttached) return;
    _incomingListenerAttached = true;
    chatSocket.onIncomingCall.listen(_handleIncomingCall);
    developer.log('listener call:incoming activo', name: _logName);
  }

  static void _handleIncomingCall(IncomingCallEvent event) {
    if (event.conversationId.isEmpty) return;
    if (!_shouldHandleIncomingCalls()) {
      _pendingIncoming = null;
      return;
    }

    final nav = navigatorKey?.currentState;
    final currentRoute = nav != null
        ? ModalRoute.of(nav.context)?.settings.name
        : null;
    if (currentRoute == AppRoutes.videoCall) {
      developer.log(
        'ignorando incoming: ya en pantalla de llamada',
        name: _logName,
      );
      return;
    }

    developer.log(
      'call:incoming conv=${event.conversationId} de=${event.callerName} (${event.callerId})',
      name: _logName,
    );
    debugPrint(
      '[AppRealtime] Llamada entrante de ${event.callerName} '
      '(conv=${event.conversationId})',
    );

    _pendingIncoming = event;
    _tryShowPendingIncomingCall();
  }

  static bool _shouldHandleIncomingCalls() {
    if (!AppSession.isLoggedIn) return false;
    final nav = navigatorKey?.currentState;
    if (nav == null) return true;
    final route = ModalRoute.of(nav.context)?.settings.name;
    return route != AppRoutes.login;
  }

  static void _tryShowPendingIncomingCall() {
    final event = _pendingIncoming;
    if (event == null) return;
    if (!_shouldHandleIncomingCalls()) {
      _pendingIncoming = null;
      _showingIncomingForConversationId = null;
      return;
    }

    final nav = navigatorKey?.currentState;
    if (nav == null) {
      developer.log('sin navigator, llamada en cola', name: _logName);
      return;
    }

    final ctx = nav.overlay?.context ?? navigatorKey?.currentContext;
    if (ctx == null || !ctx.mounted) {
      developer.log('sin contexto overlay, llamada en cola', name: _logName);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryShowPendingIncomingCall();
      });
      return;
    }

    if (_showingIncomingForConversationId == event.conversationId) return;
    _showingIncomingForConversationId = event.conversationId;
    _pendingIncoming = null;

    unawaited(_showIncomingDialog(nav, ctx, event));
  }

  static Future<void> _showIncomingDialog(
    NavigatorState nav,
    BuildContext ctx,
    IncomingCallEvent event,
  ) async {
    await IncomingCallDialog.show(
      ctx,
      event: event,
      onReject: () {
        chatSocket.rejectCall(event.conversationId);
        Navigator.of(ctx, rootNavigator: true).pop();
        _showingIncomingForConversationId = null;
      },
      onAccept: () {
        // Solo unirse a la sala; call:accept lo emite la pantalla WebRTC cuando el peer está listo.
        chatSocket.joinCallRoom(event.conversationId);
        Navigator.of(ctx, rootNavigator: true).pop();
        _showingIncomingForConversationId = null;
        nav.pushNamed(
          AppRoutes.videoCall,
          arguments: {
            'conversationId': event.conversationId,
            'peerName': event.callerName,
            'callType': event.callType,
            'isOutgoing': false,
          },
        );
      },
    );

    if (_showingIncomingForConversationId == event.conversationId) {
      _showingIncomingForConversationId = null;
    }
  }
}

/// Mantiene el socket alineado con la ruta (sin conectar en login).
final class RealtimeNavigatorObserver extends NavigatorObserver {
  void _onRouteChanged(Route<dynamic>? route) {
    if (route == null) return;
    AppRealtime.syncConnectionWithCurrentRoute();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _onRouteChanged(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _onRouteChanged(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _onRouteChanged(newRoute);
  }
}
