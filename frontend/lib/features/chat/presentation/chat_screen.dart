import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../calling/call_service.dart';
import '../../auth/auth_provider.dart';
import '../chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    ref.read(messagesProvider(widget.chatId).notifier).sendMessage(text);
    _messageController.clear();
    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatMessageTime(String createdAtString) {
    try {
      final dateTime = DateTime.parse(createdAtString).toLocal();
      final hour = dateTime.hour > 12 ? dateTime.hour - 12 : (dateTime.hour == 0 ? 12 : dateTime.hour);
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = dateTime.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final messagesState = ref.watch(messagesProvider(widget.chatId));
    final profileAsync = ref.watch(userProfileProvider);
    
    final currentUserId = profileAsync.value?['userId'] ?? '';
    final currentUsername = profileAsync.value?['username'] ?? 'Guest';
    
    // Dynamically set names and avatars based on chatId
    String displayName = widget.chatId;
    String avatarUrl = 'https://i.pravatar.cc/150?u=default';

    if (widget.chatId == 'sarah-johnson') {
      displayName = 'Sarah Johnson';
      avatarUrl = 'https://i.pravatar.cc/150?u=1';
    } else if (widget.chatId == 'design-team') {
      displayName = 'Design Team';
      avatarUrl = 'https://i.pravatar.cc/150?u=2';
    } else if (widget.chatId == 'mike-williams') {
      displayName = 'Mike Williams';
      avatarUrl = 'https://i.pravatar.cc/150?u=3';
    } else if (widget.chatId == 'project-galaxy') {
      displayName = 'Project Galaxy';
      avatarUrl = 'https://i.pravatar.cc/150?u=4';
    } else {
      // Title case
      displayName = widget.chatId.split('-').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
      avatarUrl = 'https://i.pravatar.cc/150?u=${widget.chatId}';
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(avatarUrl),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.green, size: 8),
                      const SizedBox(width: 4),
                      Text('Online', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: theme.colorScheme.primary),
            onPressed: () => ref.read(callServiceProvider).joinVideoCall('voice-${widget.chatId}', currentUsername, ''),
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: theme.colorScheme.primary),
            onPressed: () => ref.read(callServiceProvider).joinVideoCall('video-${widget.chatId}', currentUsername, ''),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messagesState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: theme.dividerColor.withOpacity(0.3)),
                            const SizedBox(height: 12),
                            Text(
                              'No messages yet\nSay hello to start the conversation!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: theme.disabledColor),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Messages load newest-first for chat look
                        padding: const EdgeInsets.all(16),
                        itemCount: messagesState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = messagesState.messages[index];
                          final isMe = msg['senderId'] == currentUserId || msg['sender']?['id'] == currentUserId;
                          final content = msg['content'] ?? '';
                          final timeString = _formatMessageTime(msg['createdAt'] ?? DateTime.now().toIso8601String());
                          final isRead = msg['status'] == 'READ';

                          return _buildMessageBubble(
                            context,
                            content,
                            timeString,
                            isMe,
                            isRead: isRead,
                          );
                        },
                      ),
          ),
          
          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add, color: Colors.grey),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: theme.colorScheme.onBackground),
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.send, color: theme.colorScheme.primary),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, String text, String time, bool isMe, {bool isRead = false}) {
    final theme = Theme.of(context);
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.05),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onBackground),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    color: isMe ? Colors.white70 : Colors.grey,
                    fontSize: 10,
                  ),
                ),
                if (isMe) const SizedBox(width: 4),
                if (isMe) Icon(Icons.done_all, size: 12, color: isRead ? Colors.white : Colors.white54),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
