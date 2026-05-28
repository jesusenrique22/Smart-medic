import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/auth/app_session.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/services/app_realtime.dart';
import '../../../../core/widgets/responsive_scaffold.dart';
import '../../data/webrtc_call_controller.dart';

/// Llamada de voz o video (WebRTC) entre paciente y médico.
class WebRtcCallPage extends StatefulWidget {
  const WebRtcCallPage({super.key, this.initialArgs});

  /// Argumentos pasados desde [AppRoutes.videoCall] (nunca leer ModalRoute en el State).
  final Map<String, dynamic>? initialArgs;

  @override
  State<WebRtcCallPage> createState() => _WebRtcCallPageState();
}

class _WebRtcCallPageState extends State<WebRtcCallPage> {
  static const _logName = 'WebRtcCallPage';

  WebRtcCallController? _call;
  StreamSubscription<String>? _statusSub;
  bool _hangUpInProgress = false;
  bool _callCleanedUp = false;
  bool _setupStarted = false;
  int _setupGeneration = 0;
  bool _muted = false;
  bool _cameraOff = false;
  bool _initializing = true;
  String? _error;
  String _status = 'Conectando…';

  /// Cacheados en [initState] — no usar [BuildContext] en [dispose].
  late final String _conversationId;
  late final String _peerName;
  late final bool _isVideo;
  late final bool _isOutgoing;
  @override
  void initState() {
    super.initState();
    final args = widget.initialArgs ?? const <String, dynamic>{};
    _conversationId = args['conversationId']?.toString() ?? '';
    _peerName = args['peerName']?.toString() ?? 'Consulta';
    _isVideo = (args['callType'] as String? ?? 'video') != 'audio';
    _isOutgoing = args['isOutgoing'] as bool? ?? true;
    developer.log(
      'init conv=$_conversationId outgoing=$_isOutgoing video=$_isVideo',
      name: _logName,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_setupStarted) return;
    _setupStarted = true;
    unawaited(_setup());
  }

  Future<void> _setup() async {
    final generation = ++_setupGeneration;

    if (_conversationId.isEmpty) {
      if (!mounted || generation != _setupGeneration) return;
      setState(() {
        _error = 'Conversación no válida';
        _initializing = false;
      });
      return;
    }

    AppRealtime.connectIfNeeded();

    if (!AppRealtime.chatSocket.isConnected) {
      if (!mounted || generation != _setupGeneration) return;
      setState(() {
        _error =
            'Sin conexión al servidor. Inicia el backend (cd backend && pnpm run dev) y vuelve a intentar.';
        _initializing = false;
      });
      return;
    }

    AppRealtime.chatSocket.joinConversation(_conversationId);
    AppRealtime.chatSocket.joinCallRoom(_conversationId);

    final call = WebRtcCallController(
      socket: AppRealtime.chatSocket,
      conversationId: _conversationId,
    );

    try {
      await call.init();
      if (!mounted || generation != _setupGeneration) {
        await call.dispose();
        return;
      }

      _statusSub = call.statusStream.listen((s) {
        developer.log('status=$s', name: _logName);
        if (!mounted || _hangUpInProgress) return;
        if (s == 'ended' || s == 'rejected') {
          unawaited(_hangUpLocal(navigateBack: true, reason: 'remote_$s'));
        } else if (s == 'connected') {
          setState(() => _status = 'En llamada');
        }
      });

      if (_isOutgoing) {
        final callType = _isVideo ? 'video' : 'audio';
        await call.startOutgoingCall(
          video: _isVideo,
          callType: callType,
        );
        call.sendOutgoingInvite(
          callerName: AppSession.currentUser?.name ?? 'Usuario',
          callType: callType,
        );
      } else {
        await call.acceptIncomingCall(
          video: _isVideo,
          callType: _isVideo ? 'video' : 'audio',
        );
      }

      if (!mounted || generation != _setupGeneration) {
        await call.dispose();
        return;
      }
      setState(() {
        _call = call;
        _initializing = false;
        _status = 'Llamando…';
      });
    } catch (e, st) {
      developer.log('setup error', name: _logName, error: e, stackTrace: st);
      debugPrint('[WebRTC] Error al iniciar llamada: $e\n$st');
      await call.dispose();
      if (!mounted || generation != _setupGeneration) return;
      final msg = e.toString();
      setState(() {
        _error = msg.contains('Permisos') || msg.contains('Permission')
            ? 'Permite cámara y micrófono para usar llamadas.'
            : msg;
        _initializing = false;
      });
    }
  }

