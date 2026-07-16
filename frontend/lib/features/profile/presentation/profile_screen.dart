import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/api_client.dart';
import '../../auth/auth_provider.dart';
import '../../../core/widgets/premium_button.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _pickAndUploadProfilePhoto(BuildContext context, WidgetRef ref) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 500, maxHeight: 500);
      if (image != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Updating profile photo...')),
        );
        
        await ref.read(authProvider).uploadProfilePhoto(image.path);
        
        // Invalidate provider to refresh profile
        ref.invalidate(userProfileProvider);
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload photo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profileAsync = ref.watch(userProfileProvider);
    final username = profileAsync.value?['username'] ?? 'Guest';
    final displayName = profileAsync.value?['displayName'] ?? 'Guest User';
    final profilePhotoUrl = profileAsync.value?['profilePhotoUrl'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.iconTheme.color),
            onPressed: () => context.push('/settings'),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Welcome Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0B132B), // Very dark navy
                    Color(0xFF1C2541), // Deep navy
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00F2FE).withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => _pickAndUploadProfilePhoto(context, ref),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00F2FE),
                                      Color(0xFF2563EB),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: const Color(0xFF0B132B),
                                  backgroundImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                                      ? NetworkImage('${getBaseUrl()}$profilePhotoUrl')
                                      : NetworkImage('https://i.pravatar.cc/150?u=$username') as ImageProvider,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, size: 10, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                              ),
                              Text(
                                '@$username',
                                style: const TextStyle(color: Colors.white70, fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('Online', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // QR Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161E2E) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your QR Code',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: QrImageView(
                            data: 'https://veyl.kkdes.co.ke/$username',
                            version: QrVersions.auto,
                            size: 160.0,
                            gapless: false,
                            embeddedImage: (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty)
                                ? NetworkImage('${getBaseUrl()}$profilePhotoUrl')
                                : const NetworkImage('https://veyl.kkdes.co.ke/app_icon.png') as ImageProvider,
                            embeddedImageStyle: const QrEmbeddedImageStyle(
                              size: Size(36, 36),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'veyl.kkdes.co.ke/$username',
                          style: TextStyle(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 24),
                        PremiumButton(
                          onPressed: () async {
                            await Share.share(
                              'Connect with me on Veyl! Scan my identity or download the app: https://veyl.kkdes.co.ke/',
                              subject: 'Veyl Profile Connection',
                            );
                          },
                          child: const Text('Share Profile'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Settings List grouped container
            _buildGroupContainer(
              theme: theme,
              children: [
                _buildSettingsTile(context, Icons.edit_outlined, 'Edit Profile', () {}),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(context, Icons.lock_outline, 'Privacy & Security', () => context.push('/settings')),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(context, Icons.devices, 'Linked Devices', () {}),
                const Divider(height: 1, indent: 56),
                _buildSettingsTile(
                  context,
                  Icons.logout,
                  'Log out',
                  () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDark ? const Color(0xFF161E2E) : Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        title: Text(
                          'Log out',
                          style: TextStyle(
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        content: Text(
                          'Are you sure you want to log out?',
                          style: TextStyle(color: isDark ? Colors.white70 : Colors.grey[750]),
                        ),
                        actions: [
                          TextButton(
                            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                            onPressed: () => Navigator.pop(context, false),
                          ),
                          TextButton(
                            child: const Text('Log out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(authProvider).logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupContainer({required List<Widget> children, required ThemeData theme}) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return HoverSettingsTile(
      leading: Icon(icon, color: isDark ? Colors.white70 : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: title == 'Log out' 
              ? Colors.redAccent 
              : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: title == 'Log out' ? Colors.redAccent.withOpacity(0.5) : Colors.grey,
      ),
      onTap: onTap,
    );
  }
}

// -------------------------------------------------------------
// Veyl Design System Premium Stateful Hover Settings Tile
// -------------------------------------------------------------

class HoverSettingsTile extends StatefulWidget {
  final Widget leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const HoverSettingsTile({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<HoverSettingsTile> createState() => _HoverSettingsTileState();
}

class _HoverSettingsTileState extends State<HoverSettingsTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _isHovered 
                ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02))
                : Colors.transparent,
          ),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.title,
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      widget.subtitle!,
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
    );
  }
}
