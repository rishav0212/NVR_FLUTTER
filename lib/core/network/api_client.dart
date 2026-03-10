import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../../injection_container.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  ApiClient(this._dio, this._storage) {
    _dio.options.baseUrl = AppConstants.baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: AppConstants.connectTimeoutSeconds);
    _dio.options.receiveTimeout = const Duration(seconds: AppConstants.receiveTimeoutSeconds);

    _dio.interceptors.add(_AuthInterceptor(_storage));
  }

  Dio get dio => _dio;
}

/// The Interceptor is the middleman for all network traffic.
class _AuthInterceptor extends Interceptor {
  final FlutterSecureStorage storage;

  _AuthInterceptor(this.storage);

  /// Fires BEFORE the request leaves the app. Injects the Bearer token.
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await storage.read(key: AppConstants.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Content-Type'] = 'application/json';
    super.onRequest(options, handler);
  }

  /// Fires AFTER the response is received, but BEFORE the app processes it.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 1. GLOBAL 401 CATCHER: If the token expired, instantly log them out.
    if (err.response?.statusCode == 401) {
      // By calling getIt<AuthBloc>(), we bypass the UI completely and force
      // the entire application state back to Unauthenticated.
      getIt<AuthBloc>().add(LogoutRequested());
    }

    // 2. STANDARDIZE ERRORS: Extract the clean message from the Spring Boot ApiResponse
    String errorMessage = 'A network error occurred.';
    if (err.response != null && err.response?.data != null) {
      try {
        final data = err.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          errorMessage = data['message'];
        }
      } catch (_) {}
    } else if (err.type == DioExceptionType.connectionTimeout) {
      errorMessage = 'Connection timed out. Please check your internet.';
    }

    // Modify the exception to carry our clean message to the Repository
    final formattedError = DioException(
      requestOptions: err.requestOptions,
      response: err.response,
      type: err.type,
      error: errorMessage, 
    );

    super.onError(formattedError, handler);
  }
}