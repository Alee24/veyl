import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';

final authStateProvider = StateProvider<bool>((ref) => false);

final userProfileProvider = FutureProvider<Map<String, String>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return {
    'username': prefs.getString('username') ?? 'Guest',
    'displayName': prefs.getString('displayName') ?? 'Guest User',
    'qrCode': prefs.getString('qrCode') ?? '',
    'userId': prefs.getString('userId') ?? '',
  };
});

final authProvider = Provider((ref) {
  return AuthRepository(
    ref.read(dioProvider),
    ref.read(secureStorageProvider),
    ref.read(authStateProvider.notifier),
  );
});

class AuthRepository {
  final Dio _dio;
  final storage;
  final StateController<bool> _authState;

  AuthRepository(this._dio, this.storage, this._authState);

  Future<void> login(String username, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    
    await _saveTokens(response.data);
    _authState.state = true;
  }

  Future<void> register(String username, String password, String displayName) async {
    final response = await _dio.post('/auth/register', data: {
      'username': username,
      'password': password,
      'displayName': displayName,
    });
    
    await _saveTokens(response.data);
    _authState.state = true;
  }

  Future<void> guestLogin() async {
    final response = await _dio.post('/auth/guest');
    await _saveTokens(response.data);
    _authState.state = true;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    await storage.write(key: 'accessToken', value: data['accessToken']);
    await storage.write(key: 'refreshToken', value: data['refreshToken']);
    await storage.write(key: 'userId', value: data['user']['id']);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', data['user']['username'] ?? '');
    await prefs.setString('displayName', data['user']['displayName'] ?? data['user']['username'] ?? '');
    await prefs.setString('qrCode', data['user']['qrCode'] ?? '');
    await prefs.setString('userId', data['user']['id'] ?? '');
  }
  
  Future<void> logout() async {
    await storage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _authState.state = false;
  }
}
