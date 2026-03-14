import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/device_models.dart';

class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  Future<DeviceCheckResult> checkDevice(String identifier) async {
    try {
      final response = await _apiClient.dio.get(
        AppConstants.deviceCheckEndpoint,
        queryParameters: {'identifier': identifier},
      );
      return DeviceCheckResult.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<DeviceCredentials> registerDevice({
    required String identifier,
    required String name,
    String? location,
    required String adminPin,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.deviceRegisterEndpoint,
        data: {
          'identifier': identifier,
          'name': name,
          'location': location,
          'adminPin': adminPin,
        },
      );
      return DeviceCredentials.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<NvrDevice> linkDevice({
    required String identifier,
    required String adminPin,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.deviceLinkEndpoint,
        data: {'identifier': identifier, 'adminPin': adminPin},
      );
      return NvrDevice.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<NvrDevice>> getMyDevices() async {
    try {
      final response = await _apiClient.dio.get(AppConstants.devicesEndpoint);
      final List<dynamic> list = response.data['data'];
      return list.map((json) => NvrDevice.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _apiClient.dio.delete('${AppConstants.devicesEndpoint}/$deviceId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // --- ADDED IN PHASE 3 ---
  // Fetches the channels available on a specific NVR device.
  // Added try/catch block to ensure consistent error parsing via _handleError.
  // Changed _apiClient.get to _apiClient.dio.get to access the underlying Dio instance.
  Future<List<Map<String, dynamic>>> getDeviceChannels(String deviceId) async {
    try {
      final response = await _apiClient.dio.get('/api/devices/$deviceId/channels');
      return List<Map<String, dynamic>>.from(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ONLY ONE _handleError METHOD NOW!
  DeviceException _handleError(DioException e) {
    int? attempts;
    DateTime? lockedTime;

    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic> &&
        responseData['data'] is Map<String, dynamic>) {
      attempts = responseData['data']['attemptsRemaining'];
      if (responseData['data']['lockedUntil'] != null) {
        lockedTime = DateTime.parse(
          responseData['data']['lockedUntil'],
        ).toLocal();
      }
    }

    // Tiny upgrade: Also safely attempt to grab the exact Spring Boot error message!
    String errorMessage = 'An unknown error occurred.';
    if (responseData is Map<String, dynamic> &&
        responseData['message'] != null) {
      errorMessage = responseData['message'];
    } else if (e.error != null) {
      errorMessage = e.error.toString();
    }

    return DeviceException(
      message: errorMessage,
      attemptsRemaining: attempts,
      lockedUntil: lockedTime,
    );
  }
}