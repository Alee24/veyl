import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../../features/chat/socket_service.dart';
import '../services/peer_connection_manager.dart';
import '../models/call_session.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String peerName;
  final String peerUsername;
  final bool isVideo;
  final bool isCaller;

  const ActiveCallScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.peerUsername,
    required this.isVideo,
    required this.isCaller,
  });

  @override
  ConsumerState<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> with SingleTickerProviderStateMixin {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  late PeerConnectionManager _peerConnectionManager;

  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  String _callStatus = 'Connecting WebRTC...';

  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _candidateSub;
  StreamSubscription? _callEndedSub;
  Timer? _callTimer;
  int _durationSeconds = 0;

  @override
  void initState() {
    super.initState();
    _isVideoMuted = !widget.isVideo;
    _initWebRTC();
  }

  Future<void> _initWebRTC() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();

    final socketService = ref.read(socketServiceProvider);

    _peerConnectionManager = PeerConnectionManager(
      onLocalStream: (stream) {
        if (mounted) {
          setState(() {
            _localRenderer.srcObject = stream;
          });
        }
      },
      onRemoteStream: (stream) {
        if (mounted) {
          setState(() {
            _remoteRenderer.srcObject = stream;
            _isConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
        }
      },
      onIceCandidate: (candidate) {
        socketService.sendWebRTCIceCandidate(widget.peerId, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      },
      onConnectionStateChange: (state) {
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          if (mounted) {
            setState(() {
              _callStatus = 'Reconnecting...';
            });
            _peerConnectionManager.restartIce();
          }
        }
      },
    );

    // Listen for WebRTC signals from peer
    _offerSub = socketService.onWebRTCOffer.listen((data) async {
      if (data['senderId'] == widget.peerId) {
        final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
        final answer = await _peerConnectionManager.createAnswer(sdp);
        socketService.sendWebRTCAnswer(widget.peerId, {
          'sdp': answer.sdp,
          'type': answer.type,
        });
      }
    });

    _answerSub = socketService.onWebRTCAnswer.listen((data) async {
      if (data['senderId'] == widget.peerId) {
        final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
        await _peerConnectionManager.setRemoteAnswer(sdp);
        if (mounted) {
          setState(() {
            _isConnected = true;
            _callStatus = 'Connected';
          });
          _startCallTimer();
        }
      }
    });

    _candidateSub = socketService.onWebRTCIceCandidate.listen((data) async {
      if (data['senderId'] == widget.peerId) {
        final candidateData = data['candidate'];
        final candidate = RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        );
        await _peerConnectionManager.addIceCandidate(candidate);
      }
    });

    _callEndedSub = socketService.onCallEnded.listen((data) {
      if (data['senderId'] == widget.peerId && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Call ended')),
        );
        _cleanUpAndExit();
      }
    });

    try {
      await _peerConnectionManager.initialize(widget.isVideo ? CallType.video : CallType.voice);

      if (widget.isCaller) {
        final offer = await _peerConnectionManager.createOffer();
        socketService.sendWebRTCOffer(widget.peerId, {
          'sdp': offer.sdp,
          'type': offer.type,
        });
      }
    } catch (e) {
      debugPrint('Error initializing WebRTC: $e');
    }
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _durationSeconds++;
        });
      }
    });
  }

  String _formatDuration(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  void _toggleMuteAudio() {
    setState(() {
      _isAudioMuted = !_isAudioMuted;
    });
    _peerConnectionManager.setAudioMuted(_isAudioMuted);
  }

  void _toggleMuteVideo() {
    if (widget.isVideo) {
      setState(() {
        _isVideoMuted = !_isVideoMuted;
      });
      _peerConnectionManager.setVideoMuted(_isVideoMuted);
    }
  }

  void _switchCamera() {
    if (widget.isVideo) {
      _peerConnectionManager.switchCamera();
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    _peerConnectionManager.setSpeakerphone(_isSpeakerOn);
  }

  void _hangUp() {
    ref.read(socketServiceProvider).endCall(widget.peerId);
    _cleanUpAndExit();
  }

  void _cleanUpAndExit() {
    _callTimer?.cancel();
    _peerConnectionManager.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _offerSub?.cancel();
    _answerSub?.cancel();
    _candidateSub?.cancel();
    _callEndedSub?.cancel();
    _peerConnectionManager.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = 'https://i.pravatar.cc/300?u=${widget.peerUsername}';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            // ─── Remote Stream / Audio Profile Visualizer ─────────────────────
            if (widget.isVideo && _isConnected && !_isVideoMuted)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Positioned.fill(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          width: 4,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 64,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.peerName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '@${widget.peerUsername}',
                      style: const TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _isConnected ? _formatDuration(_durationSeconds) : _callStatus,
                        style: const TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Picture-in-Picture Local Camera Stream ──────────────────────
            if (widget.isVideo && !_isVideoMuted)
              Positioned(
                top: 24,
                right: 24,
                child: Container(
                  width: 110,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white24, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // ─── Call Control Buttons Bar ───────────────────────────────────
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Mute Audio Toggle
                    _buildControlButton(
                      icon: _isAudioMuted ? Icons.mic_off : Icons.mic,
                      color: _isAudioMuted ? Colors.redAccent : Colors.white24,
                      onTap: _toggleMuteAudio,
                    ),

                    // Speaker Toggle
                    _buildControlButton(
                      icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: _isSpeakerOn ? const Color(0xFF6366F1) : Colors.white24,
                      onTap: _toggleSpeaker,
                    ),

                    // Video Camera Toggle
                    if (widget.isVideo)
                      _buildControlButton(
                        icon: _isVideoMuted ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoMuted ? Colors.redAccent : Colors.white24,
                        onTap: _toggleMuteVideo,
                      ),

                    // Switch Camera
                    if (widget.isVideo && !_isVideoMuted)
                      _buildControlButton(
                        icon: Icons.switch_camera,
                        color: Colors.white24,
                        onTap: _switchCamera,
                      ),

                    // End / Hang up Call
                    _buildControlButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      iconColor: Colors.white,
                      isEndCall: true,
                      onTap: _hangUp,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color iconColor = Colors.white,
    bool isEndCall = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isEndCall ? 18 : 14),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: isEndCall ? 28 : 22),
      ),
    );
  }
}
