import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'injection_container.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDi();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.bgBase,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

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

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(AppStarted());
    _appRouter = AppRouter(_authBloc);
  }

  @override
  void dispose() {
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
        theme: AppTheme.darkTheme,
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
    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: Stack(
        children: [
          // Mesh background blobs
          Positioned(
            top: -150,
            left: -150,
            width: 500,
            height: 500,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.meshAmber,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            width: 400,
            height: 400,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppTheme.meshIndigo,
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
                          color: AppTheme.amberGlow20,
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: AppTheme.textOnAmber,
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
                      color: AppTheme.amber.withOpacity(0.6),
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
