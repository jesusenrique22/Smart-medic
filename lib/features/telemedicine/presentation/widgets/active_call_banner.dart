import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/services/active_call_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Inserta/retira la barra flotante en el [Overlay] del navigator raíz.
abstract final class ActiveCallOverlay {
  ActiveCallOverlay._();

  static GlobalKey<NavigatorState>? _navigatorKey;
  static OverlayEntry? _entry;
  static bool _listenerAttached = false;

  static void attach(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    if (_listenerAttached) return;
    _listenerAttached = true;
    ActiveCallService.instance.addListener(_sync);
  }

  static void _sync() {
    final service = ActiveCallService.instance;
    if (!service.isMinimized) {
      _entry?.remove();
      _entry = null;
      return;
    }

    final overlay = _navigatorKey?.currentState?.overlay;
    if (overlay == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
      return;
    }

    _entry ??= OverlayEntry(builder: (_) => const _ActiveCallOverlayLayer());
    if (!_entry!.mounted) {
      overlay.insert(_entry!);
    } else {
      _entry!.markNeedsBuild();
    }
  }
}

class _ActiveCallOverlayLayer extends StatelessWidget {
  const _ActiveCallOverlayLayer();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ActiveCallService.instance,
      builder: (context, _) {
        final service = ActiveCallService.instance;
        if (!service.isMinimized || service.controller == null) {
          return const SizedBox.shrink();
        }

        final bottom = MediaQuery.paddingOf(context).bottom + 72;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Reproductor oculto (web necesita elemento media para audio remoto).
            Positioned(
              left: 0,
              top: 0,
              width: 1,
              height: 1,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.01,
                  child: RTCVideoView(
                    service.controller!.remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: bottom,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(14),
                color: AppColors.primary,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: service.expandToFullScreen,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          service.isVideo
                              ? Icons.videocam_rounded
                              : Icons.phone_in_talk,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                service.peerName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${service.status} · Toca para volver',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Colgar',
                          onPressed: () => unawaited(
                            ActiveCallService.instance.hangUp(notifyPeer: true),
                          ),
                          icon: const Icon(Icons.call_end, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
