import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/qr/presentation/qr_scanner_screen.dart';
import '../features/chat/presentation/chat_list_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/notifications_screen.dart';
import '../features/calling/presentation/calls_screen.dart';
import '../features/profile/presentation/settings_screen.dart';
import '../features/auth/auth_provider.dart';
import '../features/calling/presentation/room_screen.dart';
import '../features/calling/presentation/incoming_call_screen.dart';
import '../features/calling/presentation/outgoing_call_screen.dart';
import 'main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isRoomRoute = state.matchedLocation.startsWith('/room/');
      final isCallRoute = state.matchedLocation == '/incoming_call' || state.matchedLocation == '/outgoing_call';
      if (!authState && !isLoggingIn && !isRoomRoute && !isCallRoute) return '/login';
      if (authState && isLoggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/incoming_call',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return IncomingCallScreen(
            callerId: data['callerId'],
            callerName: data['callerName'],
            callerUsername: data['callerUsername'],
            roomName: data['roomName'],
          );
        },
      ),
      GoRoute(
        path: '/outgoing_call',
        builder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return OutgoingCallScreen(
            calleeId: data['calleeId'],
            calleeName: data['calleeName'],
            calleeUsername: data['calleeUsername'],
            roomName: data['roomName'],
          );
        },
      ),
      GoRoute(
        path: '/room/:id',
        builder: (context, state) => RoomScreen(roomId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(chatId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const QrScannerScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/chats',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/calls',
            builder: (context, state) => const CallsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
