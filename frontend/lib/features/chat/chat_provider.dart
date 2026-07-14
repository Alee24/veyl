import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../core/api_client.dart';
import 'socket_service.dart';

final chatProvider = Provider((ref) {
  return ChatRepository(
    ref.read(dioProvider),
    ref.read(socketServiceProvider),
  );
});

class ChatRepository {
  final Dio _dio;
  final SocketService _socketService;

  ChatRepository(this._dio, this._socketService);

  Future<List<dynamic>> getChatHistory(String chatId) async {
    try {
      final response = await _dio.get('/chat/$chatId/history');
      final data = response.data as List<dynamic>;
      // Cache locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('chat_$chatId', jsonEncode(data));
      return data;
    } catch (e) {
      // Fallback to local cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('chat_$chatId');
      if (cached != null) {
        return jsonDecode(cached);
      }
      rethrow;
    }
  }

  Future<void> sendFile(String chatId, String filePath) async {
    // Implement file upload with Dio FormData, then send message via socket with fileUrl
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post('/chat/upload', data: formData);
    final fileUrl = response.data['url'];
    
    // Send socket event
    _socketService.sendMessage(chatId, fileUrl, 'FILE');
  }
}
