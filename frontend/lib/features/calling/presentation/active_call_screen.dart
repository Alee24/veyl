import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:go_router/go_router.dart';
import '../../chat/socket_service.dart';

class ActiveCallScreen extends ConsumerStatefulWidget {
  final String peerId;
  final String peerName;
  final String peerUsername;
  final bool isVideo;
  final bool isCaller; // true if I initiated, false if I accepted

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

class _ActiveCallScreenState extends ConsumerState<ActiveCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  bool _isAudioMuted = false;
  bool _isVideoMuted = false;
  bool _isSpeakerOn = true;
  bool _isConnected = false;
  String _callStatus = 'Connecting...';

  StreamSubscription? _offerSub;
  StreamSubscription? _answerSub;
  StreamSubscription? _candidateSub;
  StreamSubscription? _callEndedSub;

  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
    ]
  };

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

    // 1. Listen for WebRTC signals from peer
    _offerSub = socketService.onWebRTCOffer.listen((data) async {
      if (data['senderId'] == widget.peerId && _peerConnection != null) {
        final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
        await _peerConnection!.setRemoteDescription(sdp);

        final answer = await _peerConnection!.createAnswer();
        await _peerConnection!.setLocalDescription(answer);

        socketService.sendWebRTCAnswer(widget.peerId, {
          'sdp': answer.sdp,
          'type': answer.type,
        });
      }
    });

    _answerSub = socketService.onWebRTCAnswer.listen((data) async {
      if (data['senderId'] == widget.peerId && _peerConnection != null) {
        final sdp = RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']);
        await _peerConnection!.setRemoteDescription(sdp);
        if (mounted) {
          setState(() {
            _isConnected = true;
            _callStatus = 'Connected';
          });
        }
      }
    });

    _candidateSub = socketService.onWebRTCIceCandidate.listen((data) async {
      if (data['senderId'] == widget.peerId && _peerConnection != null) {
        final candidateData = data['candidate'];
        final candidate = RTCIceCandidate(
          candidateData['candidate'],
          candidateData['sdpMid'],
          candidateData['sdpMLineIndex'],
        );
        await _peerConnection!.addCandidate(candidate);
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

    // 2. Get User Media Stream (Camera / Microphone)
    final mediaConstraints = {
      'audio': true,
      'video': widget.isVideo
          ? {
              'mandatory': {
                'minWidth': '640',
                'minHeight': '480',
                'minFrameRate': '30',
              },
              'facingMode': 'user',
              'optional': [],
            }
          : false,
    };

    try {
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localRenderer.srcObject = _localStream;

      // 3. Create RTCPeerConnection
      _peerConnection = await createPeerConnection(_configuration);

      // Add local tracks to peer connection
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle Remote Stream Tracks
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          setState(() {
            _remoteRenderer.srcObject = event.streams[0];
            _isConnected = true;
            _callStatus = 'Connected';
          });
        }
      };

      // Handle ICE Candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        socketService.sendWebRTCIceCandidate(widget.peerId, {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        });
      };

      // 4. If Caller, Create Offer SDP
      if (widget.isCaller) {
        final offer = await _peerConnection!.createOffer();
        await _peerConnection!.setLocalDescription(offer);

        socketService.sendWebRTCOffer(widget.peerId, {
          'sdp': offer.sdp,
          'type': offer.type,
        });
      }
    } catch (e) {
      debugPrint('Error initializing WebRTC: $e');
      if (mounted) {
        setState(() {
          _callStatus = 'Call Connection Error';
        });
      }
    }
  }

  void _toggleMuteAudio() {
    if (_localStream != null) {
      final audioTracks = _localStream!.getAudioTracks();
      if (audioTracks.isNotEmpty) {
        final enabled = audioTracks[0].enabled;
        audioTracks[0].enabled = !enabled;
        setState(() {
          _isAudioMuted = !enabled;
        });
      }
    }
  }

  void _toggleMuteVideo() {
    if (_localStream != null && widget.isVideo) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        final enabled = videoTracks[0].enabled;
        videoTracks[0].enabled = !enabled;
        setState(() {
          _isVideoMuted = !enabled;
        });
      }
    }
  }

  void _switchCamera() {
    if (_localStream != null && widget.isVideo) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        Helper.switchCamera(videoTracks[0]);
      }
    }
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
    if (_localStream != null) {
      Helper.setSpeakerphoneOn(_isSpeakerOn);
    }
  }

  void _hangUp() {
    ref.read(socketServiceProvider).endCall(widget.peerId);
    _cleanUpAndExit();
  }

  void _cleanUpAndExit() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _offerSub?.cancel();
    _answerSub?.cancel();
    _candidateSub?.cancel();
    _callEndedSub?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
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
            // ─── Remote Stream / Audio Profile UI ─────────────────────────────
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
                        _callStatus,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Local Camera Picture-in-Picture (PiP) for Video Call ─────────
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

            // ─── Call Control Buttons Bar ───────────────────────────────────────
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

                    // Video Camera Toggle (for video calls)
                    if (widget.isVideo)
                      _buildControlButton(
                        icon: _isVideoMuted ? Icons.videocam_off : Icons.videocam,
                        color: _isVideoMuted ? Colors.redAccent : Colors.white24,
                        onTap: _toggleMuteVideo,
                      ),

                    // Switch Camera (Front/Rear)
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
