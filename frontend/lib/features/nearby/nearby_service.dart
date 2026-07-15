import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

final nearbyServiceProvider = Provider((ref) {
  return NearbyService(ref);
});

class NearbyPeer {
  final String anonymousId;
  final String ipAddress;
  String? realName;
  String? realUsername;
  bool isConnected;
  bool isIncomingRequest;

  NearbyPeer({
    required this.anonymousId,
    required this.ipAddress,
    this.realName,
    this.realUsername,
    this.isConnected = false,
    this.isIncomingRequest = false,
  });
}

class NearbyService {
  final Ref _ref;
  
  RawDatagramSocket? _udpSocket;
  ServerSocket? _tcpServer;
  
  final String _anonymousId = 'VYL-${Random().nextInt(9000) + 1000}';
  String get anonymousId => _anonymousId;

  // Active discovered peers
  final Map<String, NearbyPeer> _discoveredPeers = {};
  List<NearbyPeer> get discoveredPeers => _discoveredPeers.values.toList();

  // Local P2P Chat Messages
  final List<Map<String, dynamic>> _localMessages = [];
  List<Map<String, dynamic>> get localMessages => _localMessages;

  // Stream Controllers for UI updates
  final _peerStreamController = StreamController<List<NearbyPeer>>.broadcast();
  Stream<List<NearbyPeer>> get onPeersChanged => _peerStreamController.stream;

  final _msgStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  Stream<List<Map<String, dynamic>>> get onMessagesChanged => _msgStreamController.stream;

  final _handshakeRequestController = StreamController<NearbyPeer>.broadcast();
  Stream<NearbyPeer> get onHandshakeReceived => _handshakeRequestController.stream;

  Timer? _broadcastTimer;
  Socket? _activePeerSocket;

  NearbyService(this._ref);

