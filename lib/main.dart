import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';
import 'shared/widgets/gradient_text.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Environment variables must load first to provide API base URLs
  // before the dependency injection container attempts to instantiate the ApiClient.
  await dotenv.load(fileName: ".env");
  await initDi();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure system UI bars to be transparent, allowing the app's dynamic
  // mesh backgrounds to extend fully to the device edges seamlessly.
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

  /// Global theme mode notifier.
  /// Allows the entire application to reactively toggle between light/dark
  /// modes without requiring a full bloc/provider state rebuild for a single property.
  static final themeMode = ValueNotifier<ThemeMode>(ThemeMode.system);

  @override
  State<NvrApp> createState() => _NvrAppState();
}

class _NvrAppState extends State<NvrApp> {
  // AppRouter depends on AuthBloc. Instantiating them here ensures GoRouter's
  // refreshListenable and the BlocProvider share the exact same instance across rebuilds.
  late final AuthBloc _authBloc;
  late final AppRouter _appRouter;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(AppStarted());
    _appRouter = AppRouter(_authBloc);
    _initDeepLinks();
  }

  /// Initializes deep linking to intercept OAuth callbacks from external browsers.
  /// When a user completes Google Sign-In, the system routes the redirect URI back here.
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
    _linkSubscription?.cancel();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: _authBloc,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: NvrApp.themeMode,
        builder: (context, mode, child) {
          return MaterialApp.router(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,

            themeMode: mode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,

            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
//
// Initial landing view displayed while AuthBloc resolves the secure storage session.
// Uses explicit animation controllers to handle graceful scaling/fades before GoRouter
// initiates its first navigation redirect.
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
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(decoration: BoxDecoration(gradient: ext.bgGradient)),

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
                  const SizedBox(height: AppTheme.s24),

                  GradientText(
                    AppConstants.appName,
                    style: Theme.of(
                      context,
                    ).textTheme.displayMedium?.copyWith(letterSpacing: -0.5),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF0F0FA), Color(0xFF6060A0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),

                  const SizedBox(height: AppTheme.s48),
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: colorScheme.primary.withOpacity(0.8),
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