  Future<void> _cleanupCallResources({
    required String reason,
    bool notifyPeer = false,
  }) async {
    if (_callCleanedUp) return;

    developer.log('cleanup reason=$reason notifyPeer=$notifyPeer', name: _logName);
    await _statusSub?.cancel();
    _statusSub = null;

    final call = _call;
    _call = null;

    try {
      if (call != null) {
        if (notifyPeer) call.hangUp();
        await call.dispose();
      } else if (notifyPeer && _conversationId.isNotEmpty) {
        AppRealtime.chatSocket.endCall(_conversationId);
      }
      if (_conversationId.isNotEmpty) {
        AppRealtime.chatSocket.leaveCallRoom(_conversationId);
        AppRealtime.chatSocket.leaveConversation(_conversationId);
      }
      _callCleanedUp = true;
    } catch (e, st) {
      developer.log('cleanup error', name: _logName, error: e, stackTrace: st);
      debugPrint('[WebRTC] ERROR al cancelar/colgar llamada: $e\n$st');
    }
  }

  Future<void> _hangUpLocal({
    bool navigateBack = false,
    String reason = 'user',
  }) async {
    if (_hangUpInProgress) {
      developer.log('colgar ignorado (ya en curso) reason=$reason', name: _logName);
      return;
    }
    _hangUpInProgress = true;
    _setupGeneration++;
    developer.log('colgar inicio reason=$reason navigateBack=$navigateBack', name: _logName);

    final notifyPeer = reason == 'user' || reason == 'back_button';

    await _cleanupCallResources(reason: reason, notifyPeer: notifyPeer);

    if (navigateBack && mounted) {
      AppNavigation.safeBack(context);
    }
  }

  @override
  void dispose() {
    developer.log('dispose página conv=$_conversationId', name: _logName);
    _setupGeneration++;
    unawaited(_statusSub?.cancel());
    if (!_callCleanedUp) {
      final call = _call;
      _call = null;
      final convId = _conversationId;
      unawaited(() async {
        try {
          if (call != null) {
            call.hangUp();
            await call.dispose();
          } else if (convId.isNotEmpty) {
            AppRealtime.chatSocket.endCall(convId);
          }
          if (convId.isNotEmpty) {
            AppRealtime.chatSocket.leaveCallRoom(convId);
            AppRealtime.chatSocket.leaveConversation(convId);
          }
        } catch (e, st) {
          debugPrint('[WebRTC] dispose cleanup: $e\n$st');
        }
      }());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _hangUpLocal(navigateBack: true, reason: 'back_button');
      },
      child: ResponsiveScaffold(
        hideNavigation: true,
        backgroundColor: Colors.black,
        title: Text(_isVideo ? 'Videollamada' : 'Llamada de voz'),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade300, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => AppNavigation.safeBack(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    final call = _call!;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (_isVideo)
          RTCVideoView(
            call.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          )
        else
          _audioPlaceholder(),
        if (_isVideo)
          Positioned(
            top: 100,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 110,
                height: 150,
                child: _cameraOff
                    ? Container(
                        color: Colors.grey.shade900,
                        child: const Icon(Icons.videocam_off, color: Colors.white54),
                      )
                    : RTCVideoView(
                        call.localRenderer,
                        mirror: true,
                        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
              ),
            ),
          ),
        Positioned(
          top: 48,
          left: 16,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _peerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _status,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ctrl(
                icon: _muted ? Icons.mic_off : Icons.mic,
                color: _muted ? Colors.red : Colors.white24,
                onTap: () {
                  setState(() => _muted = !_muted);
                  call.toggleMute(_muted);
                },
              ),
              const SizedBox(width: 20),
              _ctrl(
                icon: Icons.call_end,
                color: Colors.red,
                size: 32,
                onTap: () => unawaited(
                  _hangUpLocal(navigateBack: true, reason: 'user'),
                ),
              ),
              if (_isVideo) ...[
                const SizedBox(width: 20),
                _ctrl(
                  icon: _cameraOff ? Icons.videocam_off : Icons.videocam,
                  color: _cameraOff ? Colors.red : Colors.white24,
                  onTap: () {
                    setState(() => _cameraOff = !_cameraOff);
                    call.toggleCamera(_cameraOff);
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _audioPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E40AF)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 56,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.phone_in_talk_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _peerName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ctrl({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 24,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size),
      ),
    );
  }
}
