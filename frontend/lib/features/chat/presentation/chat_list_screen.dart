import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle, color: theme.colorScheme.primary, size: 32),
            onPressed: () {},
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
            child: ListView(
              children: [
                _buildChatTile('Sarah Johnson', 'Hey! Are we still meeting today?', '9:41 AM', 2, 'https://i.pravatar.cc/150?u=1', context),
                _buildChatTile('Design Team', 'Alex: Here\'s the update', '9:33 AM', 5, 'https://i.pravatar.cc/150?u=2', context),
                _buildChatTile('Mike Williams', 'Voice message', 'Yesterday', 0, 'https://i.pravatar.cc/150?u=3', context, isVoice: true),
                _buildChatTile('Project Galaxy', 'Lisa: Great work everyone!', 'Yesterday', 0, 'https://i.pravatar.cc/150?u=4', context, isMuted: true),
                _buildChatTile('Emma Brown', 'Awesome! Thanks', 'Mon', 0, 'https://i.pravatar.cc/150?u=5', context),
                _buildChatTile('Family Group', 'Mom: Dinner at 7pm', 'Mon', 0, 'https://i.pravatar.cc/150?u=6', context),
                _buildChatTile('Kevin Lee', 'See you tomorrow', 'Sun', 0, 'https://i.pravatar.cc/150?u=7', context),
              ],
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

  Widget _buildChatTile(
    String name,
    String message,
    String time,
    int unread,
    String avatarUrl,
    BuildContext context, {
    bool isVoice = false,
    bool isMuted = false,
  }) {
    final theme = Theme.of(context);
    final String chatId = name.toLowerCase().replaceAll(' ', '-');
    return ListTile(
      onTap: () => context.push('/chat/$chatId'),
      leading: CircleAvatar(
        radius: 24,
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
          Expanded(
            child: Text(
              message,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isMuted) const Icon(Icons.volume_off, size: 14, color: Colors.grey),
              if (isMuted) const SizedBox(width: 4),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
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
