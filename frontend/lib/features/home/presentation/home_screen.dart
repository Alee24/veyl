import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/auth_provider.dart';
import '../../chat/chat_provider.dart';
import '../../../core/widgets/veyl_logo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final profileAsync = ref.watch(userProfileProvider);
    final username = profileAsync.value?['username'] ?? 'guest';
    final displayName = profileAsync.value?['displayName'] ?? 'Veyl User';
    final currentUserId = profileAsync.value?['userId'] ?? '';
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFB),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            const VeylLogoWidget(size: 32.0, animateOnStart: false),
            const SizedBox(width: 8),
            Text(
              'Veyl',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          // Search Icon
          _buildAppBarAction(
            icon: Icons.search,
            isDark: isDark,
            onTap: () => context.push('/calls'),
          ),
          const SizedBox(width: 8),
          // Scan Icon
          _buildAppBarAction(
            icon: Icons.qr_code_scanner,
            isDark: isDark,
            onTap: () => context.push('/scan'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Welcome Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0B132B), // Very dark navy
                    Color(0xFF1C2541), // Deep navy
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Stack(
                children: [
                  Row(
                    children: [
                      // Avatar on a dark gradient background with a green dot
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF00F2FE),
                                  theme.colorScheme.secondary,
                                ],
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: const Color(0xFF0B132B),
                              child: ClipOval(
                                child: Image.network(
                                  'https://i.pravatar.cc/150?u=$username',
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 15,
                              height: 15,
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981), // Success online green
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0B132B), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Text info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Welcome back,',
                              style: TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Privacy shield row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00F2FE).withOpacity(0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.shield_outlined,
                                    color: Color(0xFF00F2FE),
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your privacy is protected',
                                        style: TextStyle(
                                          color: Color(0xFF00F2FE),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'End-to-end encrypted',
                                        style: TextStyle(
                                          color: Colors.white38,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // More settings dots
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white70),
                      onPressed: () => context.push('/settings'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. Quick Actions Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionItem(
                    icon: Icons.chat_bubble_outline,
                    label: 'New Chat',
                    onTap: () => context.go('/chats'),
                    theme: theme,
                  ),
                  _buildQuickActionItem(
                    icon: Icons.videocam_outlined,
                    label: 'Start Call',
                    onTap: () => context.go('/calls'),
                    theme: theme,
                  ),
                  _buildQuickActionItem(
                    icon: Icons.group_outlined,
                    label: 'New Group',
                    onTap: () => context.go('/chats'),
                    theme: theme,
                  ),
                  _buildQuickActionItem(
                    icon: Icons.link,
                    label: 'Invite Link',
                    onTap: () => context.push('/disposable_links'),
                    theme: theme,
                  ),
                  _buildQuickActionItem(
                    icon: Icons.qr_code_2,
                    label: 'My QR Code',
                    onTap: () => context.go('/profile'),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Stories Labeled Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Stories',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Row(
                    children: [
                      Text('View all', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.secondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stories Horizontal List
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: [
                  // My Story (with blue plus badge)
                  _buildStoryItem(
                    username: username,
                    name: 'My Story',
                    isMe: true,
                    isDark: isDark,
                    theme: theme,
                  ),
                  _buildStoryItem(username: 'alex', name: 'Alex', isOnline: true, isDark: isDark, theme: theme),
                  _buildStoryItem(username: 'samira', name: 'Samira', isOnline: true, isDark: isDark, theme: theme),
                  _buildStoryItem(username: 'jordan', name: 'Jordan', isOnline: true, isDark: isDark, theme: theme),
                  _buildStoryItem(username: 'taylor', name: 'Taylor', isOnline: true, isDark: isDark, theme: theme),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 4. Recent Chats Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Chats',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/chats'),
                  child: Row(
                    children: [
                      Text('See all', style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right, size: 16, color: theme.colorScheme.secondary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Recent Chats List (Loads real chats, falls back/blends beautiful preview data)
            chatsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildPreviewChatsList(context, theme, isDark),
              data: (chats) {
                if (chats.isEmpty) {
                  return _buildPreviewChatsList(context, theme, isDark);
                }
                
                // Show up to 5 real chats
                final recentChats = chats.take(5).toList();
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
                      context: context,
                      theme: theme,
                      isDark: isDark,
                      name: otherDisplayName,
                      message: lastMessageText,
                      time: formatTime(lastMsg?['createdAt']),
                      unreadCount: chat['unreadCount'] ?? 0,
                      username: otherUsername,
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

  Widget _buildAppBarAction({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return HoverAppBarAction(
      icon: icon,
      isDark: isDark,
      onTap: onTap,
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return HoverQuickAction(
      icon: icon,
      label: label,
      onTap: onTap,
      theme: theme,
    );
  }

  Widget _buildStoryItem({
    required String username,
    required String name,
    bool isMe = false,
    bool isOnline = false,
    required bool isDark,
    required ThemeData theme,
  }) {
    final avatarUrl = 'https://i.pravatar.cc/150?u=$username';
    return Padding(
      padding: const EdgeInsets.only(right: 16.0),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isMe 
                        ? Colors.transparent 
                        : (isOnline ? theme.colorScheme.secondary : Colors.grey.shade400),
                    width: 2.5,
                  ),
                ),
                child: CircleAvatar(
                  radius: 26,
                  backgroundImage: NetworkImage(avatarUrl),
                ),
              ),
              if (isMe)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFB), width: 2),
                    ),
                    child: const Icon(Icons.add, size: 12, color: Colors.white),
                  ),
                )
              else if (isOnline)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFB), width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewChatsList(BuildContext context, ThemeData theme, bool isDark) {
    return Column(
      children: [
        _buildChatTile(
          context: context,
          theme: theme,
          isDark: isDark,
          name: 'Alex Morgan',
          message: 'Let\'s catch up later today.',
          time: '9:40 AM',
          unreadCount: 2,
          username: 'alex',
          onTap: () {},
        ),
        _buildChatTile(
          context: context,
          theme: theme,
          isDark: isDark,
          name: 'Design Team',
          message: 'Samira: Here\'s the latest update.',
          time: '9:32 AM',
          unreadCount: 0,
          username: 'team',
          onTap: () {},
        ),
        _buildChatTile(
          context: context,
          theme: theme,
          isDark: isDark,
          name: 'Samira Ali',
          message: 'The file has been sent.',
          time: 'Yesterday',
          unreadCount: 1,
          username: 'samira',
          onTap: () {},
        ),
        _buildChatTile(
          context: context,
          theme: theme,
          isDark: isDark,
          name: 'Jordan Lee',
          message: '📞 Voice call • 2m 24s',
          time: 'Yesterday',
          unreadCount: 0,
          username: 'jordan',
          onTap: () {},
        ),
        _buildChatTile(
          context: context,
          theme: theme,
          isDark: isDark,
          name: 'Project Phoenix',
          message: 'Taylor: On it 🚀',
          time: 'Mon',
          unreadCount: 0,
          isMuted: true,
          username: 'phoenix',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildChatTile({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    bool isMuted = false,
    required String username,
    required VoidCallback onTap,
  }) {
    final avatarUrl = 'https://i.pravatar.cc/150?u=$username';
    return HoverChatTile(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundImage: NetworkImage(avatarUrl),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            message,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unreadCount > 0 
                  ? (isDark ? Colors.white70 : Colors.black87) 
                  : Colors.grey[500],
              fontSize: 13,
              fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: TextStyle(
                color: unreadCount > 0 ? theme.colorScheme.secondary : Colors.grey[400],
                fontSize: 11,
                fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6),
            if (unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  unreadCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            else if (isMuted)
              Icon(Icons.volume_off_outlined, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Veyl Design System Premium Stateful Hover Interaction Widgets
// -------------------------------------------------------------

class HoverAppBarAction extends StatefulWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const HoverAppBarAction({
    super.key,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<HoverAppBarAction> createState() => _HoverAppBarActionState();
}

class _HoverAppBarActionState extends State<HoverAppBarAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.1 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.isDark 
                  ? (Colors.white.withOpacity(_isHovered ? 0.12 : 0.06)) 
                  : (_isHovered ? Colors.grey[100] : Colors.white),
              shape: BoxShape.circle,
              boxShadow: widget.isDark
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
              border: Border.all(
                color: widget.isDark 
                    ? Colors.white10 
                    : (_isHovered ? theme.colorScheme.secondary.withOpacity(0.3) : const Color(0xFFE5E7EB)),
                width: 1,
              ),
            ),
            child: Icon(widget.icon, color: widget.isDark ? Colors.white : const Color(0xFF0F172A), size: 20),
          ),
        ),
      ),
    );
  }
}

class HoverQuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;

  const HoverQuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    required this.theme,
  });

  @override
  State<HoverQuickAction> createState() => _HoverQuickActionState();
}

class _HoverQuickActionState extends State<HoverQuickAction> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withOpacity(_isHovered ? 0.16 : 0.08),
                  shape: BoxShape.circle,
                  boxShadow: _isHovered 
                      ? [BoxShadow(color: theme.colorScheme.secondary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Icon(widget.icon, color: theme.colorScheme.secondary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(_isHovered ? 1.0 : 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoverChatTile extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const HoverChatTile({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  State<HoverChatTile> createState() => _HoverChatTileState();
}

class _HoverChatTileState extends State<HoverChatTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: _isHovered 
                  ? (isDark ? const Color(0xFF1E293B) : Colors.grey[100])
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isHovered
                    ? theme.colorScheme.secondary.withOpacity(0.3)
                    : (isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF3F4F6)),
                width: 1,
              ),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.15 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : [],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
