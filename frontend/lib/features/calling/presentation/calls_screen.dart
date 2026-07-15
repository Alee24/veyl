import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../auth/auth_provider.dart';
import '../../../core/api_client.dart';

final allUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/users');
  return response.data as List<dynamic>;
});

final callSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class CallsScreen extends ConsumerWidget {
  const CallsScreen({super.key});

  void _startCall(BuildContext context, WidgetRef ref, Map<String, dynamic> callee) {
    final profileAsync = ref.read(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';
    final calleeId = callee['id'];

    if (currentUserId.isEmpty || calleeId == null) return;

    // Generate a clean, unique room name for the Jitsi call session
    final String uniqueRoom = 'call_${const Uuid().v4()}';

    // Push the OutgoingCallScreen route, passing the callee details and room name
    context.push(
      '/outgoing_call',
      extra: {
        'calleeId': calleeId,
        'calleeName': callee['displayName'] ?? callee['username'] ?? 'User',
        'calleeUsername': callee['username'] ?? 'user',
        'roomName': uniqueRoom,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final usersAsync = ref.watch(allUsersProvider);
    final searchQuery = ref.watch(callSearchQueryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Directory & Calls', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.secondary),
            onPressed: () => ref.refresh(allUsersProvider),
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
              onChanged: (val) => ref.read(callSearchQueryProvider.notifier).state = val,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: 'Search user by username...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // User Directory List
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Failed to load users', style: TextStyle(color: Colors.grey[500])),
              ),
              data: (users) {
                // Filter out current user and guests
                final eligibleUsers = users.where((u) {
                  final id = u['id'];
                  final username = (u['username'] ?? '').toString().toLowerCase();
                  final displayName = (u['displayName'] ?? '').toString().toLowerCase();
                  final query = searchQuery.toLowerCase();
                  
                  return id != currentUserId && 
                      (username.contains(query) || displayName.contains(query));
                }).toList();

                if (eligibleUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: theme.dividerColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text(
                          'No users found',
                          style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: eligibleUsers.length,
                  itemBuilder: (context, index) {
                    final user = eligibleUsers[index];
                    final String username = user['username'] ?? 'user';
                    final String displayName = user['displayName'] ?? username;
                    final String avatarUrl = 'https://i.pravatar.cc/150?u=$username';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.white10 : theme.dividerColor.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundImage: NetworkImage(avatarUrl),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '@$username',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          
                          // Call Button
                          GestureDetector(
                            onTap: () => _startCall(context, ref, user),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.call,
                                color: theme.colorScheme.secondary,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Video Call Button
                          GestureDetector(
                            onTap: () => _startCall(context, ref, user),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.shade700.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.videocam,
                                color: Colors.greenAccent.shade700,
                                size: 20,
                              ),
                            ),
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
}
