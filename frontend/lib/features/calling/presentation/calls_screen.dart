import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/auth_provider.dart';
import '../../../core/api_client.dart';
import '../room_provider.dart';
import '../../../core/widgets/premium_button.dart';

final allUsersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.read(dioProvider);
  final response = await dio.get('/users');
  return response.data as List<dynamic>;
});

final callSearchQueryProvider = StateProvider.autoDispose<String>((ref) => '');

class CallsScreen extends ConsumerStatefulWidget {
  const CallsScreen({super.key});

  @override
  ConsumerState<CallsScreen> createState() => _CallsScreenState();
}

class _CallsScreenState extends ConsumerState<CallsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Breakout room form controllers
  final _roomNameController = TextEditingController();
  final _joinRoomIdController = TextEditingController();
  String _roomType = 'TEMPORARY'; // 'TEMPORARY' or 'PERMANENT'
  int _durationHours = 3;
  bool _isCreatingRoom = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomNameController.dispose();
    _joinRoomIdController.dispose();
    super.dispose();
  }

  void _startCall(BuildContext context, Map<String, dynamic> callee, {required bool isVideo}) {
    final profileAsync = ref.read(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';
    final calleeId = callee['id'];

    if (currentUserId.isEmpty || calleeId == null) return;

    // Generate a clean, unique room name for the Jitsi call session
    final String uniqueRoom = '${isVideo ? "video" : "voice"}_call_${const Uuid().v4()}';

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

  void _createBreakoutRoom() async {
    final name = _roomNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a room name'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isCreatingRoom = true);

    try {
      final roomData = await ref.read(roomServiceProvider).createRoom(
        name,
        _roomType,
        durationHours: _roomType == 'TEMPORARY' ? _durationHours : null,
      );

      final String roomId = roomData['id'];

      setState(() {
        _roomNameController.clear();
      });

      if (mounted) {
        _showRoomCreatedDialog(roomData);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create breakout room: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreatingRoom = false);
    }
  }

  void _showRoomCreatedDialog(Map<String, dynamic> roomData) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String roomId = roomData['id'];
    final String roomName = roomData['name'] ?? 'Breakout Room';
    
    // Breakout room sharing URL
    final String roomUrl = 'https://veyl.kkdes.co.ke/app.html#/room/$roomId';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF161E2E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Room Generated Successfully',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Share this room invite URL or QR code with guests. Anyone with the URL can join.',
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
                    data: roomUrl,
                    version: QrVersions.auto,
                    size: 160.0,
                    gapless: false,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  readOnly: true,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Room ID',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: 'Copy Room ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: roomId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ Room ID copied to clipboard')),
                        );
                      },
                    ),
                  ),
                  controller: TextEditingController(text: roomId),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Share Link'),
                        onPressed: () {
                          Share.share(
                            'Join my Veyl Breakout Room "$roomName":\n$roomUrl',
                            subject: 'Veyl Breakout Room Invite',
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
              child: const Text('Close', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.push('/room/$roomId');
              },
              child: const Text('Join Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _joinRoomById() {
    final roomId = _joinRoomIdController.text.trim();
    if (roomId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a Breakout Room ID to join'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }
    _joinRoomIdController.clear();
    context.push('/room/$roomId');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Directory & Calls', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.secondary),
            onPressed: () {
              ref.invalidate(allUsersProvider);
            },
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
              text: 'Users Directory',
            ),
            Tab(
              icon: Icon(Icons.meeting_room_outlined, size: 18),
              text: 'Breakout Rooms',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDirectoryTab(theme, isDark),
          _buildBreakoutRoomsTab(theme, isDark),
        ],
      ),
    );
  }

  // ─── Tab 1: Users Directory ──────────────────────────────────────────────────
  Widget _buildDirectoryTab(ThemeData theme, bool isDark) {
    final usersAsync = ref.watch(allUsersProvider);
    final searchQuery = ref.watch(callSearchQueryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final currentUserId = profileAsync.value?['userId'] ?? '';

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: TextField(
            onChanged: (val) => ref.read(callSearchQueryProvider.notifier).state = val,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Search user by username...',
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

        // User Directory List
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Failed to load users directory', style: TextStyle(color: Colors.grey[500])),
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
                        'No directory users found',
                        style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
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

                  return _UserDirectoryCard(
                    username: username,
                    displayName: displayName,
                    photoUrl: photoUrl,
                    initials: initials,
                    theme: theme,
                    isDark: isDark,
                    onVoiceCall: () => _startCall(context, user, isVideo: false),
                    onVideoCall: () => _startCall(context, user, isVideo: true),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ─── Tab 2: Breakout Rooms ───────────────────────────────────────────────────
  Widget _buildBreakoutRoomsTab(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero breakout info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.campaign, color: Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voice Breakout Rooms',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Launch a conference room. Only the presenter broadcasts audio. Others join to listen live.',
                        style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Create Breakout Room Form Card
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
                Text(
                  'Create Breakout Room',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _roomNameController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Breakout Room Title',
                    prefixIcon: Icon(Icons.meeting_room_outlined),
                    hintText: 'e.g. Weekly Cryptography Talk',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _roomType,
                  dropdownColor: theme.cardColor,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Breakout Space Type',
                    prefixIcon: Icon(Icons.security_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'TEMPORARY', child: Text('Temporary Breakout (Auto-expiring)')),
                    DropdownMenuItem(value: 'PERMANENT', child: Text('Permanent Channels')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _roomType = val);
                  },
                ),
                if (_roomType == 'TEMPORARY') ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _durationHours,
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      labelText: 'Broadcast Room Expiry Duration',
                      prefixIcon: Icon(Icons.timer_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Expires in 1 Hour')),
                      DropdownMenuItem(value: 3, child: Text('Expires in 3 Hours')),
                      DropdownMenuItem(value: 6, child: Text('Expires in 6 Hours')),
                      DropdownMenuItem(value: 12, child: Text('Expires in 12 Hours')),
                      DropdownMenuItem(value: 24, child: Text('Expires in 24 Hours')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _durationHours = val);
                    },
                  ),
                ],
                const SizedBox(height: 24),
                PremiumButton(
                  onPressed: _isCreatingRoom ? null : _createBreakoutRoom,
                  child: _isCreatingRoom
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text('Generate Breakout Space'),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Join Breakout Room by ID Card
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
                Text(
                  'Join Room by ID',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _joinRoomIdController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: const InputDecoration(
                    labelText: 'Veyl Room ID',
                    prefixIcon: Icon(Icons.vpn_key_outlined),
                    hintText: 'Enter 36-character Room UUID',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary.withOpacity(0.08),
                      foregroundColor: theme.colorScheme.secondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: theme.colorScheme.secondary.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _joinRoomById,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.login, size: 18),
                        SizedBox(width: 8),
                        Text('Tune In / Listen Live', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── User Directory Card ─────────────────────────────────────────────────────

class _UserDirectoryCard extends StatefulWidget {
  final String username;
  final String displayName;
  final String photoUrl;
  final String initials;
  final ThemeData theme;
  final bool isDark;
  final VoidCallback onVoiceCall;
  final VoidCallback onVideoCall;

  const _UserDirectoryCard({
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.initials,
    required this.theme,
    required this.isDark,
    required this.onVoiceCall,
    required this.onVideoCall,
  });

  @override
  State<_UserDirectoryCard> createState() => _UserDirectoryCardState();
}

class _UserDirectoryCardState extends State<_UserDirectoryCard> {
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.call, color: widget.theme.colorScheme.secondary),
                tooltip: 'Voice Call',
                onPressed: widget.onVoiceCall,
              ),
              IconButton(
                icon: Icon(Icons.videocam, color: Colors.greenAccent.shade700),
                tooltip: 'Video Call',
                onPressed: widget.onVideoCall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
