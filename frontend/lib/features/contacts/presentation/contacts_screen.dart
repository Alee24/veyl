import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../calling/presentation/calls_screen.dart'; // Reuse allUsersProvider
import '../../chat/chat_provider.dart';
import '../../auth/auth_provider.dart';

class ContactsScreen extends ConsumerWidget {
  const ContactsScreen({super.key});

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
        automaticallyImplyLeading: false,
        title: const Text('Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Users list
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text('Failed to load contacts', style: TextStyle(color: Colors.grey[500])),
              ),
              data: (users) {
                // Filter users
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
                          'No contacts found',
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
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(avatarUrl),
                        ),
                        title: Text(
                          displayName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          '@$username',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.chat_bubble_outline, color: theme.colorScheme.secondary),
                          onPressed: () async {
                            try {
                              // Create chat and go directly to conversation screen!
                              final chatId = await ref.read(chatProvider).createChatByUsername(username);
                              if (context.mounted) {
                                context.push('/chat/$chatId');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to start chat: $e')),
                                );
                              }
                            }
                          },
                        ),
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
