import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

String getBaseUrl() {
  if (kIsWeb) {
    // Dynamically use the active browser URL (crucial for local vs VPS deployments)
    final origin = Uri.base.origin;
    // Handle hot restart trailing slash or port differences
    return origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
  }
  // For physical Android devices and emulator fallback
  return 'https://veyl.kkdes.co.ke';
}

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.read(secureStorageProvider);
  final dio = Dio(BaseOptions(
    baseUrl: getBaseUrl(),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      String? token;
      try {
        token = await storage.read(key: 'accessToken');
      } catch (_) {}

      if (token == null || token.isEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          token = prefs.getString('accessToken');
        } catch (_) {}
      }

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401 &&
          e.requestOptions.path != '/auth/guest' &&
          e.requestOptions.path != '/auth/login') {
        try {
          final refreshDio = Dio(BaseOptions(baseUrl: getBaseUrl()));
          final response = await refreshDio.post('/auth/guest');
          final data = response.data;
          final newToken = data['accessToken'];

          if (newToken != null && newToken.toString().isNotEmpty) {
            try {
              await storage.write(key: 'accessToken', value: newToken);
            } catch (_) {}
            try {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('accessToken', newToken);
            } catch (_) {}

            final options = e.requestOptions;
            options.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await refreshDio.fetch(options);
            return handler.resolve(retryResponse);
          }
        } catch (_) {}
      }
      return handler.next(e);
    },
  ));

  return dio;
});

String getAvatarUrl(String? photoUrl, [String fallbackSeed = 'user']) {
  if (photoUrl != null && photoUrl.isNotEmpty) {
    if (photoUrl.startsWith('http')) return photoUrl;
    if (photoUrl.startsWith('/')) return '${getBaseUrl()}$photoUrl';
    return '${getBaseUrl()}/$photoUrl';
  }
  return 'https://api.dicebear.com/7.x/bottts/png?seed=$fallbackSeed';
}
