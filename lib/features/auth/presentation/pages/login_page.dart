import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

/// Login page.
///
/// Layout: Full-screen PageBackground with mesh gradients.
/// Content scrolls inside a CustomScrollView to handle keyboard safely.
/// All navigation handled by the router — no Navigator calls here.
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
      // We dynamically pull the scaffold background color from the active theme
      // rather than hardcoding AppTheme.bgBase, ensuring seamless Light/Dark mode transitions.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: BlocBuilder<AuthBloc, AuthState>(
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
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    AppTextField(
                                      label: 'Email',
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      prefixIcon: Icons.mail_outline_rounded,
                                      textInputAction: TextInputAction.next,
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

                            // ── Forgot Password ───────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 200),
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
                                      onPressed: () => context.push(
                                        AppConstants.registerRoute,
                                      ),
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
