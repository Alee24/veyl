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
    final profilePhotoUrl = profileAsync.value?['profilePhotoUrl'] ?? '';
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
          _buildAppBarAction(
            icon: Icons.search,
            isDark: isDark,
            onTap: () => context.push('/calls'),
          ),
          const SizedBox(width: 8),
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
                    Color(0xFF0B132B),
                    Color(0xFF1C2541),
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
                                child: profilePhotoUrl.isNotEmpty
                                    ? Image.network(
                                        profilePhotoUrl,
                                        fit: BoxFit.cover,
                                        width: 72,
                                        height: 72,
                                        errorBuilder: (context, error, stackTrace) => Text(
                                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V',
                                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    : Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V',
                                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
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
                                color: const Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF0B132B), width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
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
                            const SizedBox(height: 4),
                            Text(
                              '@$username',
                              style: const TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
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
                    label: 'Contacts',
                    onTap: () => context.go('/contacts'),
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

            // 3. Disposable Contact Banner
            _buildDisposableBanner(context, theme, isDark),
            const SizedBox(height: 24),

            // 4. Recent Chats Section
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

            // Recent Chats — real data only, clean empty state
            chatsAsync.when(
              loading: () => _buildChatsShimmer(isDark),
              error: (err, stack) => _buildChatsEmptyState(context, theme, isDark),
              data: (chats) {
                if (chats.isEmpty) {
                  return _buildChatsEmptyState(context, theme, isDark);
                }

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
                    final String otherPhotoUrl = otherUser['profilePhotoUrl'] ?? '';

                    final messages = chat['messages'] as List<dynamic>?;
                    final lastMsg = messages != null && messages.isNotEmpty ? messages[0] : null;
                    final String lastMessageText = lastMsg?['content'] ?? 'No messages yet';

                    String formatTime(String? dateStr) {
                      if (dateStr == null) return '';
                      try {
                        final date = DateTime.parse(dateStr).toLocal();
                        final now = DateTime.now();
                        if (date.day == now.day && date.month == now.month && date.year == now.year) {
                          final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
                          final minute = date.minute.toString().padLeft(2, '0');
                          final period = date.hour >= 12 ? 'PM' : 'AM';
                          return '$hour:$minute $period';
                        }
                        final yesterday = now.subtract(const Duration(days: 1));
                        if (date.day == yesterday.day && date.month == yesterday.month) {
                          return 'Yesterday';
                        }
                        return '${date.day}/${date.month}';
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
                      photoUrl: otherPhotoUrl,
                      initials: otherDisplayName.isNotEmpty ? otherDisplayName[0].toUpperCase() : 'V',
                      onTap: () => context.push('/chat/${chat['id']}'),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 80), // bottom nav padding
          ],
        ),
      ),
    );
  }

  Widget _buildDisposableBanner(BuildContext context, ThemeData theme, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/disposable_links'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.link, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disposable Contact Links',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Share temporary, expiring contact links — no phone number needed.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsShimmer(bool isDark) {
    return Column(
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }

  Widget _buildChatsEmptyState(BuildContext context, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline, size: 36, color: theme.colorScheme.secondary),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversations yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a chat with a contact or\nshare a disposable invite link.',
            textAlign: TextAlign.center,
            style: TextStyle(color: isDark ? Colors.white38 : Colors.grey[500], fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _EmptyStateButton(
                label: 'Find Contacts',
                icon: Icons.people_outline,
                onTap: () => context.go('/contacts'),
                theme: theme,
              ),
              const SizedBox(width: 12),
              _EmptyStateButton(
                label: 'Invite Link',
                icon: Icons.link,
                onTap: () => context.push('/disposable_links'),
                theme: theme,
                filled: true,
              ),
            ],
          ),
        ],
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

  Widget _buildChatTile({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String name,
    required String message,
    required String time,
    required int unreadCount,
    required String photoUrl,
    required String initials,
    bool isMuted = false,
    required VoidCallback onTap,
  }) {
    return HoverChatTile(
      onTap: onTap,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: theme.colorScheme.secondary.withOpacity(0.12),
          child: photoUrl.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    width: 48,
                    height: 48,
                    errorBuilder: (context, error, stackTrace) => Text(
                      initials,
                      style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
              : Text(
                  initials,
                  style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold),
                ),
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
// Small inline button for empty state
// -------------------------------------------------------------
class _EmptyStateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool filled;

  const _EmptyStateButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.theme,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? theme.colorScheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.secondary,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: filled ? Colors.white : theme.colorScheme.secondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: filled ? Colors.white : theme.colorScheme.secondary,
              ),
            ),
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
