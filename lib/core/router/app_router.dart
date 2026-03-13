import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/other_pages.dart';
import '../../main.dart';
import '../theme/app_theme.dart';
import '../../features/devices/data/models/device_models.dart';
import '../../features/devices/presentation/bloc/device_bloc.dart';
import '../../features/devices/presentation/pages/add_device_page.dart';
import '../../features/devices/presentation/pages/register_device_page.dart';
import '../../features/devices/presentation/pages/pin_entry_page.dart';
import '../../features/devices/presentation/pages/credentials_page.dart';
import '../../injection_container.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: AppConstants.splashRoute,
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),

    redirect: (context, state) {
      final authState = authBloc.state;
      final path = state.uri.path;

      final isSplash = path == AppConstants.splashRoute;
      final isAuthScreen =
          path == AppConstants.loginRoute ||
          path == AppConstants.registerRoute ||
          path == AppConstants.forgotPasswordRoute;

      if (authState is AuthInitial) return AppConstants.splashRoute;

      // ✅ FIXED: AuthError removed — errors don't mean unauthenticated.
      // Pages handle AuthError display themselves via BlocBuilder/ErrorBanner.
      if (authState is AuthUnauthenticated || authState is AuthActionSuccess) {
        if (isAuthScreen) return null;
        return AppConstants.loginRoute;
      }

      if (authState is AuthProfileIncomplete) {
        if (path == AppConstants.completeProfileRoute) return null;
        return AppConstants.completeProfileRoute;
      }

      if (authState is AuthAuthenticated) {
        if (isAuthScreen ||
            isSplash ||
            path == AppConstants.completeProfileRoute) {
          return AppConstants.homeRoute;
        }
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppConstants.splashRoute,
        pageBuilder: (context, state) =>
            _buildPage(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppConstants.loginRoute,
        pageBuilder: (context, state) => _buildPage(state, const LoginPage()),
      ),
      GoRoute(
        path: AppConstants.registerRoute,
        pageBuilder: (context, state) =>
            _buildPage(state, const RegisterPage()),
      ),
      GoRoute(
        path: AppConstants.forgotPasswordRoute,
        pageBuilder: (context, state) =>
            _buildPage(state, const ForgotPasswordPage()),
      ),
      GoRoute(
        path: AppConstants.completeProfileRoute,
        pageBuilder: (context, state) =>
            _buildPage(state, const CompleteProfilePage()),
      ),
      GoRoute(
        path: AppConstants.homeRoute,
        pageBuilder: (context, state) => _buildPage(state, const HomePage()),
      ),
      GoRoute(
        path: AppConstants.addDeviceRoute,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<DeviceBloc>(), // <--- FIX THIS
          child: const AddDevicePage(),
        ),
      ),
      GoRoute(
        path: AppConstants.registerDeviceRoute,
        builder: (context, state) => BlocProvider(
          create: (_) => getIt<DeviceBloc>(), // <--- FIX THIS
          child: RegisterDevicePage(identifier: state.extra as String),
        ),
      ),
      GoRoute(
        path: AppConstants.pinEntryRoute,
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return BlocProvider(
            create: (_) => getIt<DeviceBloc>(), // <--- FIX THIS
            child: PinEntryPage(
              identifier: data['identifier']!,
              deviceName: data['deviceName']!,
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.credentialsRoute,
        builder: (context, state) =>
            CredentialsPage(credentials: state.extra as DeviceCredentials),
      ),
    ],
  );

  // ── Page transition builder ───────────────────────────────────────────────
  //
  // Defined ONCE here — all routes call _buildPage() instead of repeating
  // the transition logic. To change the transition app-wide, edit this only.
  //
  // Effect: fade + subtle upward slide (0.05 offset).
  // Duration: AppTheme.tSlow (540ms) with easeOutExpo curve.
  //
  static Page<void> _buildPage(GoRouterState state, Widget child) {
    return CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppTheme.tSlow,
      reverseTransitionDuration: AppTheme.tMid,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade in over first 70% of animation
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.7, curve: AppTheme.curveEntrance),
        );

        // Slide up from a slight offset
        final slide =
            Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: AppTheme.curveEntrance),
            );

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }
}

// ── GoRouter refresh stream ───────────────────────────────────────────────────
//
// Converts the AuthBloc stream into a ChangeNotifier so GoRouter can
// listen to state changes and re-evaluate redirect() automatically.
//
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
