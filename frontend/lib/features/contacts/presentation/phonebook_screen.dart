import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../contacts_provider.dart';
import '../../calling/call_service.dart';
import '../../auth/auth_provider.dart';

class PhonebookScreen extends ConsumerStatefulWidget {
  const PhonebookScreen({super.key});

  @override
  ConsumerState<PhonebookScreen> createState() => _PhonebookScreenState();
}

class _PhonebookScreenState extends ConsumerState<PhonebookScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(phonebookProvider.notifier).fetchAndMatchContacts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _inviteContact(String phone) async {
    if (phone.isEmpty) return;
    final message = Uri.encodeComponent("Hey! Let's chat securely and make free internet calls on VEYL. Download the app today!");
    final uri = Uri.parse("sms:$phone?body=$message");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phonebookState = ref.watch(phonebookProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUsername = profileAsync.value?['username'] ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phonebook Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: theme.colorScheme.primary,
          tabs: [
            Tab(
              text: 'Veyl Users (${phonebookState.matchedUsers.length})',
            ),
            Tab(
              text: 'All Contacts (${phonebookState.unmatchedContacts.length})',
            ),
          ],
        ),
      ),
      body: phonebookState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !phonebookState.permissionGranted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.contacts_outlined, size: 64, color: theme.dividerColor.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'Contacts Permission Required',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'To call your phonebook contacts over the internet, VEYL needs access to your contacts list to match them with registered users.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          ),
                          onPressed: () => ref.read(phonebookProvider.notifier).fetchAndMatchContacts(),
                          child: const Text('Grant Access', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    phonebookState.matchedUsers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 64, color: theme.dividerColor.withOpacity(0.3)),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No contacts on VEYL yet',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "None of your contacts are registered on VEYL. Go to 'All Contacts' to invite them!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: phonebookState.matchedUsers.length,
                            itemBuilder: (context, index) {
                              final user = phonebookState.matchedUsers[index];
                              final String username = user['username'] ?? '';
                              final String displayName = user['displayName'] ?? username;
                              final String avatarUrl = 'https://i.pravatar.cc/150?u=$username';

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 22,
                                  backgroundImage: NetworkImage(avatarUrl),
                                ),
                                title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('@$username • ${user['phoneNumber'] ?? ''}', style: const TextStyle(color: Colors.grey)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.call, color: theme.colorScheme.primary),
                                      onPressed: () => ref.read(callServiceProvider).joinVideoCall('voice-$username', currentUsername, ''),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.videocam, color: theme.colorScheme.primary),
                                      onPressed: () => ref.read(callServiceProvider).joinVideoCall('video-$username', currentUsername, ''),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),

                    phonebookState.unmatchedContacts.isEmpty
                        ? const Center(child: Text('No contacts found'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: phonebookState.unmatchedContacts.length,
                            itemBuilder: (context, index) {
                              final contact = phonebookState.unmatchedContacts[index];
                              final name = contact.displayName;
                              final phone = contact.phones.isNotEmpty ? contact.phones.first : '';

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: theme.dividerColor.withOpacity(0.05),
                                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'C', style: TextStyle(color: theme.colorScheme.primary)),
                                ),
                                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(phone, style: const TextStyle(color: Colors.grey)),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                    foregroundColor: theme.colorScheme.primary,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  onPressed: () => _inviteContact(phone),
                                  child: const Text('Invite'),
                                ),
                              );
                            },
                          ),
                  ],
                ),
    );
  }
}
