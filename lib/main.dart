import 'dart:async'; // <-- ADDED for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart'; // <-- ADDED for Google Deep Linking

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. MUST BE FIRST: Load .env so ApiClient can successfully read the baseUrl
  await dotenv.load(fileName: ".env");

  // 2. THEN initialize Dependency Injection
  await initDi();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Make system bars transparent so the theme handles the background dynamically
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const NvrApp());
}

class NvrApp extends StatefulWidget {
  const NvrApp({super.key});

  @override
  State<NvrApp> createState() => _NvrAppState();
}

class _NvrAppState extends State<NvrApp> {
  // AppRouter depends on AuthBloc — create both once here so GoRouter's
  // refreshListenable and the BlocProvider share the exact same instance.
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;

  // Deep Link variables for Google OAuth
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(AppStarted());
    _appRouter = AppRouter(_authBloc);

    // Initialize Google Deep Link listener
    _initDeepLinks();
  }

  // Restored native deep linking.
  // Intercepts nvr://auth/callback?token=... and logs the user in!
  void _initDeepLinks() {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (uri.scheme == AppConstants.deepLinkScheme &&
          uri.path == AppConstants.oauthCallbackPath) {
        final token =
            uri.queryParameters['token'] ?? uri.queryParameters['accessToken'];

        if (token != null && token.isNotEmpty) {
          _authBloc.add(GoogleAuthTokenReceived(token));
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel(); // Clean up deep link listener
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,

        // Restored dynamic System Light/Dark Mode switching
        themeMode: ThemeMode.system,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,

        routerConfig: _appRouter.router,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
//
// Public — imported by app_router.dart for the splash route.
// Shown while AuthBloc restores session from secure storage on app start.
//
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: AppTheme.tXSlow)
      ..forward();
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: AppTheme.curveEntrance),
    );
    _scale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppTheme.curveEntrance));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Pulls the active background design securely based on light/dark mode
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // 1. Core gradient background (Aurora for dark, Pearl for light)
          Container(decoration: BoxDecoration(gradient: ext.bgGradient)),

          // 2. Mesh background blobs (Dynamically adapts to theme)
          Positioned(
            top: -150,
            left: -150,
            width: 500,
            height: 500,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: ext.meshAmber,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            width: 400,
            height: 400,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: ext.meshIndigo,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // 3. Splash Content
          Center(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, child) => FadeTransition(
                opacity: _opacity,
                child: ScaleTransition(scale: _scale, child: child),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppTheme.amberBtn,
                      borderRadius: BorderRadius.circular(AppTheme.rXl),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.amber.withOpacity(0.20),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.videocam_rounded,
                      color: colorScheme.onPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppTheme.s20),
                  Text(
                    AppConstants.appName,
                    style: Theme.of(
                      context,
                    ).textTheme.displayMedium?.copyWith(letterSpacing: -0.5),
                  ),
                  const SizedBox(height: AppTheme.s48),
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
