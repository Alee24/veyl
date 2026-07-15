import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

// ---------------------------------------------------------------------------
// Exception used to surface user-friendly Firebase / backend errors
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
  // REGISTER via Firebase Auth + backend
  // -------------------------------------------------------------------------
  Future<void> registerWithFirebase({
    required String username,
    required String email,
    required String password,
  }) async {
    UserCredential? credential;
    try {
      // 1. Create Firebase account
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Get Firebase ID token
      final idToken = await credential.user!.getIdToken();

      // 3. Register on Veyl backend using the Firebase token
      final response = await _dio.post('/auth/firebase-register', data: {
        'firebaseToken': idToken,
        'username': username,
        'displayName': username,
      });

      await _saveTokens(response.data);
      _authState.state = true;
    } on FirebaseAuthException catch (e) {
      // If backend fails after Firebase account creation, clean up Firebase
      if (credential != null) {
        try {
          await credential.user?.delete();
        } catch (_) {}
      }
      throw AuthException(_mapFirebaseError(e));
    } on DioException catch (e) {
      // If backend fails after Firebase account creation, clean up Firebase
      if (credential != null) {
        try {
          await credential.user?.delete();
        } catch (_) {}
      }
      final statusCode = e.response?.statusCode;
      final message = e.response?.data?['message'];
      if (statusCode == 409) {
        throw AuthException(
          message ?? 'Username is already taken. Please choose another.',
        );
      }
      throw AuthException(
        message ??
            'Could not connect to the server. Please try again later.',
      );
    } catch (e) {
      if (credential != null) {
        try {
          await credential.user?.delete();
        } catch (_) {}
      }
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // -------------------------------------------------------------------------
  // LOGIN via backend (username + password)
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
  // PROFILE PHOTO UPLOAD
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
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
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

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'weak-password':
        return 'Your password is too weak. Please use at least 8 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'Email registration is not enabled. Please contact support.';
      default:
        return e.message ?? 'Registration failed. Please try again.';
    }
  }
}
