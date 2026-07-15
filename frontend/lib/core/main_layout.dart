import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../features/chat/socket_service.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;
  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;
  StreamSubscription? _incomingCallSub;

  @override
  void initState() {
    super.initState();
    
    // Connect Socket and listen for incoming calls globally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      socketService.connect();

      _incomingCallSub = socketService.onCallIncoming.listen((data) {
        if (mounted) {
          context.push('/incoming_call', extra: data);
        }
      });
    });
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    super.dispose();
  }

  void _onItemTapped(int index, BuildContext context) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/contacts');
        break;
      case 2:
        context.go('/chats'); // Center button goes to Chats List
        break;
      case 3:
        context.go('/calls');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: widget.child,
      
      // Premium floating, rounded bottom navigation bar (matches screenshot mockup exactly)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 72,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFF3F4F6),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 1. Home / Chats Icon
              _buildBarItem(
                index: 0,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Chats',
                theme: theme,
              ),
              // 2. Contacts Icon
              _buildBarItem(
                index: 1,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Contacts',
                theme: theme,
              ),
              // 3. Highlighted Center Floating Button
              GestureDetector(
                onTap: () => _onItemTapped(2, context),
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF00F2FE), // Cyan
                        Color(0xFF3B82F6), // Blue
                        Color(0xFF8B5CF6), // Purple
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.chat_bubble,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              // 4. Calls Icon
              _buildBarItem(
                index: 3,
                icon: Icons.call_outlined,
                activeIcon: Icons.call,
                label: 'Calls',
                theme: theme,
              ),
              // 5. Settings Icon
              _buildBarItem(
                index: 4,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required ThemeData theme,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = theme.brightness == Brightness.dark;
    
    final selectedColor = theme.colorScheme.secondary;
    final unselectedColor = Colors.grey[550];

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index, context),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? selectedColor : unselectedColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? selectedColor : unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
