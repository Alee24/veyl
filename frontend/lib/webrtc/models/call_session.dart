enum CallState {
  idle,
  calling,
  ringing,
  connecting,
  connected,
  reconnecting,
  disconnected,
  muted,
  cameraOff,
  busy,
  declined,
  failed,
}

enum CallType {
  voice,
  video,
}

class CallSession {
  final String id;
  final String peerId;
  final String peerName;
  final String peerUsername;
  final String? peerAvatarUrl;
  final CallType type;
  final CallState state;
  final bool isCaller;
  final bool isAudioMuted;
  final bool isVideoMuted;
  final bool isSpeakerOn;
  final bool isFrontCamera;
  final DateTime? startedAt;
  final int durationSeconds;

  CallSession({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerUsername,
    this.peerAvatarUrl,
    required this.type,
    this.state = CallState.idle,
    required this.isCaller,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
    this.isSpeakerOn = true,
    this.isFrontCamera = true,
    this.startedAt,
    this.durationSeconds = 0,
  });

  CallSession copyWith({
    String? id,
    String? peerId,
    String? peerName,
    String? peerUsername,
    String? peerAvatarUrl,
    CallType? type,
    CallState? state,
    bool? isCaller,
    bool? isAudioMuted,
    bool? isVideoMuted,
    bool? isSpeakerOn,
    bool? isFrontCamera,
    DateTime? startedAt,
    int? durationSeconds,
  }) {
    return CallSession(
      id: id ?? this.id,
      peerId: peerId ?? this.peerId,
      peerName: peerName ?? this.peerName,
      peerUsername: peerUsername ?? this.peerUsername,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      type: type ?? this.type,
      state: state ?? this.state,
      isCaller: isCaller ?? this.isCaller,
      isAudioMuted: isAudioMuted ?? this.isAudioMuted,
      isVideoMuted: isVideoMuted ?? this.isVideoMuted,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      startedAt: startedAt ?? this.startedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
    );
  }
}
