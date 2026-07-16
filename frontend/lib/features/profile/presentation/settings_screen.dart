import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme.dart';

// Providers for the Settings Toggles
final hideOnlineStatusProvider = StateProvider<bool>((ref) => false);
final hideLastSeenProvider = StateProvider<bool>((ref) => false);
final hideProfilePhotoProvider = StateProvider<bool>((ref) => false);
final hideReadReceiptsProvider = StateProvider<bool>((ref) => false);
final disableGuestChatProvider = StateProvider<bool>((ref) => false);

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    ref.read(hideOnlineStatusProvider.notifier).state = prefs.getBool('hideOnlineStatus') ?? false;
    ref.read(hideLastSeenProvider.notifier).state = prefs.getBool('hideLastSeen') ?? false;
    ref.read(hideProfilePhotoProvider.notifier).state = prefs.getBool('hideProfilePhoto') ?? false;
    ref.read(hideReadReceiptsProvider.notifier).state = prefs.getBool('hideReadReceipts') ?? false;
    ref.read(disableGuestChatProvider.notifier).state = prefs.getBool('disableGuestChat') ?? false;
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Appearance
            _buildSectionHeader(context, 'Appearance'),
            const SizedBox(height: 8),
            _buildGroupContainer(
              theme: theme,
              children: [
                HoverSettingsTile(
                  leading: Icon(Icons.palette_outlined, color: theme.colorScheme.secondary),
                  title: Text(
                    'Theme Mode',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    themeMode == ThemeMode.light ? 'Light Theme' : 'Dark Theme',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<ThemeMode>(
                      value: themeMode,
                      dropdownColor: theme.cardColor,
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).state = mode;
                        }
                      },
                      items: const [
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section: Privacy
            _buildSectionHeader(context, 'Privacy & Security'),
            const SizedBox(height: 8),
            _buildGroupContainer(
              theme: theme,
              children: [
                _buildSwitchTile(
                  context,
                  'Hide Online Status',
                  'Others won\'t see when you are active',
                  ref.watch(hideOnlineStatusProvider),
                  (val) {
                    ref.read(hideOnlineStatusProvider.notifier).state = val;
                    _saveSetting('hideOnlineStatus', val);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  context,
                  'Hide Last Seen',
                  'Hide when you were last online',
                  ref.watch(hideLastSeenProvider),
                  (val) {
                    ref.read(hideLastSeenProvider.notifier).state = val;
                    _saveSetting('hideLastSeen', val);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  context,
                  'Hide Profile Photo',
                  'Only your contacts can see your avatar',
                  ref.watch(hideProfilePhotoProvider),
                  (val) {
                    ref.read(hideProfilePhotoProvider.notifier).state = val;
                    _saveSetting('hideProfilePhoto', val);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  context,
                  'Hide Read Receipts',
                  'Others won\'t see double blue checkmarks',
                  ref.watch(hideReadReceiptsProvider),
                  (val) {
                    ref.read(hideReadReceiptsProvider.notifier).state = val;
                    _saveSetting('hideReadReceipts', val);
                  },
                ),
                const Divider(height: 1, indent: 56),
                _buildSwitchTile(
                  context,
                  'Disable Guest Chat',
                  'Prevent guest profiles from contacting you',
                  ref.watch(disableGuestChatProvider),
                  (val) {
                    ref.read(disableGuestChatProvider.notifier).state = val;
                    _saveSetting('disableGuestChat', val);
                  },
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section: Storage
            _buildSectionHeader(context, 'Storage & Media'),
            const SizedBox(height: 8),
            _buildGroupContainer(
              theme: theme,
              children: [
                HoverSettingsTile(
                  leading: Icon(Icons.storage_outlined, color: theme.colorScheme.secondary),
                  title: Text(
                    'Local Storage',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text('Store media logs locally inside container', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Text('Enabled', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.secondary,
          letterSpacing: 1.2,
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

  Widget _buildSwitchTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return HoverSettingsTile(
      leading: Icon(Icons.shield_outlined, color: theme.colorScheme.secondary),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: theme.colorScheme.secondary,
      ),
      onTap: () => onChanged(!value),
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
