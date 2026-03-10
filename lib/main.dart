import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart'; // NEW: Importing your go_router configuration
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'shared/widgets/shared_widgets.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load Environment Variables (.env)
  await dotenv.load(fileName: ".env");

  // Initialize Dependency Injection BEFORE running the app
  await initDi();

  runApp(const NvrApp());
}

class NvrApp extends StatefulWidget {
  const NvrApp({super.key});

  @override
  State<NvrApp> createState() => _NvrAppState();
}

class _NvrAppState extends State<NvrApp> {
  late final AppRouter _appRouter;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize our new GoRouter, passing the AuthBloc from GetIt
    _appRouter = AppRouter(getIt<AuthBloc>());

    // Trigger the session restoration check on startup
    getIt<AuthBloc>().add(AppStarted());

    _initDeepLinks();
  }

  // This listens natively to the OS. When Google redirects to nvr://auth/callback?token=...
  // it intercepts the URI, extracts the token, and pushes it to the BLoC to log the user in!
  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == AppConstants.deepLinkScheme &&
          uri.path == AppConstants.oauthCallbackPath) {
        // Handle variations of token parameter naming
        final token =
            uri.queryParameters['token'] ?? uri.queryParameters['accessToken'];

        if (token != null && token.isNotEmpty) {
          getIt<AuthBloc>().add(GoogleAuthTokenReceived(token));
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Using BlocProvider.value since the BLoC is managed by GetIt
    return BlocProvider.value(
      value: getIt<AuthBloc>(),
      // Upgraded to MaterialApp.router to use go_router
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: _appRouter.router, // Connects GoRouter!
      ),
    );
  }
}

/// Minimal splash screen shown while checking secure storage on app start.
/// Renamed to be public so the AppRouter can access it.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedEntrance(
              delay: const Duration(milliseconds: 100),
              child: const Icon(
                Icons.videocam_outlined,
                color: AppTheme.amber,
                size: 48,
              ),
            ),
            const SizedBox(height: AppTheme.md),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 200),
              child: Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontSize: 28,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.xxl),
            AnimatedEntrance(
              delay: const Duration(milliseconds: 300),
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.amber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
