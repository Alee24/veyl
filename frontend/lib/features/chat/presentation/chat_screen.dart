import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import '../../../core/api_client.dart';
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
  bool _showEmojis = false;

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
    setState(() {
      _showEmojis = false;
    });
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

  void _pickAndSendFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading attachment...')),
        );
        await ref.read(chatProvider).sendFile(widget.chatId, filePath);
        ref.invalidate(messagesProvider(widget.chatId));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send file: $e')),
      );
    }
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(offset: selection.start + emoji.length);
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
      displayName = widget.chatId.split('-').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
      avatarUrl = 'https://i.pravatar.cc/150?u=${widget.chatId}';
    }

    final commonEmojis = ['😀', '😂', '👍', '❤️', '🔥', '🙌', '🎉', '😎', '😢', '😮', '🙏', '✨'];

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
                        reverse: true,
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
          
          // Quick Emojis Selection Row
          if (_showEmojis)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: theme.cardColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: commonEmojis.map((emoji) => GestureDetector(
                  onTap: () => _insertEmoji(emoji),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                )).toList(),
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
                  onPressed: _pickAndSendFile,
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
                  icon: Icon(
                    _showEmojis ? Icons.keyboard : Icons.emoji_emotions_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _showEmojis = !_showEmojis;
                    });
                  },
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
    final isFile = text.startsWith('/uploads/');
    
    Widget contentWidget;
    if (isFile) {
      final fileUrl = '${getBaseUrl()}$text';
      final fileName = text.substring(text.lastIndexOf('/') + 1);
      final extension = text.split('.').last.toLowerCase();
      
      final isImage = ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(extension);
      final isVideo = ['mp4', 'mov', 'avi', 'mkv'].contains(extension);
      
      if (isImage) {
        contentWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            fileUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const SizedBox(
                width: 150,
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Text('[Image failed to load]'),
          ),
        );
      } else if (isVideo) {
        contentWidget = Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_circle_fill, color: Colors.white, size: 36),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      } else {
        // General File
        contentWidget = Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isMe ? Colors.black12 : Colors.white10,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.grey, size: 32),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onBackground),
                ),
              ),
            ],
          ),
        );
      }
    } else {
      final String trimmed = text.trim();
      final Map<String, String> animatedEmojiMap = {
        '😀': '1f600',
        '😂': '1f602',
        '👍': '1f44d',
        '❤️': '2764_fe0f',
        '🔥': '1f525',
        '🙌': '1f64c',
        '🎉': '1f389',
        '😎': '1f60e',
        '😢': '1f622',
        '😮': '1f62e',
        '🙏': '1f64f',
        '✨': '2728',
      };
      
      if (animatedEmojiMap.containsKey(trimmed)) {
        final codepoint = animatedEmojiMap[trimmed];
        contentWidget = SizedBox(
          width: 80,
          height: 80,
          child: Lottie.network(
            'https://fonts.gstatic.com/s/e/notoemoji/latest/$codepoint/lottie.json',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Text(
              text,
              style: TextStyle(
                color: isMe ? Colors.white : theme.colorScheme.onBackground,
                fontSize: 32,
              ),
            ),
          ),
        );
      } else {
        contentWidget = Text(
          text,
          style: TextStyle(color: isMe ? Colors.white : theme.colorScheme.onBackground),
        );
      }
    }

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
            contentWidget,
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
