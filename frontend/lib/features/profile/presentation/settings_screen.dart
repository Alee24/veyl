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
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          // Section: Theme
          _buildSectionHeader(context, 'Appearance'),
          ListTile(
            leading: Icon(Icons.palette_outlined, color: theme.colorScheme.primary),
            title: const Text('Theme Mode'),
            subtitle: Text(themeMode == ThemeMode.light ? 'Light Theme' : 'Dark Theme'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
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
          
          const Divider(),
          
          // Section: Privacy
          _buildSectionHeader(context, 'Privacy & Security'),
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
          
          const Divider(),
          
          // Section: Storage
          _buildSectionHeader(context, 'Storage & Media'),
          ListTile(
            leading: Icon(Icons.storage_outlined, color: theme.colorScheme.primary),
            title: const Text('Local Storage'),
            subtitle: const Text('Store media logs locally inside container'),
            trailing: const Text('Enabled', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
          letterSpacing: 1.1,
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
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title, style: TextStyle(color: theme.colorScheme.onBackground, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      activeColor: theme.colorScheme.primary,
    );
  }
}
