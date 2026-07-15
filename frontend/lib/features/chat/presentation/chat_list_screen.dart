import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  void _showAddChatDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161825),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter contact username...',
              hintStyle: const TextStyle(color: Colors.white38),
              prefixText: '@ ',
              prefixStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5D3FD3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Chat', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                final username = controller.text.trim();
                if (username.isEmpty) return;
                try {
                  final chatId = await ref.read(chatProvider).createChatByUsername(username);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(userChatsProvider); // Refresh list
                    context.push('/chat/$chatId');
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not found or chat initialization failed')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final chatsAsync = ref.watch(userChatsProvider);
    final profileAsync = ref.watch(userProfileProvider);
    
    final currentUserId = profileAsync.value?['userId'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 32),
            onPressed: () => _showAddChatDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              style: TextStyle(color: theme.colorScheme.onBackground),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: theme.dividerColor.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildChip(context, 'All', isSelected: true),
                const SizedBox(width: 8),
                _buildChip(context, 'Unread'),
                const SizedBox(width: 8),
                _buildChip(context, 'Groups'),
                const SizedBox(width: 8),
                _buildChip(context, 'Favorites'),
              ],
            ),
          ),
          
          // Chat List
          Expanded(
            child: chatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Failed to load chats', style: TextStyle(color: theme.disabledColor)),
              ),
              data: (chats) {
                if (chats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: theme.dividerColor.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No active chats yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Text(
                            'Scan a QR code or tap the "+" icon at the top to start chatting with your contacts securely!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: theme.disabledColor),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    
                    // Find the other participant user object
                    final participants = chat['participants'] as List<dynamic>;
                    final otherParticipant = participants.firstWhere(
                      (p) => p['userId'] != currentUserId,
                      orElse: () => null,
                    );
                    
                    if (otherParticipant == null) return const SizedBox.shrink();
                    
                    final otherUser = otherParticipant['user'];
                    final String otherUsername = otherUser['username'] ?? 'User';
                    final String otherDisplayName = otherUser['displayName'] ?? otherUsername;
                    final String avatarUrl = 'https://i.pravatar.cc/150?u=$otherUsername';
                    
                    // Last message details
                    final messages = chat['messages'] as List<dynamic>?;
                    final lastMsg = messages != null && messages.isNotEmpty ? messages[0] : null;
                    final String lastMessageText = lastMsg?['content'] ?? 'No messages yet';
                    final String time = lastMsg != null ? _formatMessageTime(lastMsg['createdAt']) : '';
                    final bool isUnread = lastMsg != null && lastMsg['senderId'] != currentUserId && lastMsg['status'] != 'READ';

                    return ListTile(
                      onTap: () => context.push('/chat/${chat['id']}'),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                      title: Text(
                        otherDisplayName,
                        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground),
                      ),
                      subtitle: Text(
                        lastMessageText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: isUnread ? theme.colorScheme.onBackground : Colors.grey),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          if (isUnread)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, {bool isSelected = false}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onBackground.withOpacity(0.8),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
