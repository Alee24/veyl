import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Clear all', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        children: [
          _buildNotificationTile(
            context,
            'Sarah Johnson',
            'sent you a message: "Hey! Are we still meeting..."',
            '9:41 AM',
            Icons.message_outlined,
            theme.colorScheme.primary,
          ),
          _buildNotificationTile(
            context,
            'Missed Call',
            'You missed a voice call from Mike Williams',
            'Yesterday, 6:42 PM',
            Icons.call_missed,
            Colors.red,
          ),
          _buildNotificationTile(
            context,
            'New Connection',
            'You connected with Emma Brown via QR code scanner',
            'July 12, 11:30 AM',
            Icons.person_add_outlined,
            Colors.green,
          ),
          _buildNotificationTile(
            context,
            'Security Alert',
            'A new web session was initiated for your profile @ametto',
            'July 10, 2:15 PM',
            Icons.security_outlined,
            Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    String title,
    String body,
    String time,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onBackground,
                        ),
                      ),
                      Text(time, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
