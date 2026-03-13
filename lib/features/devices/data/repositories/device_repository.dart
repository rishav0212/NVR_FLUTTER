import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/device_models.dart';

class DeviceRepository {
  final ApiClient _apiClient;

  DeviceRepository(this._apiClient);

  DeviceException _handleError(DioException e) {
    int? attempts;
    // Extract metadata injected by our Spring Boot GlobalExceptionHandler
    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic> && responseData['data'] is Map<String, dynamic>) {
      attempts = responseData['data']['attemptsRemaining'];
    }
    
    return DeviceException(
      message: e.error?.toString() ?? 'An unknown error occurred.',
      attemptsRemaining: attempts,
    );
  }

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
        data: {'identifier': identifier, 'name': name, 'location': location, 'adminPin': adminPin},
      );
      return DeviceCredentials.fromJson(response.data['data']);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<NvrDevice> linkDevice({required String identifier, required String adminPin}) async {
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
}