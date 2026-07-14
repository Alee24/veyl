import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../calling/call_service.dart';

class ChatScreen extends ConsumerWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamically set names and avatars based on chatId
    String displayName = chatId;
    String avatarUrl = 'https://i.pravatar.cc/150?u=default';

    if (chatId == 'sarah-johnson') {
      displayName = 'Sarah Johnson';
      avatarUrl = 'https://i.pravatar.cc/150?u=1';
    } else if (chatId == 'design-team') {
      displayName = 'Design Team';
      avatarUrl = 'https://i.pravatar.cc/150?u=2';
    } else if (chatId == 'mike-williams') {
      displayName = 'Mike Williams';
      avatarUrl = 'https://i.pravatar.cc/150?u=3';
    } else if (chatId == 'project-galaxy') {
      displayName = 'Project Galaxy';
      avatarUrl = 'https://i.pravatar.cc/150?u=4';
    } else {
      // Title case
      displayName = chatId.split('-').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
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
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.call, color: theme.colorScheme.primary),
            onPressed: () => ref.read(callServiceProvider).joinVideoCall('voice-$chatId', 'ametto', ''),
          ),
          IconButton(
            icon: Icon(Icons.videocam, color: theme.colorScheme.primary),
            onPressed: () => ref.read(callServiceProvider).joinVideoCall('video-$chatId', 'ametto', ''),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Today', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMessageBubble(context, 'Hey Alex! 👋', '9:30 AM', false),
                _buildMessageBubble(context, 'How are you?', '9:30 AM', false),
                _buildMessageBubble(context, 'I\'m good! How about you?', '9:31 AM', true, isRead: true),
                _buildMessageBubble(context, 'Great! Can we hop on a quick video call later?', '9:31 AM', false),
                _buildMessageBubble(context, 'Sure! Let\'s do it at 3 PM', '9:32 AM', true, isRead: true),
                
                // Voice Note bubble placeholder
                _buildVoiceNoteBubble(context, '0:18', '9:32 AM', false),
                
                // Image bubble placeholder
                _buildImageBubble(context, 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=500&q=80', '9:33 AM', true, isRead: true),
              ],
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
                const Icon(Icons.add, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: TextStyle(color: theme.colorScheme.onBackground),
                    decoration: const InputDecoration(
                      hintText: 'Message...',
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const Icon(Icons.emoji_emotions_outlined, color: Colors.grey),
                const SizedBox(width: 16),
                const Icon(Icons.mic_none, color: Colors.grey),
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
          crossAxisAlignment: CrossAxisAlignment.end,
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

  Widget _buildVoiceNoteBubble(BuildContext context, String duration, String time, bool isMe) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_fill, color: isMe ? Colors.white : theme.colorScheme.primary, size: 36),
            const SizedBox(width: 8),
            const Text('Voice Note', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(width: 16),
            Text(duration, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageBubble(BuildContext context, String imageUrl, String time, bool isMe, {bool isRead = false}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(imageUrl, fit: BoxFit.cover),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(time, style: const TextStyle(color: Colors.white, fontSize: 10)),
                    if (isMe) const SizedBox(width: 4),
                    if (isMe) Icon(Icons.done_all, size: 12, color: isRead ? Colors.white : Colors.white54),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
