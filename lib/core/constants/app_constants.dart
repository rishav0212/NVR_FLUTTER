import 'package:flutter_dotenv/flutter_dotenv.dart';

/// All string constants, route names, and shared values.
/// Keeping these centralized means a single change propagates everywhere.
class AppConstants {
  // ─── API ─────────────────────────────────────────────────────────────────────
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080';
  // Auth endpoints
  static const String registerEndpoint = '/api/auth/register';
  static const String loginEndpoint = '/api/auth/login';

  static const String logoutEndpoint = '/api/auth/logout';
  static const String meEndpoint = '/api/auth/me';
  static const String completeProfileEndpoint = '/api/auth/complete-profile';
  static const String updateProfileEndpoint = '/api/auth/profile';
  static const String googleAuthEndpoint = '/api/auth/oauth2/authorize/google';

  // NEW: Forgot Password endpoint
  static const String forgotPasswordEndpoint = '/api/auth/forgot-password';

  // ─── Storage Keys ─────────────────────────────────────────────────────────────
  /// Stored in flutter_secure_storage — encrypted on device.
  static const String accessTokenKey = 'access_token';
  static const String userProfileKey = 'user_profile';

  // ─── Routes ──────────────────────────────────────────────────────────────────
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String completeProfileRoute = '/complete-profile';
  static const String homeRoute = '/home';
  static const String forgotPasswordRoute = '/forgot-password'; // NEW

  // ─── Device Endpoints ─────────────────────────────────────────────────────────
  static const String deviceCheckEndpoint = '/api/devices/check';
  static const String deviceRegisterEndpoint = '/api/devices/register';
  static const String deviceLinkEndpoint = '/api/devices/link';
  static const String devicesEndpoint = '/api/devices';

  // ─── Device Routes ────────────────────────────────────────────────────────────
  static const String addDeviceRoute = '/devices/add';
  static const String registerDeviceRoute = '/devices/register';
  static const String pinEntryRoute = '/devices/pin';
  static const String credentialsRoute = '/devices/credentials';
  // ─── Deep Link ───────────────────────────────────────────────────────────────
  /// Flutter registers this URI scheme so Google OAuth2 redirects land here.
  /// Must match app.oauth2-redirect-uri in application.yml.
  static const String deepLinkScheme = 'nvr';
  static const String oauthCallbackPath = '/auth/callback';

  // ─── Misc ────────────────────────────────────────────────────────────────────
  static const String appName = 'Sentinel';
  static const int connectTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
}
