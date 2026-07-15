import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';

final roomServiceProvider = Provider((ref) {
  return RoomRepository(ref.read(dioProvider));
});

class RoomRepository {
  final Dio _dio;
  RoomRepository(this._dio);

  Future<Map<String, dynamic>> createRoom(String name, String type, {int? durationHours}) async {
    final response = await _dio.post('/room', data: {
      'name': name,
      'type': type,
      if (durationHours != null) 'durationHours': durationHours,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getRoom(String roomId) async {
    // Public endpoint bypasses standard auth wrapper if offline or unregistered
    final response = await _dio.get('/room/$roomId');
    return response.data;
  }
}
