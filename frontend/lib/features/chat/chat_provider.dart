import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../core/api_client.dart';
import 'socket_service.dart';

final userChatsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/chat');
  return response.data as List<dynamic>;
});

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

  Future<String> createChatByUsername(String username) async {
    final userResponse = await _dio.get('/users/$username');
    final contactId = userResponse.data['id'];
    
    final chatResponse = await _dio.post('/chat/direct/$contactId');
    return chatResponse.data['id'];
  }

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
      return []; // Return empty list on failure instead of rethrowing
    }
  }

  Future<Response> postMessage(String chatId, String content, String type) async {
    return _dio.post('/chat/$chatId/message', data: {
      'content': content,
      'type': type,
    });
  }

  Future<void> sendFile(String chatId, String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });

    final response = await _dio.post('/chat/upload', data: formData);
    final fileUrl = response.data['url'];
    // Deliver via REST first
    await postMessage(chatId, fileUrl, 'FILE');
    // Notify socket if connected
    _socketService.sendMessage(chatId, fileUrl, 'FILE');
  }
}

class MessagesState {
  final List<dynamic> messages;
  final bool isLoading;
  MessagesState({required this.messages, this.isLoading = false});
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ChatRepository _chatRepository;
  final SocketService _socketService;
  final String _chatId;
  StreamSubscription? _messageSubscription;

  MessagesNotifier(this._chatRepository, this._socketService, this._chatId)
      : super(MessagesState(messages: [], isLoading: true)) {
    _init();
  }

  void _init() async {
    try {
      final history = await _chatRepository.getChatHistory(_chatId);
      state = MessagesState(messages: history, isLoading: false);
    } catch (e) {
      state = MessagesState(messages: [], isLoading: false);
    }

    await _socketService.connect();
    _socketService.joinChat(_chatId);

    _messageSubscription = _socketService.onMessage.listen((msg) {
      // Backend message structure includes chatId
      if (msg['chatId'] == _chatId) {
        // Prevent duplicate messages if already inserted optimistically
        final exists = state.messages.any((m) => m['id'] == msg['id']);
        if (!exists) {
          state = MessagesState(
            messages: [msg, ...state.messages],
            isLoading: false,
          );
        }
      }
    });
  }

  void sendMessage(String content, {String type = 'TEXT'}) async {
    if (content.trim().isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = {
      'id': tempId,
      'chatId': _chatId,
      'content': content,
      'type': type,
      'createdAt': DateTime.now().toIso8601String(),
      'status': 'SENT',
    };

    // Optimistically add to UI state
    state = MessagesState(
      messages: [tempMsg, ...state.messages],
      isLoading: false,
    );

    try {
      final response = await _chatRepository.postMessage(_chatId, content, type);
      final actualMsg = response.data;
      
      // Update with database message
      state = MessagesState(
        messages: state.messages.map((m) => m['id'] == tempId ? actualMsg : m).toList(),
        isLoading: false,
      );

      // Broadcast over Socket
      _socketService.sendMessage(_chatId, content, type);
    } catch (e) {
      state = MessagesState(
        messages: state.messages.map((m) => m['id'] == tempId ? {...m, 'status': 'FAILED'} : m).toList(),
        isLoading: false,
      );
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _socketService.leaveChat(_chatId);
    super.dispose();
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String>((ref, chatId) {
  final chatRepo = ref.read(chatProvider);
  final socketService = ref.read(socketServiceProvider);
  return MessagesNotifier(chatRepo, socketService, chatId);
});
