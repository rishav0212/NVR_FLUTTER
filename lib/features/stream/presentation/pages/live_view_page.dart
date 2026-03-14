import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../bloc/stream_bloc.dart';

class LiveViewPage extends StatefulWidget {
  final String deviceId;
  final String channelId;
  final String channelName;

  const LiveViewPage({
    Key? key,
    required this.deviceId,
    required this.channelId,
    required this.channelName,
  }) : super(key: key);

  @override
  State<LiveViewPage> createState() => _LiveViewPageState();
}

class _LiveViewPageState extends State<LiveViewPage> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  Timer? _heartbeatTimer;
  String? _activeSessionId;
  String _streamType = 'MAIN'; // Default to high-res

  @override
  void initState() {
    super.initState();
    _initRenderer();
  }

  Future<void> _initRenderer() async {
    await _localRenderer.initialize();
    _startWebRtcNegotiation();
  }

  /// 1. Prepares the WebRTC peer connection and generates the local SDP Offer
  Future<void> _startWebRtcNegotiation() async {
    // Configuration forces standard WebRTC behavior
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    _peerConnection = await createPeerConnection(configuration);

    // We only want to RECEIVE video, not send our phone's camera back to the server
    _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // When the server answers and sends video tracks, bind them to the Flutter renderer
    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'video' && event.streams.isNotEmpty) {
        setState(() {
          _localRenderer.srcObject = event.streams[0];
        });
      }
    };

    // Gather local WebRTC info to send to MediaMTX
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Dispatch to BLoC to send to Spring Boot
    if (mounted) {
      context.read<StreamBloc>().add(
        StartStreamEvent(
          deviceId: widget.deviceId,
          channelId: widget.channelId,
          streamType: _streamType,
          sdpOffer: offer.sdp ?? '',
        ),
      );
    }
  }

  /// 2. Completes the handshake with the SDP Answer from MediaMTX
  Future<void> _handleStreamActive(String sdpAnswer, String sessionId) async {
    _activeSessionId = sessionId;

    // Inform WebRTC of the server's video parameters
    RTCSessionDescription answer = RTCSessionDescription(sdpAnswer, 'answer');
    await _peerConnection?.setRemoteDescription(answer);

    // Start the strict 30-second heartbeat required by Phase 3.5
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        context.read<StreamBloc>().add(HeartbeatEvent(sessionId));
      }
    });
  }

  /// 3. Cleanup to prevent orphaned streams
  @override
  void dispose() {
    _heartbeatTimer?.cancel();

    if (_activeSessionId != null) {
      // Fire-and-forget deletion to Spring Boot
      context.read<StreamBloc>().add(StopStreamEvent(_activeSessionId!));
    }

    _peerConnection?.close();
    _peerConnection?.dispose();
    _localRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.channelName),
        backgroundColor: Colors.black87,
        actions: [
          // MAIN/SUB Stream Toggle
          TextButton(
            onPressed: () {
              // ---> ADDED OPTIMIZATION HERE <---
              // Kill the old server session BEFORE starting the new one
              if (_activeSessionId != null) {
                context.read<StreamBloc>().add(
                  StopStreamEvent(_activeSessionId!),
                );
                _activeSessionId = null;
              }

              setState(() {
                _streamType = _streamType == 'MAIN' ? 'SUB' : 'MAIN';
              });

              // Dispose old connection and restart with new resolution
              _peerConnection?.close();
              _heartbeatTimer?.cancel();
              _startWebRtcNegotiation();
            },
            child: Text(
              _streamType,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<StreamBloc, StreamState>(
        listener: (context, state) {
          if (state is StreamActive) {
            _handleStreamActive(state.sdpAnswer, state.sessionId);
          } else if (state is StreamError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is StreamConnecting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "Waking up camera...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            );
          }

          // Video Renderer View
          return Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: RTCVideoView(
                  _localRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitContain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
