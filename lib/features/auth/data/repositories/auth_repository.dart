import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

/// Handles auth calls using the centralized ApiClient.
class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage;

  String? _accessToken;
  UserModel? _currentUser;

  AuthRepository(this._apiClient, this._storage);

  // ─── State ────────────────────────────────────────────────────────────────

  String? get accessToken => _accessToken;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _accessToken != null;

  // ─── Session ──────────────────────────────────────────────────────────────

  Future<bool> tryRestoreSession() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    final userJson = await _storage.read(key: AppConstants.userProfileKey);

    if (token != null && userJson != null) {
      _accessToken = token;
      _currentUser = UserModel.fromJsonString(userJson);
      return true;
    }
    return false;
  }

  Future<void> _saveSession(String token, UserModel user) async {
    _accessToken = token;
    _currentUser = user;
    await Future.wait([
      _storage.write(key: AppConstants.accessTokenKey, value: token),
      _storage.write(
        key: AppConstants.userProfileKey,
        value: user.toJsonString(),
      ),
    ]);
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _currentUser = null;
    await Future.wait([
      _storage.delete(key: AppConstants.accessTokenKey),
      _storage.delete(key: AppConstants.userProfileKey),
    ]);
  }

  // ─── Auth Operations ──────────────────────────────────────────────────────

  Future<AuthResponseModel> register({
    required String name,
    required String email,
    required String password,
    String? phoneNumber,
  }) async {
    try {
      // Notice how we don't need to pass headers. ApiClient handles it!
      final response = await _apiClient.dio.post(
        AppConstants.registerEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phoneNumber != null && phoneNumber.isNotEmpty)
            'phoneNumber': phoneNumber,
        },
      );

      final result = AuthResponseModel.fromJson(response.data['data']);
      await _saveSession(result.accessToken, result.user);
      return result;
    } on DioException catch (e) {
      throw AuthException(e.error.toString());
    }
  }

  Future<AuthResponseModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.loginEndpoint,
        data: {'email': email, 'password': password},
      );

      final result = AuthResponseModel.fromJson(response.data['data']);
      await _saveSession(result.accessToken, result.user);
      return result;
    } on DioException catch (e) {
      throw AuthException(e.error.toString());
    }
  }

  Future<UserModel> handleGoogleSignIn(String token) async {
    try {
      // Temporary override for this specific call since we need to pass the Google token
      // before it is saved in storage.
      final response = await _apiClient.dio.get(
        AppConstants.meEndpoint,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final user = UserModel.fromJson(response.data['data']);
      await _saveSession(token, user);
      return user;
    } on DioException catch (e) {
      throw AuthException(e.error.toString());
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _apiClient.dio.post(
        AppConstants.forgotPasswordEndpoint,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw AuthException(e.error.toString());
    }
  }

  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await _apiClient.dio.post(AppConstants.logoutEndpoint);
      }
    } catch (_) {
    } finally {
      await _clearSession();
    }
  }

  Future<UserModel> completeProfile({
    required String phoneNumber,
    String? name,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        AppConstants.completeProfileEndpoint,
        data: {'phoneNumber': phoneNumber, if (name != null) 'name': name},
      );

      final user = UserModel.fromJson(response.data['data']);
      await _storage.write(
        key: AppConstants.userProfileKey,
        value: user.toJsonString(),
      );
      _currentUser = user;
      return user;
    } on DioException catch (e) {
      throw AuthException(e.error.toString());
    }
  }

  Future<UserModel> updateProfile({String? name, String? phoneNumber}) async {
    try {
      final response = await _apiClient.dio.patch(
        AppConstants.updateProfileEndpoint,
        data: {
          if (name != null) 'name': name,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
        },
      );

      final user = UserModel.fromJson(response.data['data']);
      await _storage.write(
        key: AppConstants.userProfileKey,
        value: user.toJsonString(),
      );
      _currentUser = user;
      return user;
    } on DioException catch (e) {
      throw AuthException(e.error.toString());
    }
  }
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}
