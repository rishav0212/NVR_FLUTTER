import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- Added for Google Auth
import 'package:go_router/go_router.dart'; // <--- Added for GoRouter
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

/// Login page.
///
/// Design intent: The Sentinel wordmark anchors the screen with authority.
/// The form is compact and centered — no wasted space. The amber accent
/// on the logo and primary button creates a clear visual hierarchy that
/// guides the eye from brand → form → action.
///
/// Two auth paths are available:
/// 1. Email + password → dispatches LoginRequested
/// 2. Google → opens browser to /api/auth/oauth2/authorize/google,
///    which redirects back via the nvr:// deep link scheme.
///
/// Updates: Implemented CustomScrollView with SliverFillRemaining to guarantee
/// the UI never overflows when the keyboard appears. Added cascading fade/slide
/// animations for a premium, smooth entrance feel. Fixed Google sign-in launching.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    // Dismiss keyboard on submit for a cleaner loading state UX
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        LoginRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    // Opens the server's OAuth2 authorize URL in the system browser.
    // After Google consent, the server redirects to nvr://auth/callback?accessToken=...
    // The app_links package catches this and the router navigates accordingly.
    final Uri url = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.googleAuthEndpoint}',
    );

    // Smoothly opens the system browser to handle Google Auth
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch browser';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open Google Sign-In')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // GestureDetector at the root level catches taps outside text fields
      // and dismisses the keyboard, providing a polished native feel.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),

        // CHANGED: We now use BlocBuilder instead of BlocConsumer.
        // GoRouter handles all navigation redirects automatically in app_router.dart!
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final errorMessage = state is AuthError ? state.message : null;

            return SafeArea(
              // CustomScrollView replaces SingleChildScrollView + fixed SizedBox height.
              // This is the optimal way to handle forms in Flutter. It allows content
              // to be centered vertically on large screens, but become scrollable
              // automatically when the keyboard intrudes.
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Top spacer + wordmark ──────────────────────────────
                          const Spacer(flex: 2),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 100),
                            child: _Wordmark(),
                          ),
                          const SizedBox(height: AppTheme.xxl),

                          // ── Form ──────────────────────────────────────────────
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: AppTheme.xs),
                                Text(
                                  'Sign in to your account',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.xl),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 300),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  AppTextField(
                                    label: 'Email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.mail_outline,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Email is required';
                                      if (!v.contains('@'))
                                        return 'Enter a valid email';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.md),
                                  AppTextField(
                                    label: 'Password',
                                    controller: _passwordController,
                                    obscureText: true,
                                    prefixIcon: Icons.lock_outline,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submit(),
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Password is required';
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Forgot Password ─────────────────────────────────
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 400),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  context.push(
                                    AppConstants.forgotPasswordRoute,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppTheme.sm,
                                  ),
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(color: AppTheme.amber),
                                ),
                              ),
                            ),
                          ),

                          // ── Error ─────────────────────────────────────────────
                          if (errorMessage != null) ...[
                            AnimatedEntrance(
                              delay: Duration.zero,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppTheme.md,
                                ),
                                child: ErrorBanner(message: errorMessage),
                              ),
                            ),
                          ],

                          const SizedBox(height: AppTheme.sm),

                          // ── Primary action ────────────────────────────────────
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 500),
                            child: PrimaryButton(
                              label: 'Sign In',
                              onPressed: _submit,
                              isLoading: isLoading,
                            ),
                          ),

                          const SizedBox(height: AppTheme.lg),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 600),
                            child: const LabeledDivider(label: 'or'),
                          ),
                          const SizedBox(height: AppTheme.lg),

                          // ── Google ────────────────────────────────────────────
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 700),
                            child: GoogleSignInButton(
                              onPressed: _signInWithGoogle,
                              isLoading: _isGoogleLoading,
                            ),
                          ),

                          // ── Register link ─────────────────────────────────────
                          const Spacer(flex: 3),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 800),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: () =>
                                      context.push(AppConstants.registerRoute),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Create account'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.xl),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The app wordmark — used on auth screens.
class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.amberGlow,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.amberDim, width: 1),
          ),
          child: const Icon(
            Icons.videocam_outlined,
            color: AppTheme.amber,
            size: 22,
          ),
        ),
        const SizedBox(width: AppTheme.sm),
        Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 3),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: const BoxDecoration(
            color: AppTheme.amber,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