  Future<void> startOfflineMode() async {
    await stopOfflineMode();
    _discoveredPeers.clear();
    _localMessages.clear();
    _peerStreamController.add([]);

    try {
      // 1. Bind UDP Socket for Discovery (Port 4545)
      _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4545);
      _udpSocket!.broadcastEnabled = true;
      
      _udpSocket!.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = _udpSocket!.receive();
          if (datagram != null) {
            try {
              final data = jsonDecode(utf8.decode(datagram.data));
              if (data['anonymousId'] != null && data['anonymousId'] != _anonymousId) {
                final peerIp = datagram.address.address;
                final peerId = data['anonymousId'];
                
                if (!_discoveredPeers.containsKey(peerId)) {
                  _discoveredPeers[peerId] = NearbyPeer(
                    anonymousId: peerId,
                    ipAddress: peerIp,
                  );
                  _peerStreamController.add(discoveredPeers);
                }
              }
            } catch (_) {}
          }
        }
      });

      // 2. Start Periodic Broadcast (Every 2 seconds)
      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        final packet = jsonEncode({'anonymousId': _anonymousId});
        final bytes = utf8.encode(packet);
        _udpSocket?.send(bytes, InternetAddress('255.255.255.255'), 4545);
      });

      // 3. Bind TCP Server for peer connections (Port 4546)
      _tcpServer = await ServerSocket.bind(InternetAddress.anyIPv4, 4546);
      _tcpServer!.listen(_handleIncomingTcpConnection);

    } catch (e) {
      debugPrint('Failed to start P2P offline service: $e');
    }
  }

  void _handleIncomingTcpConnection(Socket clientSocket) {
    clientSocket.listen((bytes) {
      try {
        final payload = jsonDecode(utf8.decode(bytes));
        final String action = payload['action'] ?? '';

        if (action == 'handshake_request') {
          final peer = NearbyPeer(
            anonymousId: payload['anonymousId'],
            ipAddress: clientSocket.remoteAddress.address,
            realName: payload['senderName'],
            realUsername: payload['senderUsername'],
            isIncomingRequest: true,
          );
          _discoveredPeers[peer.anonymousId] = peer;
          _peerStreamController.add(discoveredPeers);
          
          _activePeerSocket = clientSocket;
          _handshakeRequestController.add(peer);
        } else if (action == 'message') {
          // Received direct message
          _addLocalMessage(
            sender: payload['sender'],
            content: payload['content'],
          );
        }
      } catch (_) {}
    });
  }

  Future<void> sendHandshakeRequest(NearbyPeer peer) async {
    final profileAsync = _ref.read(userProfileProvider);
    final myName = profileAsync.value?['displayName'] ?? 'User';
    final myUsername = profileAsync.value?['username'] ?? 'user';

    try {
      final Socket socket = await Socket.connect(peer.ipAddress, 4546);
      _activePeerSocket = socket;

      // Listen for accept/decline response
      socket.listen((bytes) {
        try {
          final payload = jsonDecode(utf8.decode(bytes));
          if (payload['action'] == 'handshake_accepted') {
            peer.isConnected = true;
            peer.realName = payload['responderName'];
            peer.realUsername = payload['responderUsername'];
            _peerStreamController.add(discoveredPeers);
          }
        } catch (_) {}
      });

      final request = jsonEncode({
        'action': 'handshake_request',
        'anonymousId': _anonymousId,
        'senderName': myName,
        'senderUsername': myUsername,
      });
      socket.write(request);
    } catch (e) {
      debugPrint('Handshake connect failed: $e');
    }
  }

  void acceptHandshake(NearbyPeer peer) {
    final profileAsync = _ref.read(userProfileProvider);
    final myName = profileAsync.value?['displayName'] ?? 'User';
    final myUsername = profileAsync.value?['username'] ?? 'user';

    if (_activePeerSocket != null) {
      final response = jsonEncode({
        'action': 'handshake_accepted',
        'responderName': myName,
        'responderUsername': myUsername,
      });
      _activePeerSocket!.write(response);
      
      peer.isConnected = true;
      _peerStreamController.add(discoveredPeers);
    }
  }

  void declineHandshake(NearbyPeer peer) {
    if (_activePeerSocket != null) {
      final response = jsonEncode({
        'action': 'handshake_declined',
      });
      _activePeerSocket!.write(response);
      _activePeerSocket!.destroy();
      _activePeerSocket = null;
    }
    peer.isIncomingRequest = false;
    _peerStreamController.add(discoveredPeers);
  }

  void sendOfflineMessage(NearbyPeer peer, String content) {
    if (_activePeerSocket != null) {
      final profileAsync = _ref.read(userProfileProvider);
      final myUsername = profileAsync.value?['username'] ?? 'user';

      final msgPacket = jsonEncode({
        'action': 'message',
        'sender': myUsername,
        'content': content,
      });
      _activePeerSocket!.write(msgPacket);

      _addLocalMessage(sender: myUsername, content: content);

      // Save to local offline queue to sync later when internet is back
      _queueOfflineMessage(
        sender: myUsername,
        receiver: peer.realUsername ?? 'unknown',
        content: content,
      );
    }
  }

  void _addLocalMessage({required String sender, required String content}) {
    _localMessages.add({
      'sender': sender,
      'content': content,
      'createdAt': DateTime.now().toIso8601String(),
    });
    _msgStreamController.add(List.from(_localMessages));
  }

  void _queueOfflineMessage({
    required String sender,
    required String receiver,
    required String content,
  }) {
    // Queue offline message locally to sync later when internet is back
  }

  Future<void> syncOfflineMessages() async {
    // When internet is restored, sync queued messages back to the server
    // For each queued item: await dio.post('/chat/direct/:contactId/message', ...)
  }

  Future<void> stopOfflineMode() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    
    _udpSocket?.close();
    _udpSocket = null;

    _activePeerSocket?.destroy();
    _activePeerSocket = null;

    await _tcpServer?.close();
    _tcpServer = null;
  }
}
