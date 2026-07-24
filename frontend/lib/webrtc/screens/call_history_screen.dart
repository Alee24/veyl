import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../repositories/call_repository.dart';
import '../../features/auth/auth_provider.dart';

class CallHistoryScreen extends ConsumerWidget {
  const CallHistoryScreen({super.key});

  void _redialUser(BuildContext context, WidgetRef ref, Map<String, dynamic> peer, bool isVideo) {
    final profileAsync = ref.read(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';
    final peerId = peer['id'];

    if (currentUserId.isEmpty || peerId == null) return;

    final String uniqueRoom = '${isVideo ? "video" : "voice"}_call_${const Uuid().v4()}';

    context.push(
      '/outgoing_call',
      extra: {
        'calleeId': peerId,
        'calleeName': peer['displayName'] ?? peer['username'] ?? 'User',
        'calleeUsername': peer['username'] ?? 'user',
        'roomName': uniqueRoom,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final callHistoryAsync = ref.watch(callHistoryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Call History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(callHistoryProvider),
          ),
        ],
      ),
      body: callHistoryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Failed to load call history', style: TextStyle(color: Colors.grey[500])),
        ),
        data: (calls) {
          if (calls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_missed, size: 64, color: theme.dividerColor.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No recent call logs',
                    style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: calls.length,
            itemBuilder: (context, index) {
              final call = calls[index];
              final isCaller = call['callerId'] == currentUserId;
              final peer = isCaller ? call['receiver'] : call['caller'];
              final String displayName = peer?['displayName'] ?? peer?['username'] ?? 'Unknown User';
              final String username = peer?['username'] ?? 'user';
              final String type = call['type'] ?? 'VOICE';
              final String status = call['status'] ?? 'ANSWERED';
              final isVideo = type == 'VIDEO';

              final isMissed = status == 'MISSED' || status == 'REJECTED';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                    child: Icon(
                      isVideo ? Icons.videocam : Icons.call,
                      color: isMissed ? Colors.redAccent : const Color(0xFF6366F1),
                    ),
                  ),
                  title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Row(
                    children: [
                      Icon(
                        isCaller ? Icons.call_made : Icons.call_received,
                        size: 14,
                        color: isMissed ? Colors.redAccent : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMissed ? 'Missed Call' : '@$username',
                        style: TextStyle(
                          color: isMissed ? Colors.redAccent : Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isVideo ? Icons.videocam_outlined : Icons.call_outlined,
                      color: theme.colorScheme.secondary,
                    ),
                    onPressed: () => _redialUser(context, ref, peer, isVideo),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
