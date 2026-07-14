import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';

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
      final token = await storage.read(key: 'accessToken');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (DioException e, handler) async {
      if (e.response?.statusCode == 401) {
        // Implement token refresh logic here
      }
      return handler.next(e);
    },
  ));

  return dio;
});
