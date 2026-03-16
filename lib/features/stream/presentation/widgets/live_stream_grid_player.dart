import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/stream_bloc.dart';

// ═════════════════════════════════════════════════════════════════════════════
// LIVE STREAM GRID PLAYER
//
// A single camera tile inside the multi-camera grid view.
//
// Stream lifecycle rules:
//   • isActive = true  → begin ICE gathering + SDP negotiation → stream video.
//   • isActive = false → send StopStreamEvent, close PeerConnection, show placeholder.
//   • isMuted changes  → toggle audio tracks on the live MediaStream (no reconnect).
//   • dispose()        → always stop active session and close WebRTC resources.
//
// The parent (DeviceDetailPage) passes isActive = (myPageIndex == currentPage)
// so only the visible page's tiles are ever streaming at one time.
// ═════════════════════════════════════════════════════════════════════════════
class LiveStreamGridPlayer extends StatefulWidget {
  final String deviceId;
  final String channelId;
  final String channelName;

  /// Controls whether this tile should actively stream.
  /// Set false to stop the stream and show a placeholder.
  final bool isActive;

  /// Global mute state from the dashboard.
  final bool isMuted;

  final VoidCallback onFullScreenTap;

  const LiveStreamGridPlayer({
    Key? key,
    required this.deviceId,
    required this.channelId,
    required this.channelName,
    required this.isActive,
    required this.isMuted,
    required this.onFullScreenTap,
  }) : super(key: key);

  @override
  State<LiveStreamGridPlayer> createState() => _LiveStreamGridPlayerState();
}

class _LiveStreamGridPlayerState extends State<LiveStreamGridPlayer> {
  final RTCVideoRenderer _renderer = RTCVideoRenderer();
  RTCPeerConnection? _pc;
  Timer? _heartbeat;
  String? _sessionId;
  bool _rendererReady = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  @override
  void didUpdateWidget(LiveStreamGridPlayer old) {
    super.didUpdateWidget(old);

    // Mute toggled — apply to audio tracks without reconnecting
    if (old.isMuted != widget.isMuted) {
      _applyMute(widget.isMuted);
    }

    // Active state changed
    if (old.isActive != widget.isActive) {
      if (widget.isActive) {
        // Page became visible — start streaming
        _startNegotiation();
      } else {
        // Page became hidden — stop streaming
        _tearDown(reason: 'page hidden');
      }
    }
  }

  @override
  void dispose() {
    _tearDown(reason: 'widget disposed');
    _renderer.dispose();
    super.dispose();
  }

  // ── Renderer ──────────────────────────────────────────────────────────────

  Future<void> _initRenderer() async {
    await _renderer.initialize();
    if (mounted) {
      setState(() => _rendererReady = true);
      if (widget.isActive) _startNegotiation();
    }
  }

  // ── Stream Negotiation ────────────────────────────────────────────────────

