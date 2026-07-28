import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api_client.dart';
import '../../../core/widgets/premium_button.dart';
import '../../auth/auth_provider.dart';

final allLinksProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get('/links/all');
    return response.data as List<dynamic>;
  } catch (e) {
    try {
      await ref.read(authProvider).guestLogin();
      final retryResponse = await dio.get('/links/all');
      return retryResponse.data as List<dynamic>;
    } catch (_) {
      return <dynamic>[];
    }
  }
});

class DisposableLinksScreen extends ConsumerStatefulWidget {
  const DisposableLinksScreen({super.key});

  @override
  ConsumerState<DisposableLinksScreen> createState() => _DisposableLinksScreenState();
}

class _DisposableLinksScreenState extends ConsumerState<DisposableLinksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers
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
      dynamic response;
      try {
        response = await dio.post('/links/create', data: payload);
      } catch (_) {
        await ref.read(authProvider).guestLogin();
        response = await dio.post('/links/create', data: payload);
      }

      setState(() {
        _nameController.clear();
        _pinController.clear();
        _expiresInMinutes = 15;
        _maxScans = 1;
        _allowChat = true;
        _allowCalls = true;
      });

      ref.invalidate(allLinksProvider);

      _showGeneratedLinkDialog(response.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to generate invite link. Please try again.'),
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This invite is temporary and expires automatically.',
                style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
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
              const SizedBox(height: 20),

              TextField(
                readOnly: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  labelText: 'Invite URL',
                  hintText: fullUrl,
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: fullUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URL copied to clipboard')),
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
      ref.invalidate(allLinksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite link revoked')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke link: $e')),
        );
      }
    }
  }

  void _reactivateLink(String linkId) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post('/links/reactivate/$linkId', data: {'extensionMinutes': 60});
      ref.invalidate(allLinksProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('⚡ Link reactivated & extended for 60 minutes!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reactivate link: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Disposable Links', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.colorScheme.secondary,
          labelColor: theme.colorScheme.secondary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Create Link'),
            Tab(text: 'All My Links'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Create Link Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate Secret Disposable Link',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create temporary links to let contacts message or call you without exposing your permanent identity.',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.grey, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Link Name (Optional)
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Link Title / Note (Optional)',
                    hintText: 'e.g., Temporary Work Contact, Marketplace Seller',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 20),

                // Expiration Picker
                Text(
                  'Link Duration',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [15, 60, 1440, 4320].map((mins) {
                    final label = mins == 15
                        ? '15 Mins'
                        : mins == 60
                            ? '1 Hour'
                            : mins == 1440
                                ? '1 Day'
                                : '3 Days';
                    final isSelected = _expiresInMinutes == mins;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _expiresInMinutes = mins),
                      selectedColor: theme.colorScheme.secondary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.secondary : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Usage Limits (Max Scans)
                Text(
                  'Max Uses / Scans',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [1, 5, 10, null].map((limit) {
                    final label = limit == null ? 'Unlimited' : '$limit ${limit == 1 ? "Scan" : "Scans"}';
                    final isSelected = _maxScans == limit;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (val) => setState(() => _maxScans = limit),
                      selectedColor: theme.colorScheme.secondary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.secondary : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // PIN Protection (Optional)
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Protection PIN Code (Optional)',
                    hintText: 'e.g., 1234',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 20),

                // Allowed Actions Selection
                Text(
                  'Allowed Communication Permissions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionSelectionCard(
                        icon: Icons.chat_bubble_outline,
                        title: 'Direct Chat',
                        isSelected: _allowChat,
                        onTap: () => setState(() => _allowChat = !_allowChat),
                        theme: theme,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionSelectionCard(
                        icon: Icons.phone_outlined,
                        title: 'Voice Calling',
                        isSelected: _allowCalls,
                        onTap: () => setState(() => _allowCalls = !_allowCalls),
                        theme: theme,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Create Button
                PremiumButton(
                  onPressed: _isCreating ? null : _createLink,
                  child: _isCreating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Generate Secret Link'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Tab 2: All My Links List (Active, Expired, Revoked with Reactivate Button)
          Consumer(
            builder: (context, ref, child) {
              final allLinksAsync = ref.watch(allLinksProvider);

              return allLinksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.refresh_outlined, size: 56, color: theme.colorScheme.secondary),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load links at this time.',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
                          label: const Text('Tap to Refresh', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: () => ref.invalidate(allLinksProvider),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (links) {
                  if (links.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link_off, size: 64, color: theme.dividerColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(
                            'No temporary links created yet',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      final String id = link['id'];
                      final String name = link['name'] ?? 'Temporary Invite';
                      final int scans = link['currentScans'];
                      final int? max = link['maxScans'];
                      final String status = link['status'] ?? 'ACTIVE';
                      final String expires = link['expiresAt'] != null
                          ? DateTime.parse(link['expiresAt']).toLocal().toString().substring(0, 16)
                          : 'Never';

                      final isActive = status == 'ACTIVE';
                      final isExpired = status == 'EXPIRED';

                      return HoverLinkCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isActive
                                                  ? Colors.green.withOpacity(0.12)
                                                  : (isExpired
                                                      ? Colors.red.withOpacity(0.12)
                                                      : Colors.grey.withOpacity(0.12)),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              isActive ? '🟢 Active' : (isExpired ? '🔴 Expired' : '⛔ Revoked'),
                                              style: TextStyle(
                                                color: isActive ? Colors.green : (isExpired ? Colors.redAccent : Colors.grey),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text('Scans: $scans / ${max ?? "∞"}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      const SizedBox(height: 2),
                                      Text('Expires: $expires', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                      if (link['password'] != null) ...[
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'PIN Locked: ${link['password']}',
                                            style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isActive) ...[
                                  IconButton(
                                    icon: const Icon(Icons.qr_code, color: Color(0xFF6366F1)),
                                    onPressed: () => _showGeneratedLinkDialog(link),
                                    tooltip: 'Show QR Code',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                    onPressed: () => _revokeLink(id),
                                    tooltip: 'Revoke Link',
                                  ),
                                ],
                              ],
                            ),
                            if (isActive) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                      ),
                                      icon: const Icon(Icons.meeting_room_outlined, color: Colors.white, size: 18),
                                      label: const Text(
                                        '🚀 Rejoin / Open Session',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      onPressed: () {
                                        final token = link['secureToken'];
                                        if (token != null) {
                                          context.push('/claim/$token');
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                    ),
                                    icon: const Icon(Icons.qr_code, size: 18),
                                    label: const Text('QR Code'),
                                    onPressed: () => _showGeneratedLinkDialog(link),
                                  ),
                                ],
                              ),
                            ] else ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(Icons.bolt, color: Colors.white, size: 18),
                                  label: const Text(
                                    '⚡ Reactivate & Extend (60 Mins)',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  onPressed: () => _reactivateLink(id),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
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
              ? theme.colorScheme.secondary.withOpacity(0.08) 
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.secondary 
                : (isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon, 
              color: isSelected ? theme.colorScheme.secondary : Colors.grey, 
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? theme.colorScheme.secondary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Veyl Design System Premium Stateful Hover Link Card
// -------------------------------------------------------------

class HoverLinkCard extends StatefulWidget {
  final Widget child;

  const HoverLinkCard({super.key, required this.child});

  @override
  State<HoverLinkCard> createState() => _HoverLinkCardState();
}

class _HoverLinkCardState extends State<HoverLinkCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered 
                ? (isDark ? const Color(0xFF1E293B) : Colors.grey[100])
                : theme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? theme.colorScheme.secondary.withOpacity(0.4)
                  : (isDark ? Colors.white10 : theme.dividerColor.withOpacity(0.5)),
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
