import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../auth/auth_provider.dart';
import '../../calling/call_service.dart';
import '../../chat/chat_provider.dart';
import '../../calling/room_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

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
    final profilePhotoUrl = profileAsync.value?['profilePhotoUrl'];
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
                    backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                        ? NetworkImage('${getBaseUrl()}$profilePhotoUrl')
                        : NetworkImage('https://i.pravatar.cc/150?u=$username') as ImageProvider,
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
                  onTap: () => _showCreateRoomDialog(context, ref),
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

void _showCreateRoomDialog(BuildContext context, WidgetRef ref) {
  final theme = Theme.of(context);
  final roomNameController = TextEditingController(text: 'Breakout Room');
  String roomType = 'PERMANENT';
  int durationHours = 1;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF161825),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Create Breakout Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Room Name', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: roomNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter room name',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Room Type', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Permanent'),
                          selected: roomType == 'PERMANENT',
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(color: roomType == 'PERMANENT' ? Colors.white : Colors.grey),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          onSelected: (val) {
                            if (val) setState(() => roomType = 'PERMANENT');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Temporary'),
                          selected: roomType == 'TEMPORARY',
                          selectedColor: theme.colorScheme.primary,
                          labelStyle: TextStyle(color: roomType == 'TEMPORARY' ? Colors.white : Colors.grey),
                          backgroundColor: Colors.white.withOpacity(0.05),
                          onSelected: (val) {
                            if (val) setState(() => roomType = 'TEMPORARY');
                          },
                        ),
                      ),
                    ],
                  ),
                  if (roomType == 'TEMPORARY') ...[
                    const SizedBox(height: 16),
                    const Text('Expiration Duration', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: durationHours,
                          dropdownColor: const Color(0xFF161825),
                          isExpanded: true,
                          style: const TextStyle(color: Colors.white),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('1 Hour')),
                            DropdownMenuItem(value: 2, child: Text('2 Hours')),
                            DropdownMenuItem(value: 6, child: Text('6 Hours')),
                            DropdownMenuItem(value: 12, child: Text('12 Hours')),
                            DropdownMenuItem(value: 24, child: Text('1 Day (24h)')),
                            DropdownMenuItem(value: 72, child: Text('3 Days')),
                            DropdownMenuItem(value: 168, child: Text('7 Days')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => durationHours = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  final name = roomNameController.text.trim();
                  if (name.isEmpty) return;
                  Navigator.pop(context);
                  _handleCreateRoom(context, ref, name, roomType, durationHours);
                },
              ),
            ],
          );
        },
      );
    },
  );
}

void _handleCreateRoom(BuildContext context, WidgetRef ref, String name, String type, int durationHours) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final room = await ref.read(roomServiceProvider).createRoom(
      name,
      type,
      durationHours: type == 'TEMPORARY' ? durationHours : null,
    );
    
    if (context.mounted) Navigator.pop(context); // Pop spinner
    
    final String roomId = room['id'];
    final String roomUrl = 'https://veyl.kkdes.co.ke/app.html#/room/$roomId';
    
    if (!context.mounted) return;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161825),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Room is Ready!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Anyone with this link or QR can join as a guest listener without logging in.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: roomUrl,
                  version: QrVersions.auto,
                  size: 160.0,
                  gapless: false,
                  embeddedImage: const NetworkImage('https://veyl.kkdes.co.ke/app_icon.png'),
                  embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(32, 32)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                type == 'TEMPORARY' ? 'Expires in $durationHours hour(s)' : 'Permanent Room',
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Share Invite', style: TextStyle(color: Colors.white70)),
              onPressed: () async {
                await Share.share(
                  'Join my Veyl breakout room "$name"! Scan the QR or open the link to listen in: $roomUrl',
                  subject: 'Veyl Breakout Room Invite',
                );
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Join Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                context.push('/room/$roomId');
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    if (context.mounted) Navigator.pop(context); // Pop spinner
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
    }
  }
}
