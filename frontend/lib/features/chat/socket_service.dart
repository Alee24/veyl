import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import 'dart:async';

final socketServiceProvider = Provider((ref) {
  return SocketService(ref);
});

class SocketService {
  IO.Socket? _socket;
  final Ref _ref;

  final StreamController<Map<String, dynamic>> _messageController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  final StreamController<Map<String, dynamic>> _typingController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onTyping => _typingController.stream;

  // Call Signaling Streams
  final StreamController<Map<String, dynamic>> _callIncomingController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onCallIncoming => _callIncomingController.stream;

  final StreamController<Map<String, dynamic>> _callAcceptedController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onCallAccepted => _callAcceptedController.stream;

  final StreamController<Map<String, dynamic>> _callDeclinedController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onCallDeclined => _callDeclinedController.stream;

  final StreamController<Map<String, dynamic>> _callCancelledController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onCallCancelled => _callCancelledController.stream;

  // WebRTC Signaling Streams
  final StreamController<Map<String, dynamic>> _webrtcOfferController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onWebRTCOffer => _webrtcOfferController.stream;

  final StreamController<Map<String, dynamic>> _webrtcAnswerController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onWebRTCAnswer => _webrtcAnswerController.stream;

  final StreamController<Map<String, dynamic>> _webrtcIceCandidateController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onWebRTCIceCandidate => _webrtcIceCandidateController.stream;

  final StreamController<Map<String, dynamic>> _callEndedController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onCallEnded => _callEndedController.stream;

  SocketService(this._ref);

  IO.Socket? get socket => _socket;

  Future<void> connect() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'accessToken');

    if (_socket != null && _socket!.connected) {
      return;
    }

    if (_socket != null) {
      _socket!.dispose();
      _socket = null;
    }

    _socket = IO.io(getBaseUrl(), IO.OptionBuilder()
      .setTransports(['websocket', 'polling'])
      .enableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(9999)
      .setReconnectionDelay(1000)
      .setAuth({'token': token})
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('⚡ Connected to Socket.IO signaling server');
    });

    _socket!.on('new_message', (data) {
      _messageController.add(data);
    });

    _socket!.on('user_typing', (data) {
      _typingController.add(data);
    });

    // Call Signaling listeners
    _socket!.on('call_incoming', (data) {
      _callIncomingController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('call_accepted', (data) {
      _callAcceptedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('call_declined', (data) {
      _callDeclinedController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('call_cancelled', (data) {
      _callCancelledController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('webrtc_offer', (data) {
      _webrtcOfferController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('webrtc_answer', (data) {
      _webrtcAnswerController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('webrtc_ice_candidate', (data) {
      _webrtcIceCandidateController.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('call_ended', (data) {
      _callEndedController.add(Map<String, dynamic>.from(data));
    });
  }

  void joinChat(String chatId) {
    _socket?.emit('join_chat', chatId);
  }

  void leaveChat(String chatId) {
    _socket?.emit('leave_chat', chatId);
  }

  void sendMessage(String chatId, String content, String type) {
    _socket?.emit('send_message', {
      'chatId': chatId,
      'content': content,
      'type': type,
    });
  }

  void broadcastMessage(String chatId, dynamic message) {
    _socket?.emit('send_message', {
      'chatId': chatId,
      'message': message,
    });
  }

  void sendTyping(String chatId, bool isTyping) {
    _socket?.emit('typing', {
      'chatId': chatId,
      'isTyping': isTyping,
    });
  }

  // Call Signaling Emits
  void makeCall({
    required String targetUserId,
    required String roomName,
    required String callerName,
    required String callerUsername,
  }) {
    _socket?.emit('make_call', {
      'targetUserId': targetUserId,
      'roomName': roomName,
      'callerName': callerName,
      'callerUsername': callerUsername,
    });
  }

  void acceptCall(String callerId) {
    _socket?.emit('accept_call', {
      'callerId': callerId,
    });
  }

  void declineCall(String callerId) {
    _socket?.emit('decline_call', {
      'callerId': callerId,
    });
  }

  void cancelCall(String targetUserId) {
    _socket?.emit('cancel_call', {
      'targetUserId': targetUserId,
    });
  }

  void sendWebRTCOffer(String targetUserId, dynamic sdp) {
    _socket?.emit('webrtc_offer', {
      'targetUserId': targetUserId,
      'sdp': sdp,
    });
  }

  void sendWebRTCAnswer(String targetUserId, dynamic sdp) {
    _socket?.emit('webrtc_answer', {
      'targetUserId': targetUserId,
      'sdp': sdp,
    });
  }

  void sendWebRTCIceCandidate(String targetUserId, dynamic candidate) {
    _socket?.emit('webrtc_ice_candidate', {
      'targetUserId': targetUserId,
      'candidate': candidate,
    });
  }

  void endCall(String targetUserId) {
    _socket?.emit('end_call', {
      'targetUserId': targetUserId,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
