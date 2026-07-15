import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

// ---------------------------------------------------------------------------
// Exception used to surface user-friendly backend validation or network errors
// ---------------------------------------------------------------------------
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------
final authStateProvider = StateProvider<bool>((ref) => false);

final userProfileProvider = FutureProvider<Map<String, String>>((ref) async {
  try {
    final response = await ref.read(dioProvider).get('/auth/me');
    final user = response.data;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profilePhotoUrl', user['profilePhotoUrl'] ?? '');
    await prefs.setString('displayName', user['displayName'] ?? '');
    await prefs.setString('username', user['username'] ?? '');
    await prefs.setString('qrCode', user['qrCode'] ?? '');
    await prefs.setString('userId', user['id'] ?? '');
    return {
      'username': user['username'] ?? 'Guest',
      'displayName': user['displayName'] ?? 'Guest User',
      'qrCode': user['qrCode'] ?? '',
      'userId': user['id'] ?? '',
      'profilePhotoUrl': user['profilePhotoUrl'] ?? '',
    };
  } catch (e) {
    final prefs = await SharedPreferences.getInstance();
    return {
      'username': prefs.getString('username') ?? 'Guest',
      'displayName': prefs.getString('displayName') ?? 'Guest User',
      'qrCode': prefs.getString('qrCode') ?? '',
      'userId': prefs.getString('userId') ?? '',
      'profilePhotoUrl': prefs.getString('profilePhotoUrl') ?? '',
    };
  }
});

final authProvider = Provider((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(secureStorageProvider),
    ref.read(authStateProvider.notifier),
  );
});

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------
class AuthRepository {
  final Dio _dio;
  final dynamic storage;
  final StateController<bool> _authState;

  AuthRepository(this._dio, this.storage, this._authState);

  // -------------------------------------------------------------------------
  // REGISTER (username + password + optional recovery key)
  // -------------------------------------------------------------------------
  Future<void> register({
    required String username,
    required String password,
    String? recoveryKey,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'username': username,
        'password': password,
        'displayName': username, // Uses username as public display name by default
        if (recoveryKey != null) 'recoveryKey': recoveryKey,
      });

      await _saveTokens(response.data);
      _authState.state = true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'];
      if (statusCode == 409) {
        throw AuthException(
          message ?? 'Username is already taken. Please choose another.',
        );
      }
      throw AuthException(
        message ?? 'Could not connect to the server. Please try again later.',
      );
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // -------------------------------------------------------------------------
  // LOGIN (username + password)
  // -------------------------------------------------------------------------
  Future<void> login(String username, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      await _saveTokens(response.data);
      _authState.state = true;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 400) {
        throw AuthException('Invalid username or password.');
      }
      throw AuthException(
        'Could not connect to the server. Please try again later.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // PASSWORD RECOVERY (username + recovery key + new password)
  // -------------------------------------------------------------------------
  Future<void> recoverPassword({
    required String username,
    required String recoveryKey,
    required String newPassword,
  }) async {
    try {
      await _dio.post('/auth/recover', data: {
        'username': username,
        'recoveryKey': recoveryKey,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      final message = e.response?.data?['message'];
      throw AuthException(message ?? 'Failed to recover password. Please check your recovery key.');
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // -------------------------------------------------------------------------
  // GUEST LOGIN
  // -------------------------------------------------------------------------
  Future<void> guestLogin() async {
    try {
      final response = await _dio.post('/auth/guest');
      await _saveTokens(response.data);
      _authState.state = true;
    } on DioException catch (_) {
      throw AuthException(
        'Could not start guest session. Please check your connection.',
      );
    }
  }

  // -------------------------------------------------------------------------
  // PROFILE PHOTO UPLOAD (optional only)
  // -------------------------------------------------------------------------
  Future<void> uploadProfilePhoto(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final response = await _dio.post('/users/profile-photo', data: formData);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'profilePhotoUrl',
      response.data['profilePhotoUrl'] ?? '',
    );
  }

  // -------------------------------------------------------------------------
  // LOGOUT
  // -------------------------------------------------------------------------
  Future<void> logout() async {
    await storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _authState.state = false;
  }

  // -------------------------------------------------------------------------
  // HELPERS
  // -------------------------------------------------------------------------
  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await storage.write(key: 'accessToken', value: data['accessToken']);
    await storage.write(key: 'refreshToken', value: data['refreshToken']);
    await storage.write(key: 'userId', value: data['user']['id']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', data['user']['username'] ?? '');
    await prefs.setString(
      'displayName',
      data['user']['displayName'] ?? data['user']['username'] ?? '',
    );
    await prefs.setString('qrCode', data['user']['qrCode'] ?? '');
    await prefs.setString('userId', data['user']['id'] ?? '');
    await prefs.setString(
      'profilePhotoUrl',
      data['user']['profilePhotoUrl'] ?? '',
    );
  }
}
