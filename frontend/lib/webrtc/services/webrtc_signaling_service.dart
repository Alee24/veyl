import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chat/socket_service.dart';

final webrtcSignalingProvider = Provider((ref) {
  return WebRTCSignalingService(ref.read(socketServiceProvider));
});

class WebRTCSignalingService {
  final SocketService _socketService;

  WebRTCSignalingService(this._socketService);

  Stream<Map<String, dynamic>> get onCallIncoming => _socketService.onCallIncoming;
  Stream<Map<String, dynamic>> get onCallAccepted => _socketService.onCallAccepted;
  Stream<Map<String, dynamic>> get onCallDeclined => _socketService.onCallDeclined;
  Stream<Map<String, dynamic>> get onCallCancelled => _socketService.onCallCancelled;
  Stream<Map<String, dynamic>> get onWebRTCOffer => _socketService.onWebRTCOffer;
  Stream<Map<String, dynamic>> get onWebRTCAnswer => _socketService.onWebRTCAnswer;
  Stream<Map<String, dynamic>> get onWebRTCIceCandidate => _socketService.onWebRTCIceCandidate;
  Stream<Map<String, dynamic>> get onCallEnded => _socketService.onCallEnded;

  void startCall({
    required String targetUserId,
    required String roomName,
    required String callerName,
    required String callerUsername,
  }) {
    _socketService.makeCall(
      targetUserId: targetUserId,
      roomName: roomName,
      callerName: callerName,
      callerUsername: callerUsername,
    );
  }

  void acceptCall(String callerId) {
    _socketService.acceptCall(callerId);
  }

  void declineCall(String callerId) {
    _socketService.declineCall(callerId);
  }

  void cancelCall(String targetUserId) {
    _socketService.cancelCall(targetUserId);
  }

  void sendOffer(String targetUserId, dynamic sdp) {
    _socketService.sendWebRTCOffer(targetUserId, sdp);
  }

  void sendAnswer(String targetUserId, dynamic sdp) {
    _socketService.sendWebRTCAnswer(targetUserId, sdp);
  }

  void sendIceCandidate(String targetUserId, dynamic candidate) {
    _socketService.sendWebRTCIceCandidate(targetUserId, candidate);
  }

  void endCall(String targetUserId) {
    _socketService.endCall(targetUserId);
  }
}
