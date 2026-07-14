import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../call_service.dart';

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final callService = ref.read(callServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.add_call, color: theme.colorScheme.primary),
            onPressed: () => callService.joinVideoCall('new-call', 'ametto', ''),
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
                hintText: 'Search call history',
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
          
          // Call Log list
          Expanded(
            child: ListView(
              children: [
                _buildCallLogTile(
                  context,
                  'Sarah Johnson',
                  'Incoming',
                  'Today, 10:15 AM',
                  Icons.call_received,
                  Colors.green,
                  true,
                  onTap: () => callService.joinVideoCall('sarah-johnson', 'ametto', ''),
                ),
                _buildCallLogTile(
                  context,
                  'Sarah Johnson',
                  'Outgoing',
                  'Today, 10:10 AM',
                  Icons.call_made,
                  theme.colorScheme.primary,
                  true,
                  onTap: () => callService.joinVideoCall('sarah-johnson', 'ametto', ''),
                ),
                _buildCallLogTile(
                  context,
                  'Mike Williams',
                  'Missed',
                  'Yesterday, 6:42 PM',
                  Icons.call_missed,
                  Colors.red,
                  false,
                  onTap: () => callService.joinVideoCall('mike-williams', 'ametto', ''),
                ),
                _buildCallLogTile(
                  context,
                  'Emma Brown',
                  'Incoming',
                  'July 12, 11:30 AM',
                  Icons.call_received,
                  Colors.green,
                  true,
                  onTap: () => callService.joinVideoCall('emma-brown', 'ametto', ''),
                ),
                _buildCallLogTile(
                  context,
                  'Design Team Room',
                  'Group Call',
                  'July 11, 4:15 PM',
                  Icons.group,
                  theme.colorScheme.primary,
                  true,
                  onTap: () => callService.joinVideoCall('design-team', 'ametto', ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallLogTile(
    BuildContext context,
    String name,
    String type,
    String time,
    IconData icon,
    Color iconColor,
    bool isVideo, {
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: const CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white),
      ),
      title: Text(
        name,
        style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onBackground),
      ),
      subtitle: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text('$type • $time', style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      trailing: IconButton(
        icon: Icon(
          isVideo ? Icons.videocam_outlined : Icons.call_outlined,
          color: theme.colorScheme.primary,
        ),
        onPressed: onTap,
      ),
    );
  }
}
