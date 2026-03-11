import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

/// Presentation layer for the Login Feature.
///
/// Layout: Full-screen PageBackground with a CustomScrollView to ensure
/// safe rendering and auto-scrolling when the device keyboard is open.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
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
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      AppHaptics.medium();
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
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.googleAuthEndpoint}',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch';
      }
    } catch (_) {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,

          // BlocConsumer is utilized strictly to capture state changes for UI side-effects
          // (e.g., triggering haptic vibrations or form shake animations).
          // Actual page routing logic remains encapsulated within GoRouter's global listenable.
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthError) {
                AppHaptics.error();
                _shakeKey.currentState?.shake();
              } else if (state is AuthAuthenticated) {
                AppHaptics.success();
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              final errorMessage = state is AuthError ? state.message : null;

              return SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.s24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppTheme.s48),

                            // ── Wordmark ──────────────────────────────────
                            AnimatedEntrance(
                              delay: Duration.zero,
                              child: const AppWordmark(),
                            ),

                            const SizedBox(height: AppTheme.s48),

                            // ── Headline ──────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 80),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                  const SizedBox(height: AppTheme.s6),
                                  Text(
                                    'Sign in to monitor your cameras',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTheme.s32),

                            // ── Form ──────────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 160),
                              child: ShakeWidget(
                                key: _shakeKey,
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      AppTextField(
                                        label: 'Email',
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        prefixIcon: Icons.mail_outline_rounded,
                                        textInputAction: TextInputAction.next,
                                        autofocus: true,
                                        validator: (v) {
                                          if (v == null || v.isEmpty)
                                            return 'Email is required';
                                          if (!v.contains('@'))
                                            return 'Enter a valid email';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppTheme.s12),
                                      AppTextField(
                                        label: 'Password',
                                        controller: _passwordController,
                                        obscureText: true,
                                        prefixIcon: Icons.lock_outline_rounded,
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
                            ),

                            // ── Forgot Password ───────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 200),
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    AppHaptics.selection();
                                    FocusScope.of(context).unfocus();
                                    context.push(
                                      AppConstants.forgotPasswordRoute,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppTheme.s12,
                                    ),
                                  ),
                                  child: Text(
                                    'Forgot Password?',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(color: AppTheme.amber),
                                  ),
                                ),
                              ),
                            ),

                            // ── Error ─────────────────────────────────────
                            if (errorMessage != null) ...[
                              const SizedBox(height: AppTheme.s16),
                              AnimatedEntrance(
                                delay: Duration.zero,
                                child: ErrorBanner(message: errorMessage),
                              ),
                            ],

                            const SizedBox(height: AppTheme.s28),

                            // ── Primary CTA ───────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 240),
                              child: PrimaryButton(
                                label: 'Sign In',
                                onPressed: _submit,
                                isLoading: isLoading,
                              ),
                            ),

                            const SizedBox(height: AppTheme.s24),

                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 300),
                              child: const LabeledDivider(label: 'or'),
                            ),

                            const SizedBox(height: AppTheme.s24),

                            // ── Google ────────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 360),
                              child: GoogleSignInButton(
                                onPressed: _signInWithGoogle,
                                isLoading: _isGoogleLoading,
                              ),
                            ),

                            const Spacer(),
                            const SizedBox(height: AppTheme.s24),

                            // ── Register link ─────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 420),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Don't have an account?  ",
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        AppHaptics.selection();
                                        context.push(
                                          AppConstants.registerRoute,
                                        );
                                      },
                                      child: const Text('Create account'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppTheme.s24),
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
      ),
    );
  }
}
