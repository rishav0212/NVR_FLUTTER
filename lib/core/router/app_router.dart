// ═════════════════════════════════════════════════════════════════════════════
// FILE: lib/core/router/app_router.dart
// ═════════════════════════════════════════════════════════════════════════════
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/devices/presentation/pages/device_detail_page.dart';
import '../../features/devices/presentation/pages/device_dashboard_page.dart';
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
import '../../features/stream/presentation/pages/live_view_page.dart';
import '../../features/stream/presentation/bloc/stream_bloc.dart';
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
        pageBuilder: (context, state) =>
            _buildPage(state, const DeviceDashboardPage()),
      ),
      // ── Device wizard routes ─────────────────────────────────────────────
      //
      // Each wizard page gets a fresh DeviceBloc instance via BlocProvider.
      // Using pageBuilder keeps the same slide+fade transition as auth routes.
      //
      GoRoute(
        path: AppConstants.addDeviceRoute,
        pageBuilder: (context, state) => _buildPage(
          state,
          BlocProvider(
            create: (_) => getIt<DeviceBloc>(),
            child: const AddDevicePage(),
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.registerDeviceRoute,
        pageBuilder: (context, state) => _buildPage(
          state,
          BlocProvider(
            create: (_) => getIt<DeviceBloc>(),
            child: RegisterDevicePage(identifier: state.extra as String),
          ),
        ),
      ),
      GoRoute(
        path: AppConstants.pinEntryRoute,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>;
          return _buildPage(
            state,
            BlocProvider(
              create: (_) => getIt<DeviceBloc>(),
              child: PinEntryPage(
                identifier: data['identifier']!,
                deviceName: data['deviceName']!,
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppConstants.credentialsRoute,
        pageBuilder: (context, state) => _buildPage(
          state,
          CredentialsPage(credentials: state.extra as DeviceCredentials),
        ),
      ),

      // ── Device detail route ──────────────────────────────────────────────
      //
      // Reached via context.go('/devices/$id') from credentials or pin pages.
      // Path param :id is the device UUID.
      //
      GoRoute(
        path: '/devices/:id',
        pageBuilder: (context, state) => _buildPage(
          state,
          BlocProvider(
            // <--- Wrap in BlocProvider
            create: (_) => getIt<DeviceBloc>(),
            child: DeviceDetailPage(deviceId: state.pathParameters['id']!),
          ),
        ),
      ),
      GoRoute(
        path: '/devices/:id/channels/:channelId/live',
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, dynamic>? ?? {};
          return _buildPage(
            state,
            BlocProvider(
              create: (_) => getIt<StreamBloc>(),
              child: LiveViewPage(
                deviceId: state.pathParameters['id']!,
                channelId: state.pathParameters['channelId']!,
                channelName: data['channelName'] ?? 'Camera',
              ),
            ),
          );
        },
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
  Type? _lastStateType;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    // Filters the continuous stream of authentication events down to only structural state changes.
    // GoRouter completely reconstructs the navigation tree and evaluates redirects whenever
    // notifyListeners is called. By caching the runtime type, we prevent the router from
    // halting the UI thread to rebuild during transient states (like loading spinners or minor errors),
    // guaranteeing butter-smooth route transitions.
    _subscription = stream.asBroadcastStream().listen((state) {
      if (_lastStateType != state.runtimeType) {
        _lastStateType = state.runtimeType;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
