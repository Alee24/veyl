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

  SocketService(this._ref);

  Future<void> connect() async {
    final storage = _ref.read(secureStorageProvider);
    final token = await storage.read(key: 'accessToken');

    _socket = IO.io(getBaseUrl(), IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .setAuth({'token': token})
      .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      print('Connected to Socket.IO');
    });

    _socket!.on('new_message', (data) {
      _messageController.add(data);
    });

    _socket!.on('user_typing', (data) {
      _typingController.add(data);
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

  void sendTyping(String chatId, bool isTyping) {
    _socket?.emit('typing', {
      'chatId': chatId,
      'isTyping': isTyping,
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket = null;
  }
}
