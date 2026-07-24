import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../models/call_session.dart';

typedef OnLocalStreamCallback = void Function(MediaStream stream);
typedef OnRemoteStreamCallback = void Function(MediaStream stream);
typedef OnIceCandidateCallback = void Function(RTCIceCandidate candidate);
typedef OnConnectionStateCallback = void Function(RTCPeerConnectionState state);

class PeerConnectionManager {
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  final OnLocalStreamCallback? onLocalStream;
  final OnRemoteStreamCallback? onRemoteStream;
  final OnIceCandidateCallback? onIceCandidate;
  final OnConnectionStateCallback? onConnectionStateChange;

  PeerConnectionManager({
    this.onLocalStream,
    this.onRemoteStream,
    this.onIceCandidate,
    this.onConnectionStateChange,
  });

  // ICE Server configuration with Google STUN + Coturn TURN fallback
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {
        'urls': [
          'turn:veyl.kkdes.co.ke:3478?transport=udp',
          'turn:veyl.kkdes.co.ke:3478?transport=tcp',
        ],
        'username': 'veylturn',
        'credential': 'veylturnpassword',
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  /// Initializes local audio/video media streams and creates RTCPeerConnection.
  Future<void> initialize(CallType callType) async {
    // 1. Audio constraints: Echo cancellation, noise suppression, auto gain control
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
        'highpassFilter': true,
      },
      'video': callType == CallType.video
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
      if (onLocalStream != null && _localStream != null) {
        onLocalStream!(_localStream!);
      }

      // 2. Create PeerConnection with DTLS/SRTP hardware encryption
      _peerConnection = await createPeerConnection(_iceServers);

      // Add local media tracks
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });

      // Handle Remote Stream Track
      _peerConnection!.onTrack = (RTCTrackEvent event) {
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          if (onRemoteStream != null) {
            onRemoteStream!(_remoteStream!);
          }
        }
      };

      // Handle ICE Candidates
      _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        if (onIceCandidate != null) {
          onIceCandidate!(candidate);
        }
      };

      // Handle Connection State Changes (Wi-Fi ↔ 4G ↔ 5G handover)
      _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
        debugPrint('WebRTC Connection State: $state');
        if (onConnectionStateChange != null) {
          onConnectionStateChange!(state);
        }
      };
    } catch (e) {
      debugPrint('PeerConnectionManager initialize error: $e');
      rethrow;
    }
  }

  /// Creates a WebRTC SDP Offer (Caller)
  Future<RTCSessionDescription> createOffer() async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    return offer;
  }

  /// Creates a WebRTC SDP Answer (Callee)
  Future<RTCSessionDescription> createAnswer(RTCSessionDescription offer) async {
    if (_peerConnection == null) throw Exception('PeerConnection not initialized');
    await _peerConnection!.setRemoteDescription(offer);
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    return answer;
  }

  /// Sets Remote SDP Answer
  Future<void> setRemoteAnswer(RTCSessionDescription answer) async {
    if (_peerConnection == null) return;
    await _peerConnection!.setRemoteDescription(answer);
  }

  /// Adds Remote ICE Candidate
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    if (_peerConnection == null) return;
    await _peerConnection!.addCandidate(candidate);
  }

  /// Mutes or unmutes local microphone track
  void setAudioMuted(bool isMuted) {
    if (_localStream != null) {
      for (final track in _localStream!.getAudioTracks()) {
        track.enabled = !isMuted;
      }
    }
  }

  /// Mutes or unmutes local camera track
  void setVideoMuted(bool isMuted) {
    if (_localStream != null) {
      for (final track in _localStream!.getVideoTracks()) {
        track.enabled = !isMuted;
      }
    }
  }

  /// Switches camera (front/rear)
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTracks = _localStream!.getVideoTracks();
      if (videoTracks.isNotEmpty) {
        await Helper.switchCamera(videoTracks[0]);
      }
    }
  }

  /// Toggles Speakerphone
  void setSpeakerphone(bool enable) {
    if (_localStream != null) {
      Helper.setSpeakerphoneOn(enable);
    }
  }

  /// Restarts ICE Gathering when switching network interfaces (Wi-Fi ↔ 4G ↔ 5G)
  Future<void> restartIce() async {
    if (_peerConnection != null) {
      final offer = await _peerConnection!.createOffer({'iceRestart': true});
      await _peerConnection!.setLocalDescription(offer);
    }
  }

  /// Closes and disposes all media streams and peer connections
  Future<void> dispose() async {
    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();
    await _peerConnection?.close();
    _peerConnection = null;
    _localStream = null;
    _remoteStream = null;
  }
}
