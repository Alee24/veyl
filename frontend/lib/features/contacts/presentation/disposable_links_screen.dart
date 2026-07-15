import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/api_client.dart';
import '../../../core/widgets/premium_button.dart';

final activeLinksProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/links/active');
  return response.data as List<dynamic>;
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
  bool _requireApproval = false;

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
      'requireApproval': _requireApproval,
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

      ref.invalidate(activeLinksProvider);
      
      // Auto-switch to generated dialog
      _showGeneratedLinkDialog(response.data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate invite: $e')),
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
          title: const Text('Invite QR Code', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This invite is temporary and expires automatically.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // QR Code
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200, width: 1.5),
                ),
                child: QrImageView(
                  data: fullUrl,
                  version: QrVersions.auto,
                  size: 180.0,
                  gapless: false,
                ),
              ),
              const SizedBox(height: 20),

              // Action Link Input
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
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
      ref.invalidate(activeLinksProvider);
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
            Tab(text: 'Active Links'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Create Link Form
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create an expiring contact link to share privately with buyers, tables, or temporary meetings.',
                  style: TextStyle(color: Colors.grey, height: 1.4),
                ),
                const SizedBox(height: 24),

                // Link Name
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Contact/Link Name (e.g. Marketplace Buyer)',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                ),
                const SizedBox(height: 16),

                // Expiration time dropdown
                DropdownButtonFormField<int>(
                  value: _expiresInMinutes,
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

                // Max Uses dropdown
                DropdownButtonFormField<int?>(
                  value: _maxScans,
                  decoration: const InputDecoration(
                    labelText: 'Maximum Uses (Scans)',
                    prefixIcon: Icon(Icons.people_outline),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1 Scan')),
                    DropdownMenuItem(value: 5, child: Text('5 Scans')),
                    DropdownMenuItem(value: 10, child: Text('10 Scans')),
                    DropdownMenuItem(value: null, child: Text('Unlimited')),
                  ],
                  onChanged: (val) {
                    setState(() => _maxScans = val);
                  },
                ),
                const SizedBox(height: 16),

                // PIN Code Input
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 4,
                  decoration: const InputDecoration(
                    labelText: 'Optional PIN Code (4 Digits)',
                    prefixIcon: Icon(Icons.lock_outline),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 20),

                // Actions Allowed
                const Text('Allowed Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Allow Chatting'),
                  value: _allowChat,
                  activeColor: theme.colorScheme.secondary,
                  onChanged: (val) {
                    if (val != null) setState(() => _allowChat = val);
                  },
                ),
                CheckboxListTile(
                  title: const Text('Allow Calling'),
                  value: _allowCalls,
                  activeColor: theme.colorScheme.secondary,
                  onChanged: (val) {
                    if (val != null) setState(() => _allowCalls = val);
                  },
                ),
                const SizedBox(height: 24),

                PremiumButton(
                  onPressed: _isCreating ? null : _createLink,
                  child: _isCreating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Generate Contact Link'),
                ),
              ],
            ),
          ),

          // Tab 2: Active Links List
          Consumer(
            builder: (context, ref, child) {
              final activeLinksAsync = ref.watch(activeLinksProvider);

              return activeLinksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Failed to load active links: $err')),
                data: (links) {
                  if (links.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.link_off, size: 64, color: theme.dividerColor.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text('No active temporary links', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: links.length,
                    itemBuilder: (context, index) {
                      final link = links[index];
                      final String name = link['name'] ?? 'Temporary Invite';
                      final int scans = link['currentScans'];
                      final int? max = link['maxScans'];
                      final String expires = link['expiresAt'] != null
                          ? DateTime.parse(link['expiresAt']).toLocal().toString().substring(0, 16)
                          : 'Never';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 6),
                                  Text('Scans: $scans / ${max ?? "∞"}', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  const SizedBox(height: 2),
                                  Text('Expires: $expires', style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                  if (link['password'] != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
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
                            IconButton(
                              icon: const Icon(Icons.qr_code),
                              onPressed: () => _showGeneratedLinkDialog(link),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _revokeLink(link['id']),
                            ),
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
}
