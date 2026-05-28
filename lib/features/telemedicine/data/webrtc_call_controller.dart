import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/auth/app_session.dart';
import '../../chat/data/chat_socket_service.dart';

class WebRtcCallController {
  WebRtcCallController({required this.socket, required this.conversationId});

  static const _logName = 'WebRtcCallController';

  final ChatSocketService socket;
  final String conversationId;

  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peer;
  MediaStream? _localStream;
  bool _disposed = false;
  bool _videoEnabled = false;
  bool _remoteDescriptionSet = false;
  bool _remoteAnswerApplied = false;
  bool _handlingOffer = false;
  bool _mediaReady = false;
  bool _offerSent = false;
  bool _acceptHandled = false;
  bool _pendingAccept = false;
  bool _outgoingMediaReady = false;

  final List<RTCIceCandidate> _pendingRemoteCandidates = [];
  final Set<String> _seenIceCandidateKeys = {};
  final Set<String> _seenSignalIds = {};

  Map<String, dynamic>? _queuedOffer;

  final _statusController = StreamController<String>.broadcast();
  Stream<String> get statusStream => _statusController.stream;

  static const _config = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan',
  };

  Map<String, dynamic> _sessionConstraints(bool video) => {
        'offerToReceiveAudio': true,
        'offerToReceiveVideo': video,
      };

  Future<void> init() async {
    try {
      await localRenderer.initialize();
      await remoteRenderer.initialize();
    } on MissingPluginException {
      throw Exception(
        'WebRTC no está disponible en esta build. En iOS ejecuta: '
        'cd ios && pod install, luego flutter clean && flutter run.',
      );
    } on PlatformException catch (e) {
      throw Exception('No se pudo iniciar WebRTC: ${e.message ?? e.code}');
    }
  }

  Future<bool> ensurePermissions({required bool video}) async {
    if (kIsWeb) return true;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) return false;
    }
    return true;
  }

  bool _dedupeSignal(Map<String, dynamic> data) {
    final id = data['signalId']?.toString();
    if (id == null || id.isEmpty) return false;
    if (_seenSignalIds.contains(id)) return true;
    _seenSignalIds.add(id);
    return false;
  }

  String? _currentUserId() => AppSession.currentUser?.id;

  bool _isFromSelf(Map<String, dynamic> data) {
    final from = data['fromUserId']?.toString();
    final me = _currentUserId();
    return from != null && me != null && from == me;
  }

  Future<void> _createPeer() async {
    _peer = await createPeerConnection(_config);
    _peer!.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      socket.sendIceCandidate(
        conversationId: conversationId,
        candidate: candidate.toMap(),
      );
    };
    _peer!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        remoteRenderer.srcObject = event.streams.first;
      }
    };
    _peer!.onConnectionState = (state) {
      final name = state.toString();
      developer.log('connectionState=$name', name: _logName);
      if (name.contains('Connected')) {
        if (!_statusController.isClosed) {
          _statusController.add('connected');
        }
      } else if (name.contains('Failed') || name.contains('Closed')) {
        if (!_statusController.isClosed) {
          _statusController.add('ended');
        }
      }
    };
  }

  Future<void> _attachLocalMedia({required bool video}) async {
    _videoEnabled = video;
    final ok = await ensurePermissions(video: video);
    if (!ok) throw Exception('Permisos de cámara o micrófono denegados');

    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video
          ? {
              'facingMode': 'user',
              'width': {'ideal': 1280},
              'height': {'ideal': 720},
            }
          : false,
    });
    localRenderer.srcObject = _localStream;

    if (_peer == null || _localStream == null) return;

    await _peer!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(
        direction: TransceiverDirection.SendRecv,
        streams: [_localStream!],
      ),
    );

    if (video && _localStream!.getVideoTracks().isNotEmpty) {
      await _peer!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(
          direction: TransceiverDirection.SendRecv,
          streams: [_localStream!],
        ),
      );
    }
  }

  String _iceKey(Map<String, dynamic> raw) {
    final c = raw['candidate'] as String? ?? '';
    final mid = raw['sdpMid'] as String? ?? '';
    final idx = raw['sdpMLineIndex']?.toString() ?? '';
    return '$c|$mid|$idx';
  }

  Future<void> _safeAddCandidate(RTCIceCandidate candidate) async {
    if (_peer == null) return;
    if (!_remoteDescriptionSet) {
      _pendingRemoteCandidates.add(candidate);
      return;
    }
    try {
      await _peer!.addCandidate(candidate);
    } catch (_) {
      _pendingRemoteCandidates.add(candidate);
    }
  }

  Future<void> _queueOrAddCandidate(Map<String, dynamic> raw) async {
    final line = raw['candidate'] as String?;
    if (line == null || line.isEmpty) return;

    final key = _iceKey(raw);
    if (_seenIceCandidateKeys.contains(key)) return;
    _seenIceCandidateKeys.add(key);

    await _safeAddCandidate(
      RTCIceCandidate(
        line,
        raw['sdpMid'] as String?,
        raw['sdpMLineIndex'] as int?,
      ),
    );
  }

  Future<void> _drainPendingCandidates() async {
    if (_peer == null || !_remoteDescriptionSet) return;
    if (kIsWeb) {
      await Future<void>.delayed(Duration.zero);
    }
    final pending = List<RTCIceCandidate>.from(_pendingRemoteCandidates);
    _pendingRemoteCandidates.clear();
    for (final c in pending) {
      await _safeAddCandidate(c);
    }
  }

  Future<void> _setRemoteDescription(RTCSessionDescription desc) async {
    await _peer!.setRemoteDescription(desc);
    _remoteDescriptionSet = true;
    await _drainPendingCandidates();
  }

  Future<void> _applyRemoteAnswer(Map<String, dynamic> sdpMap) async {
    if (_peer == null || _disposed || _remoteAnswerApplied) return;

    _remoteAnswerApplied = true;
    try {
      await _setRemoteDescription(
        RTCSessionDescription(sdpMap['sdp'] as String, sdpMap['type'] as String),
      );
      developer.log('answer aplicada (caller)', name: _logName);
    } catch (e, st) {
      _remoteAnswerApplied = false;
      developer.log('applyRemoteAnswer', name: _logName, error: e, stackTrace: st);
    }
  }

  void _registerSharedHandlers() {
    socket.onCallIce((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (_isFromSelf(data) || _dedupeSignal(data)) return;
      final c = data['candidate'];
      if (c is Map) {
        await _queueOrAddCandidate(Map<String, dynamic>.from(c));
      }
    });
    socket.onCallEnded((_) {
      if (!_statusController.isClosed) _statusController.add('ended');
    });
    socket.onCallRejected((_) {
      if (!_statusController.isClosed) _statusController.add('rejected');
    });
  }

  void _registerOfferHandler({required bool wantsVideo}) {
    socket.onCallOffer((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (_isFromSelf(data) || _dedupeSignal(data)) return;

      if (!_mediaReady) {
        _queuedOffer = data;
        developer.log('offer en cola (media no lista)', name: _logName);
        return;
      }
      await _handleRemoteOffer(data, fallbackVideo: wantsVideo);
    });
  }

  Future<void> _flushQueuedOffer({required bool wantsVideo}) async {
    final offer = _queuedOffer;
    if (offer == null) return;
    _queuedOffer = null;
    await _handleRemoteOffer(offer, fallbackVideo: wantsVideo);
  }

  Future<void> _onOutgoingPeerAccepted(bool wantsVideo) async {
    if (_acceptHandled || _disposed) return;
    _acceptHandled = true;
    developer.log('call:accepted → createOffer', name: _logName);
    socket.joinCallRoom(conversationId);
    await _createAndSendOffer(wantsVideo);
  }

  /// Registra listeners y prepara media. Llamar [sendOutgoingInvite] después.
  Future<void> startOutgoingCall({required bool video, required String callType}) async {
    final wantsVideo = callType != 'audio' && video;

    socket.offCallEvents();
    _registerSharedHandlers();

    socket.onCallAccepted((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (!_outgoingMediaReady) {
        _pendingAccept = true;
        developer.log('call:accepted en cola (media aún no lista)', name: _logName);
        return;
      }
      await _onOutgoingPeerAccepted(wantsVideo);
    });

    socket.onCallAnswer((data) async {
      if (data['conversationId']?.toString() != conversationId) return;
      if (_isFromSelf(data) || _dedupeSignal(data)) return;
      final sdp = data['sdp'];
      if (sdp is! Map) return;
      await _applyRemoteAnswer(Map<String, dynamic>.from(sdp));
    });

    await _createPeer();
    await _attachLocalMedia(video: wantsVideo);
    _mediaReady = true;
    _outgoingMediaReady = true;

    if (_pendingAccept) {
      _pendingAccept = false;
      await _onOutgoingPeerAccepted(wantsVideo);
    }
  }

  /// Debe llamarse solo después de [startOutgoingCall] (peer listo + listeners activos).
  void sendOutgoingInvite({required String callerName, required String callType}) {
    developer.log('call:invite conv=$conversationId', name: _logName);
    socket.inviteCall(
      conversationId: conversationId,
      callType: callType,
      callerName: callerName,
    );
  }

  Future<void> _createAndSendOffer(bool video) async {
    if (_peer == null || _disposed || _offerSent) return;
    _offerSent = true;
    final offer = await _peer!.createOffer(_sessionConstraints(video));
    await _peer!.setLocalDescription(offer);
    socket.sendOffer(
      conversationId: conversationId,
      sdp: offer.toMap(),
      callType: video ? 'video' : 'audio',
    );
    developer.log('offer enviada (video=$video)', name: _logName);
  }

  Future<void> acceptIncomingCall({
    required bool video,
    required String callType,
    bool skipAcceptSignal = false,
  }) async {
    final wantsVideo = callType != 'audio' && video;

    socket.offCallEvents();
    _registerSharedHandlers();
    _registerOfferHandler(wantsVideo: wantsVideo);

    await _createPeer();
    await _attachLocalMedia(video: wantsVideo);

    socket.joinCallRoom(conversationId);
    _mediaReady = true;

    await _flushQueuedOffer(wantsVideo: wantsVideo);

    if (!skipAcceptSignal) {
      developer.log('call:accept (peer listo)', name: _logName);
      socket.acceptCall(conversationId);
    }

    await _flushQueuedOffer(wantsVideo: wantsVideo);
  }

  Future<void> _handleRemoteOffer(
    Map<String, dynamic> data, {
    required bool fallbackVideo,
  }) async {
    if (_handlingOffer || _peer == null) return;
    _handlingOffer = true;

    try {
      final offerCallType = data['callType'] as String? ?? (fallbackVideo ? 'video' : 'audio');
      final offerVideo = offerCallType != 'audio';
      final sdp = data['sdp'];
      if (sdp is! Map) return;

      developer.log('offer recibida (video=$offerVideo)', name: _logName);

      await _setRemoteDescription(
        RTCSessionDescription(sdp['sdp'] as String, sdp['type'] as String),
      );

      final answer = await _peer!.createAnswer(_sessionConstraints(offerVideo));
      await _peer!.setLocalDescription(answer);
      socket.sendAnswer(conversationId: conversationId, sdp: answer.toMap());
      developer.log('answer enviada', name: _logName);
    } catch (e, st) {
      developer.log('handleRemoteOffer', name: _logName, error: e, stackTrace: st);
      debugPrint('[WebRTC] Error negociando offer/answer: $e');
      if (!_statusController.isClosed) _statusController.add('ended');
    } finally {
      _handlingOffer = false;
    }
  }

  Future<void> toggleMute(bool muted) async {
    for (final track in _localStream?.getAudioTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !muted;
    }
  }

  Future<void> toggleCamera(bool off) async {
    for (final track in _localStream?.getVideoTracks() ?? <MediaStreamTrack>[]) {
      track.enabled = !off;
    }
  }

  bool get hasVideo => _videoEnabled;

  void hangUp() {
    if (_disposed) return;
    try {
      socket.endCall(conversationId);
    } catch (e, st) {
      developer.log('hangUp', name: _logName, error: e, stackTrace: st);
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      socket.offCallEvents();
      localRenderer.srcObject = null;
      remoteRenderer.srcObject = null;
      for (final track in _localStream?.getTracks() ?? <MediaStreamTrack>[]) {
        track.stop();
      }
      await _localStream?.dispose();
      _localStream = null;
      await _peer?.close();
      _peer = null;
      _pendingRemoteCandidates.clear();
      _seenIceCandidateKeys.clear();
      _seenSignalIds.clear();
      _queuedOffer = null;
      await localRenderer.dispose();
      await remoteRenderer.dispose();
      if (!_statusController.isClosed) {
        await _statusController.close();
      }
    } catch (e, st) {
      developer.log('dispose', name: _logName, error: e, stackTrace: st);
      rethrow;
    }
  }
}
