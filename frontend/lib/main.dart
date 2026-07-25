import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/auth/auth_provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

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

class VeylApp extends ConsumerWidget {
  const VeylApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
