import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../auth/auth_provider.dart';
import '../../calling/call_service.dart';
import '../../chat/chat_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileProvider);
    final username = profileAsync.value?['username'] ?? 'Guest';
    final displayName = profileAsync.value?['displayName'] ?? 'Guest User';
    final currentUserId = profileAsync.value?['userId'] ?? '';
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: theme.iconTheme.color),
            onPressed: () => context.push('/scan'),
          ),
          IconButton(
            icon: Icon(Icons.notifications_none, color: theme.iconTheme.color),
            onPressed: () => context.go('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark
                    ? null
                    : [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                border: isDark ? Border.all(color: Colors.white10) : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$username'),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                        Text(
                          '@$username',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.circle, color: Colors.green, size: 10),
                            SizedBox(width: 4),
                            Text('Online', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.qr_code, color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Your Link Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: Colors.white10) : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your link', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        'veyl.kkdes.co.ke/$username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      foregroundColor: theme.colorScheme.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: const Text('Share'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Theme Option Selector Widget
            const Text(
              'Theme Mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.light,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: themeMode == ThemeMode.light
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.light_mode,
                              color: themeMode == ThemeMode.light ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Light',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: themeMode == ThemeMode.light ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: themeMode == ThemeMode.dark
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.dark_mode,
                              color: themeMode == ThemeMode.dark ? Colors.white : Colors.grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dark',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: themeMode == ThemeMode.dark ? Colors.white : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionItem(
                  context,
                  Icons.chat_bubble_outline,
                  'New Chat',
                  onTap: () => context.go('/chats'),
                ),
                _buildActionItem(
                  context,
                  Icons.call_outlined,
                  'Voice Call',
                  onTap: () => ref.read(callServiceProvider).joinVideoCall('voice-call', 'ametto', ''),
                ),
                _buildActionItem(
                  context,
                  Icons.videocam_outlined,
                  'Video Call',
                  onTap: () => ref.read(callServiceProvider).joinVideoCall('video-call', 'ametto', ''),
                ),
                _buildActionItem(
                  context,
                  Icons.group_add_outlined,
                  'Create Room',
                  onTap: () => ref.read(callServiceProvider).joinVideoCall('meeting-room', 'ametto', ''),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Recent Chats Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Chats',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: theme.colorScheme.onBackground,
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/chats'),
                  child: const Text('See all >', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),

            // Recent Chats List (Exposes real chats, handles empty placeholder)
            chatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Text('Failed to load recent chats', style: TextStyle(color: Colors.grey)),
              data: (chats) {
                if (chats.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: Center(
                      child: Text(
                        'No recent chats yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                
                final recentChats = chats.take(4).toList();
                
                return Column(
                  children: recentChats.map((chat) {
                    final participants = chat['participants'] as List<dynamic>;
                    final otherParticipant = participants.firstWhere(
                      (p) => p['userId'] != currentUserId,
                      orElse: () => null,
                    );
                    if (otherParticipant == null) return const SizedBox.shrink();
                    
                    final otherUser = otherParticipant['user'];
                    final String otherUsername = otherUser['username'] ?? 'User';
                    final String otherDisplayName = otherUser['displayName'] ?? otherUsername;
                    
                    final messages = chat['messages'] as List<dynamic>?;
                    final lastMsg = messages != null && messages.isNotEmpty ? messages[0] : null;
                    final String lastMessageText = lastMsg?['content'] ?? 'No messages yet';
                    
                    String formatTime(String? dateStr) {
                      if (dateStr == null) return '';
                      try {
                        final date = DateTime.parse(dateStr).toLocal();
                        final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
                        final minute = date.minute.toString().padLeft(2, '0');
                        final period = date.hour >= 12 ? 'PM' : 'AM';
                        return '$hour:$minute $period';
                      } catch (_) {
                        return '';
                      }
                    }
                    
                    return _buildChatTile(
                      context,
                      otherDisplayName,
                      lastMessageText,
                      formatTime(lastMsg?['createdAt']),
                      0,
                      'https://i.pravatar.cc/150?u=$otherUsername',
                      onTap: () => context.push('/chat/${chat['id']}'),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, IconData icon, String label, {required VoidCallback onTap}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    String name,
    String message,
    String time,
    int unread,
    String avatarUrl, {
    bool isVoice = false,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground),
      ),
      subtitle: Row(
        children: [
          if (isVoice) const Icon(Icons.mic, size: 14, color: Colors.grey),
          if (isVoice) const SizedBox(width: 4),
          Text(
            message,
            style: TextStyle(color: message == 'Typing...' ? Colors.green : Colors.grey),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
              child: Text(
                unread.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
