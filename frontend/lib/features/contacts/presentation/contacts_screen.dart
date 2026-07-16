import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../calling/presentation/calls_screen.dart';
import '../../chat/chat_provider.dart';
import '../../auth/auth_provider.dart';
import '../../../core/api_client.dart';
import '../../../core/widgets/premium_button.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider for active disposable links
// ─────────────────────────────────────────────────────────────────────────────
final contactsActiveLinksProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/links/active');
  return response.data as List<dynamic>;
});

// ─────────────────────────────────────────────────────────────────────────────
// ContactsScreen — Tabbed: Contacts | Disposable Links
// ─────────────────────────────────────────────────────────────────────────────
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Disposable link form
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  int _expiresInMinutes = 15;
  int? _maxScans = 1;
  bool _allowChat = true;
  bool _allowCalls = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ─── Disposable Link Actions ───────────────────────────────────────────────

  void _createLink() async {
    setState(() => _isCreating = true);

    final allowedActions = <String>[];
    if (_allowChat) allowedActions.add('chat');
    if (_allowCalls) allowedActions.add('voice_call');

    final payload = {
      if (_nameController.text.trim().isNotEmpty) 'name': _nameController.text.trim(),
      'expiresInMinutes': _expiresInMinutes,
      if (_maxScans != null) 'maxScans': _maxScans,
      'allowedActions': allowedActions,
      'requireApproval': false,
      if (_pinController.text.trim().isNotEmpty) 'password': _pinController.text.trim(),
    };

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.post('/links/create', data: payload);

      setState(() {
        _nameController.clear();
        _pinController.clear();
        _expiresInMinutes = 15;
        _maxScans = 1;
        _allowChat = true;
        _allowCalls = true;
      });

      ref.invalidate(contactsActiveLinksProvider);
      _showGeneratedLinkDialog(response.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate invite link. Please try again.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showGeneratedLinkDialog(Map<String, dynamic> linkData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String token = linkData['secureToken'];
    final String fullUrl = 'https://veyl.kkdes.co.ke/app.html#/claim/$token';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Invite QR Code',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share this QR or link. It expires automatically.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: QrImageView(
                    data: fullUrl,
                    version: QrVersions.auto,
                    size: 180.0,
                    gapless: false,
                  ),
                ),
                TextField(
                  readOnly: true,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Invite URL',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy URL',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ URL copied to clipboard')),
                        );
                      },
                    ),
                  ),
                  controller: TextEditingController(text: fullUrl),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share Invite Link'),
                        onPressed: () {
                          Share.share(
                            'Connect with me on Veyl using this disposable invite link:\n$fullUrl',
                            subject: 'Veyl Private Invite Link',
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _revokeLink(String linkId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete('/links/$linkId');
      ref.invalidate(contactsActiveLinksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite link revoked successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke link: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Contacts', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Scan QR Code',
            onPressed: () => context.push('/scan'),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          indicatorWeight: 2.5,
          labelColor: theme.colorScheme.secondary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(
              icon: Icon(Icons.people_outline, size: 18),
              text: 'Contacts',
            ),
            Tab(
              icon: Icon(Icons.link, size: 18),
              text: 'Disposable Links',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactsTab(theme, isDark),
          _buildDisposableLinksTab(theme, isDark),
        ],
      ),
    );
  }

  // ─── Tab 1: Contacts ──────────────────────────────────────────────────────
  Widget _buildContactsTab(ThemeData theme, bool isDark) {
    final usersAsync = ref.watch(allUsersProvider);
    final searchQuery = ref.watch(callSearchQueryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (val) => ref.read(callSearchQueryProvider.notifier).state = val,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search by username or name...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _buildNoContactsState(theme, isDark, 'Failed to load contacts.\nPlease check your connection.'),
            data: (users) {
              final eligibleUsers = users.where((u) {
                final id = u['id'];
                final username = (u['username'] ?? '').toString().toLowerCase();
                final displayName = (u['displayName'] ?? '').toString().toLowerCase();
                final query = searchQuery.toLowerCase();
                return id != currentUserId &&
                    (query.isEmpty || username.contains(query) || displayName.contains(query));
              }).toList();

              if (eligibleUsers.isEmpty) {
                return _buildNoContactsState(theme, isDark,
                    searchQuery.isEmpty
                        ? 'No contacts on Veyl yet.\nInvite someone with a disposable link!'
                        : 'No contacts match "$searchQuery".');
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                itemCount: eligibleUsers.length,
                itemBuilder: (context, index) {
                  final user = eligibleUsers[index];
                  final String username = user['username'] ?? 'user';
                  final String displayName = user['displayName'] ?? username;
                  final String photoUrl = user['profilePhotoUrl'] ?? '';
                  final String initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'V';

                  return _ContactTile(
                    username: username,
                    displayName: displayName,
                    photoUrl: photoUrl,
                    initials: initials,
                    theme: theme,
                    isDark: isDark,
                    onChat: () async {
                      try {
                        final chatId = await ref.read(chatProvider).createChatByUsername(username);
                        if (context.mounted) context.push('/chat/$chatId');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not start chat with @$username. Please try again.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNoContactsState(ThemeData theme, bool isDark, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline, size: 40, color: theme.colorScheme.secondary),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white38 : Colors.grey[500],
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => _tabController.animateTo(1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text('Create Disposable Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tab 2: Disposable Links ──────────────────────────────────────────────
  Widget _buildDisposableLinksTab(ThemeData theme, bool isDark) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: theme.scaffoldBackgroundColor,
            child: TabBar(
              indicatorColor: const Color(0xFF6366F1),
              labelColor: const Color(0xFF6366F1),
              unselectedLabelColor: Colors.grey,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              tabs: const [
                Tab(text: 'Create Link'),
                Tab(text: 'Active Links'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildCreateLinkForm(theme, isDark),
                _buildActiveLinksList(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateLinkForm(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero explanation card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, color: Colors.white, size: 28),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Privacy-First Contact Sharing',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      SizedBox(height: 4),
                      Text(
                        'Share a temporary link — no phone number revealed. Auto-expires after use.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Form Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Link Settings',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Contact Label (e.g. Marketplace Buyer)',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _expiresInMinutes,
                  dropdownColor: theme.cardColor,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Expires In',
                    prefixIcon: Icon(Icons.timer_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 15, child: Text('15 Minutes')),
                    DropdownMenuItem(value: 60, child: Text('1 Hour')),
                    DropdownMenuItem(value: 360, child: Text('6 Hours')),
                    DropdownMenuItem(value: 1440, child: Text('24 Hours')),
                    DropdownMenuItem(value: 10080, child: Text('7 Days')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _expiresInMinutes = val);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int?>(
                  value: _maxScans,
                  dropdownColor: theme.cardColor,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Maximum Uses',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 Scan (Single Use)')),
                    DropdownMenuItem(value: 5, child: Text('5 Scans')),
                    DropdownMenuItem(value: 10, child: Text('10 Scans')),
                    DropdownMenuItem(value: null, child: Text('Unlimited')),
                  ],
                  onChanged: (val) => setState(() => _maxScans = val),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Optional PIN Code (4 digits)',
                    prefixIcon: Icon(Icons.lock_outline),
                    counterText: '',
                    hintText: 'Leave blank for no PIN',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Allowed Actions
          Text('Allowed Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionSelectionCard(
                  icon: Icons.chat_bubble_outline,
                  title: 'Allow Chat',
                  isSelected: _allowChat,
                  onTap: () => setState(() => _allowChat = !_allowChat),
                  theme: theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionSelectionCard(
                  icon: Icons.videocam_outlined,
                  title: 'Allow Calls',
                  isSelected: _allowCalls,
                  onTap: () => setState(() => _allowCalls = !_allowCalls),
                  theme: theme,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          PremiumButton(
            onPressed: _isCreating ? null : _createLink,
            child: _isCreating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_link, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Generate Disposable Link'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveLinksList(ThemeData theme, bool isDark) {
    final activeLinksAsync = ref.watch(contactsActiveLinksProvider);

    return activeLinksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Unable to load links.\nCheck your connection.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500], height: 1.5)),
            const SizedBox(height: 16),
            TextButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: () => ref.invalidate(contactsActiveLinksProvider),
            ),
          ],
        ),
      ),
      data: (links) {
        if (links.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.link_off, size: 40, color: Colors.grey[400]),
                ),
                const SizedBox(height: 20),
                Text(
                  'No active disposable links',
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Create one in the "Create Link" tab\nto share privately.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: links.length,
          itemBuilder: (context, index) {
            final link = links[index];
            final String name = link['name'] ?? 'Temporary Invite';
            final int scans = link['currentScans'] ?? 0;
            final int? max = link['maxScans'];
            final String? rawExpiry = link['expiresAt'];
            String expiryLabel = 'Never';
            bool isExpiringSoon = false;
            if (rawExpiry != null) {
              final exp = DateTime.tryParse(rawExpiry)?.toLocal();
              if (exp != null) {
                final diff = exp.difference(DateTime.now());
                if (diff.inMinutes < 30) isExpiringSoon = true;
                expiryLabel = diff.isNegative
                    ? 'Expired'
                    : diff.inDays > 0
                        ? 'in ${diff.inDays}d ${diff.inHours % 24}h'
                        : diff.inHours > 0
                            ? 'in ${diff.inHours}h ${diff.inMinutes % 60}m'
                            : 'in ${diff.inMinutes}m';
              }
            }

            return _HoverLinkCard(
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isExpiringSoon
                          ? Colors.orange.withOpacity(0.1)
                          : const Color(0xFF6366F1).withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.link,
                      color: isExpiringSoon ? Colors.orange : const Color(0xFF6366F1),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _LinkChip(
                              label: 'Uses: $scans/${max ?? "∞"}',
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: 8),
                            _LinkChip(
                              label: 'Expires $expiryLabel',
                              color: isExpiringSoon ? Colors.orange : Colors.grey,
                            ),
                          ],
                        ),
                        if (link['password'] != null) ...[
                          const SizedBox(height: 6),
                          _LinkChip(
                            label: '🔒 PIN Protected',
                            color: Colors.amber[700]!,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code, color: theme.colorScheme.secondary),
                    tooltip: 'Show QR',
                    onPressed: () => _showGeneratedLinkDialog(link),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    tooltip: 'Revoke Link',
                    onPressed: () => _confirmRevoke(link['id']),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmRevoke(String linkId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Link?'),
        content: const Text('This will permanently delete the disposable link. Recipients who haven\'t used it yet won\'t be able to connect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _revokeLink(linkId);
            },
            child: const Text('Revoke', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSelectionCard({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF6366F1).withOpacity(0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF6366F1)
                : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Contact Tile ─────────────────────────────────────────────────────────────

class _ContactTile extends StatefulWidget {
  final String username;
  final String displayName;
  final String photoUrl;
  final String initials;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onChat;

  const _ContactTile({
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.initials,
    required this.theme,
    required this.isDark,
    required this.onChat,
  });

  @override
  State<_ContactTile> createState() => _ContactTileState();
}

class _ContactTileState extends State<_ContactTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isHovered
              ? (widget.isDark ? const Color(0xFF1E293B) : Colors.grey[50])
              : widget.theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHovered
                ? widget.theme.colorScheme.secondary.withOpacity(0.3)
                : (widget.isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: widget.theme.colorScheme.secondary.withOpacity(0.1),
            child: widget.photoUrl.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.photoUrl,
                      fit: BoxFit.cover,
                      width: 48,
                      height: 48,
                      errorBuilder: (context, error, stackTrace) => Text(
                        widget.initials,
                        style: TextStyle(
                          color: widget.theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                : Text(
                    widget.initials,
                    style: TextStyle(
                      color: widget.theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          title: Text(widget.displayName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(
            '@${widget.username}',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          trailing: IconButton(
            icon: Icon(Icons.chat_bubble_outline, color: widget.theme.colorScheme.secondary),
            tooltip: 'Start Chat',
            onPressed: widget.onChat,
          ),
        ),
      ),
    );
  }
}

// ─── Link Chip ────────────────────────────────────────────────────────────────

class _LinkChip extends StatelessWidget {
  final String label;
  final Color color;

  const _LinkChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ─── Hover Link Card ─────────────────────────────────────────────────────────

class _HoverLinkCard extends StatefulWidget {
  final Widget child;

  const _HoverLinkCard({required this.child});

  @override
  State<_HoverLinkCard> createState() => _HoverLinkCardState();
}

class _HoverLinkCardState extends State<_HoverLinkCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.01 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered
                ? (isDark ? const Color(0xFF1E293B) : Colors.grey[50])
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? const Color(0xFF6366F1).withOpacity(0.4)
                  : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
