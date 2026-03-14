// ═════════════════════════════════════════════════════════════════════════════
// FILE: lib/features/stream/data/repositories/stream_repository.dart
// ═════════════════════════════════════════════════════════════════════════════
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/stream_models.dart';

class StreamException implements Exception {
  final String message;
  StreamException(this.message);
  @override
  String toString() => message;
}

class StreamRepository {
  final ApiClient _apiClient;

  StreamRepository(this._apiClient);

  Future<StreamStartResponse> startLiveStream(
    String deviceId,
    String channelId,
    LiveStreamRequest request,
  ) async {
    try {
      // FIXED: Added .dio before .post
      final response = await _apiClient.dio.post(
        '/api/devices/$deviceId/channels/$channelId/live',
        data: request.toJson(),
      );
      return StreamStartResponse.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw StreamException('Failed to start stream: ${_extractMessage(e)}');
    } catch (e) {
      throw StreamException('Failed to start stream: ${e.toString()}');
    }
  }

  Future<void> sendHeartbeat(String sessionId) async {
    try {
      // FIXED: Added .dio before .post
      await _apiClient.dio.post('/api/streams/$sessionId/heartbeat');
    } on DioException catch (e) {
      throw StreamException('Heartbeat failed: ${_extractMessage(e)}');
    } catch (e) {
      throw StreamException('Heartbeat failed');
    }
  }

  Future<void> stopStream(String sessionId) async {
    try {
      // FIXED: Added .dio before .delete
      await _apiClient.dio.delete('/api/streams/$sessionId');
    } on DioException catch (e) {
      throw StreamException(
        'Failed to stop stream cleanly: ${_extractMessage(e)}',
      );
    } catch (e) {
      throw StreamException('Failed to stop stream cleanly');
    }
  }

  // Helper to extract clean error messages
  String _extractMessage(DioException e) {
    if (e.response?.data is Map<String, dynamic> &&
        e.response?.data['message'] != null) {
      return e.response?.data['message'];
    }
    return e.error?.toString() ?? 'Unknown network error';
  }
}