  Future<void> _startNegotiation() async {
    if (!_rendererReady || !mounted) return;

    // Safety: clean up any previous connection first
    await _closePeerConnection();

    final config = {
      'sdpSemantics': 'unified-plan',
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _pc = await createPeerConnection(config);

    // Receive-only transceivers (we never send from the app)
    await _pc!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );
    await _pc!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    _pc!.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty && mounted) {
        setState(() => _renderer.srcObject = event.streams[0]);
        _applyMute(widget.isMuted);
      }
    };

    // Create offer
    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    // Wait for ICE gathering to complete (max 1.5s)
    if (_pc!.iceGatheringState !=
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      final done = Completer<void>();
      _pc!.onIceGatheringState = (state) {
        if (state == RTCIceGatheringState.RTCIceGatheringStateComplete &&
            !done.isCompleted) {
          done.complete();
        }
      };
      await done.future.timeout(
        const Duration(milliseconds: 1500),
        onTimeout: () {},
      );
    }

    final finalDesc = await _pc!.getLocalDescription();
    final sdpOffer = finalDesc?.sdp ?? offer.sdp ?? '';

    if (mounted) {
      context.read<StreamBloc>().add(
        StartStreamEvent(
          deviceId: widget.deviceId,
          channelId: widget.channelId,
          streamType: 'SUB', // Grid always uses sub-stream to save bandwidth
          sdpOffer: sdpOffer,
        ),
      );
    }
  }

  /// Called when the backend returns the SDP answer and a session ID.
  Future<void> _onStreamActive(String sdpAnswer, String sessionId) async {
    _sessionId = sessionId;

    await _pc?.setRemoteDescription(RTCSessionDescription(sdpAnswer, 'answer'));

    // Start heartbeat — backend reaper kills sessions after 90s without one
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _sessionId != null) {
        context.read<StreamBloc>().add(HeartbeatEvent(_sessionId!));
      }
    });
  }

  /// Gracefully stops the stream, closes WebRTC, and cleans up timers.
  Future<void> _tearDown({required String reason}) async {
    _heartbeat?.cancel();
    _heartbeat = null;

    // Tell the backend to close the WVP stream and MediaMTX WHEP session
    if (_sessionId != null && mounted) {
      try {
        context.read<StreamBloc>().add(StopStreamEvent(_sessionId!));
      } catch (_) {
        // StreamBloc may already be closed during widget disposal — safe to ignore
      }
      _sessionId = null;
    }

    await _closePeerConnection();

    if (mounted) {
      setState(() => _renderer.srcObject = null);
    }
  }

  Future<void> _closePeerConnection() async {
    await _pc?.close();
    await _pc?.dispose();
    _pc = null;
  }

  // ── Audio ─────────────────────────────────────────────────────────────────

  void _applyMute(bool muted) {
    final stream = _renderer.srcObject;
    if (stream == null) return;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StreamBloc, StreamState>(
      listener: (context, state) {
        if (state is StreamActive) {
          _onStreamActive(state.sdpAnswer, state.sessionId);
        }
      },
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            if (state is StreamActive) widget.onFullScreenTap();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.rSm),
            child: Container(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Video layer ─────────────────────────────────────────
                  if (state is StreamActive && _renderer.srcObject != null)
                    RTCVideoView(
                      _renderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                    ),

                  // ── Placeholder layer (not yet streaming or inactive) ───
                  if (state is! StreamActive)
                    _PlaceholderOverlay(
                      channelName: widget.channelName,
                      state: state,
                      isActive: widget.isActive,
                    ),

                  // ── Camera name + status overlay ────────────────────────
                  if (state is StreamActive)
                    _CameraLabel(
                      name: widget.channelName,
                      isMuted: widget.isMuted,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEHOLDER OVERLAY
// Shown while connecting, on error, or when the tile is inactive.
// ─────────────────────────────────────────────────────────────────────────────
class _PlaceholderOverlay extends StatelessWidget {
  final String channelName;
  final StreamState state;
  final bool isActive;

  const _PlaceholderOverlay({
    required this.channelName,
    required this.state,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    Widget centerContent;

    if (!isActive) {
      // Tile is on an inactive page — show dim placeholder
      centerContent = Icon(
        Icons.videocam_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.2),
        size: 20,
      );
    } else if (state is StreamConnecting || state is StreamInitial) {
      // Connecting to the stream
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              color: AppTheme.amber,
              strokeWidth: 1.5,
            ),
          ),
          const SizedBox(height: AppTheme.s6),
          Text(
            'Connecting',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.amberLight,
              fontSize: 9,
            ),
          ),
        ],
      );
    } else if (state is StreamError) {
      // Stream failed
      centerContent = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.signal_wifi_bad_rounded,
            color: AppTheme.error.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(height: AppTheme.s4),
          Text(
            'Failed',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppTheme.error.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
        ],
      );
    } else {
      centerContent = const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Subtle background pattern
        Container(color: Theme.of(context).colorScheme.surfaceContainer),
        Center(child: centerContent),
        // Camera name label at bottom
        Positioned(
          bottom: AppTheme.s4,
          left: AppTheme.s6,
          right: AppTheme.s6,
          child: Text(
            channelName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 9,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA LABEL — overlay shown on top of live video
// ─────────────────────────────────────────────────────────────────────────────
class _CameraLabel extends StatelessWidget {
  final String name;
  final bool isMuted;

  const _CameraLabel({required this.name, required this.isMuted});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: AppTheme.s4,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black54, Colors.transparent],
          ),
        ),
        child: Row(
          children: [
            // Tiny pulsing green dot — live indicator
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFF34D399),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF34D399).withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
            if (!isMuted)
              const Icon(
                Icons.volume_up_rounded,
                color: Colors.white70,
                size: 10,
              ),
          ],
        ),
      ),
    );
  }
}
