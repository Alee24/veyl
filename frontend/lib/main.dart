import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';
import 'features/chat/socket_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Pre-check authentication status to keep user logged in forever
  String? token;
  try {
    const storage = FlutterSecureStorage();
    token = await storage.read(key: 'accessToken');
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('accessToken');
    }
  } catch (e) {
    try {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('accessToken');
    } catch (_) {}
  }

  runApp(
    ProviderScope(
      overrides: [
        if (token != null && token.isNotEmpty) authStateProvider.overrideWith((ref) => true),
      ],
      child: const VeylApp(),
    ),
  );
}

class VeylApp extends ConsumerStatefulWidget {
  const VeylApp({super.key});

  @override
  ConsumerState<VeylApp> createState() => _VeylAppState();
}

class _VeylAppState extends ConsumerState<VeylApp> {
  StreamSubscription? _callIncomingSub;
  bool _isCallScreenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final socketService = ref.read(socketServiceProvider);
      await socketService.connect();

      _callIncomingSub = socketService.onCallIncoming.listen((data) {
        if (!_isCallScreenOpen) {
          _isCallScreenOpen = true;
          final router = ref.read(routerProvider);
          router.push('/incoming_call', extra: data).then((_) {
            _isCallScreenOpen = false;
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _callIncomingSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'VEYL',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
