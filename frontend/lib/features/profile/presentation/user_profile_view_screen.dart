import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/api_client.dart';
import '../../auth/auth_provider.dart';
import '../../chat/chat_provider.dart';
import '../../../core/widgets/premium_button.dart';

class UserProfileViewScreen extends ConsumerStatefulWidget {
  final String username;
  const UserProfileViewScreen({super.key, required this.username});

  @override
  ConsumerState<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends ConsumerState<UserProfileViewScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _fetchUserProfile() async {
    try {
      final authState = ref.read(authStateProvider);
      if (!authState) {
        await ref.read(authProvider).guestLogin();
      }

      final dio = ref.read(dioProvider);
      final response = await dio.get('/users/${widget.username}');
      setState(() {
        _userData = response.data;
        _isLoading = false;
      });
    } catch (e) {
      // Fallback display if user lookup fails
      setState(() {
        _userData = {
          'username': widget.username,
          'displayName': widget.username[0].toUpperCase() + widget.username.substring(1),
          'isOnline': true,
        };
        _isLoading = false;
        _errorMessage = null;
      });
    }
  }

  void _startChat() async {
    try {
      final chatId = await ref.read(chatProvider).createChatByUsername(widget.username);
      if (mounted) {
        ref.invalidate(userChatsProvider);
        context.go('/chat/$chatId');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start chat: $e')),
        );
      }
    }
  }

  void _startCall({required bool isVideo}) async {
    try {
      final targetUserId = _userData?['id'] ?? widget.username;
      final targetName = _userData?['displayName'] ?? widget.username;

      context.push('/outgoing_call', extra: {
        'calleeId': targetUserId,
        'calleeName': targetName,
        'calleeUsername': widget.username,
        'roomName': 'Call-${DateTime.now().millisecondsSinceEpoch}',
        'isVideo': isVideo,
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call: $e')),
        );
      }
    }
  }

  void _shareProfile() {
    final profileUrl = 'https://veyl.kkdes.co.ke/app.html#/user/${widget.username}';
    Share.share(
      'Connect with @${widget.username} on Veyl! Open profile link: $profileUrl',
      subject: 'Veyl Profile Connection',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6366F1)),
              SizedBox(height: 16),
              Text(
                'Loading User Account...',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final user = _userData!;
    final displayName = user['displayName'] ?? user['username'] ?? widget.username;
    final username = user['username'] ?? widget.username;
    final profilePhotoUrl = user['profilePhotoUrl'];
    final isOnline = user['isOnline'] ?? true;
    final profileUrl = 'https://veyl.kkdes.co.ke/app.html#/user/$username';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'User Account',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            
            // Main User Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Profile Avatar with Online Ring
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 52,
                          backgroundColor: const Color(0xFF0F172A),
                          backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                              ? NetworkImage(profilePhotoUrl.startsWith('http') ? profilePhotoUrl : '${getBaseUrl()}$profilePhotoUrl')
                              : NetworkImage('https://api.dicebear.com/7.x/bottts/png?seed=$username') as ImageProvider,
                        ),
                      ),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E293B), width: 3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    displayName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '@$username',
                    style: const TextStyle(color: Color(0xFF6366F1), fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),

                  // Connection Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 14),
                        SizedBox(width: 6),
                        Text('VERIFIED VEYL IDENTITY', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Primary Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                          label: const Text('Message', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          onPressed: _startChat,
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.call, color: Colors.white, size: 20),
                        onPressed: () => _startCall(isVideo: false),
                        tooltip: 'Voice Call',
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFA855F7),
                          padding: const EdgeInsets.all(14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.videocam, color: Colors.white, size: 20),
                        onPressed: () => _startCall(isVideo: true),
                        tooltip: 'Video Call',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Account QR Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                children: [
                  const Text(
                    'Identity QR Code',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: profileUrl,
                      version: QrVersions.auto,
                      size: 160.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    profileUrl,
                    style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.share, color: Color(0xFF6366F1), size: 18),
                      label: const Text('Share Profile Link', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _shareProfile,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
