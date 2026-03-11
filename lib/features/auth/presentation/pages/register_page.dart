import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

/// Registration page.
///
/// Uses BlocBuilder (NOT BlocConsumer) — GoRouter's redirect in app_router.dart
/// watches AuthBloc state and handles all navigation automatically.
/// Manual Navigator calls conflict with GoRouter and cause crashes.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey           = GlobalKey<FormState>();
  final _nameController      = TextEditingController();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _phoneController     = TextEditingController();
  bool _isGoogleLoading    = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(RegisterRequested(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          ));
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final uri = Uri.parse(
        '${AppConstants.baseUrl}${AppConstants.googleAuthEndpoint}');
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
      backgroundColor: AppTheme.bgBase,
      // Custom back button on AppBar — clean with background transparency
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: PageBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isLoading    = state is AuthLoading;
              final errorMessage = state is AuthError ? state.message : null;

              return SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.s24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppTheme.s16),

                            // ── Wordmark ──────────────────────────────────
                            AnimatedEntrance(
                              delay: Duration.zero,
                              child: const AppWordmark(),
                            ),

                            const SizedBox(height: AppTheme.s32),

                            // ── Headline ──────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 80),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displaySmall,
                                  ),
                                  const SizedBox(height: AppTheme.s6),
                                  Text(
                                    'Set up your Sentinel account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTheme.s28),

                            // ── Form ──────────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 160),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    AppTextField(
                                      label: 'Full Name',
                                      controller: _nameController,
                                      prefixIcon:
                                          Icons.person_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Name is required';
                                        if (v.trim().length < 2)
                                          return 'Name is too short';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.s12),
                                    AppTextField(
                                      label: 'Email',
                                      controller: _emailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      prefixIcon:
                                          Icons.mail_outline_rounded,
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
                                      prefixIcon:
                                          Icons.lock_outline_rounded,
                                      textInputAction: TextInputAction.next,
                                      validator: (v) {
                                        if (v == null || v.isEmpty)
                                          return 'Password is required';
                                        if (v.length < 8)
                                          return 'Minimum 8 characters';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppTheme.s12),
                                    AppTextField(
                                      label: 'Phone Number',
                                      hint: 'Optional — add later',
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      prefixIcon:
                                          Icons.phone_outlined,
                                      textInputAction: TextInputAction.done,
                                      onSubmitted: (_) => _submit(),
                                    ),
                                  ],
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

                            // ── CTA ───────────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 240),
                              child: PrimaryButton(
                                label: 'Create Account',
                                onPressed: _submit,
                                isLoading: isLoading,
                                icon: Icons.arrow_forward_rounded,
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

                            // ── Sign in link ──────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 420),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Already have an account?  ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context),
                                      child: const Text('Sign in'),
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