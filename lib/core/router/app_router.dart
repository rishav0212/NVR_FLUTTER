import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/other_pages.dart';
import '../../main.dart'; // To access _SplashScreen

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  late final GoRouter router = GoRouter(
    initialLocation: AppConstants.splashRoute,
    // Listens to your BLoC. If state changes, it re-evaluates the redirect logic!
    refreshListenable: _GoRouterRefreshStream(authBloc.stream),
    
    redirect: (context, state) {
      final authState = authBloc.state;
      final path = state.uri.path;

      final isSplash = path == AppConstants.splashRoute;
      final isAuthScreen = path == AppConstants.loginRoute || 
                           path == AppConstants.registerRoute || 
                           path == AppConstants.forgotPasswordRoute;

      // 1. App is starting
      if (authState is AuthInitial) return AppConstants.splashRoute;

      // 2. User is NOT logged in
      if (authState is AuthUnauthenticated || authState is AuthError || authState is AuthActionSuccess) {
        if (isAuthScreen) return null; // Let them browse auth screens
        return AppConstants.loginRoute; // Kick unauthorized users to login
      }

      // 3. User logged in, but needs to add phone number
      if (authState is AuthProfileIncomplete) {
        if (path == AppConstants.completeProfileRoute) return null;
        return AppConstants.completeProfileRoute;
      }

      // 4. User is fully authenticated
      if (authState is AuthAuthenticated) {
        if (isAuthScreen || isSplash || path == AppConstants.completeProfileRoute) {
          return AppConstants.homeRoute; // Send to dashboard
        }
      }

      return null; // No redirect needed
    },
    
    routes: [
      GoRoute(path: AppConstants.splashRoute, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppConstants.loginRoute, builder: (context, state) => const LoginPage()),
      GoRoute(path: AppConstants.registerRoute, builder: (context, state) => const RegisterPage()),
      GoRoute(path: AppConstants.forgotPasswordRoute, builder: (context, state) => const ForgotPasswordPage()),
      GoRoute(path: AppConstants.completeProfileRoute, builder: (context, state) => const CompleteProfilePage()),
      GoRoute(path: AppConstants.homeRoute, builder: (context, state) => const HomePage()),
    ],
  );
}

// Helper class to convert a BLoC Stream into a Listenable for GoRouter
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