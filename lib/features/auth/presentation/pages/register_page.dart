import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/constants/app_constants.dart';

/// Registration page.
///
/// Navigation is fully handled by GoRouter watching AuthBloc state in
/// app_router.dart — no manual Navigator calls needed here at all.
/// BlocBuilder (not BlocConsumer) — GoRouter's redirect handles routing.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isGoogleLoading = false;

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
      context.read<AuthBloc>().add(
        RegisterRequested(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phoneNumber: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final Uri url = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.googleAuthEndpoint}',
    );
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),

        // ✅ BlocBuilder — NOT BlocConsumer.
        // GoRouter in app_router.dart listens to AuthBloc state changes via
        // _GoRouterRefreshStream and calls redirect() automatically.
        // When state becomes AuthAuthenticated → redirect sends to /home.
        // When state becomes AuthProfileIncomplete → redirect sends to /complete-profile.
        // Manual Navigator calls here would conflict with GoRouter and cause crashes.
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
                        horizontal: AppTheme.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.sm),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 100),
                            child: const AppWordmark(),
                          ),
                          const SizedBox(height: AppTheme.xl),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create account',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: AppTheme.xs),
                                Text(
                                  'Set up your Sentinel account',
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
                                    label: 'Full Name',
                                    controller: _nameController,
                                    prefixIcon: Icons.person_outline,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Name is required';
                                      if (v.length < 2)
                                        return 'Name is too short';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.md),
                                  AppTextField(
                                    label: 'Email',
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.mail_outline,
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
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return 'Password is required';
                                      if (v.length < 8)
                                        return 'Password must be at least 8 characters';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: AppTheme.md),
                                  AppTextField(
                                    label: 'Phone Number (optional)',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_outlined,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submit(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppTheme.xs,
                                      left: AppTheme.xs,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'You can add this later',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (errorMessage != null) ...[
                            const SizedBox(height: AppTheme.md),
                            AnimatedEntrance(
                              delay: Duration.zero,
                              child: ErrorBanner(message: errorMessage),
                            ),
                          ],

                          const SizedBox(height: AppTheme.xl),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 400),
                            child: PrimaryButton(
                              label: 'Create Account',
                              onPressed: _submit,
                              isLoading: isLoading,
                              icon: Icons.arrow_forward,
                            ),
                          ),

                          const SizedBox(height: AppTheme.lg),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 500),
                            child: const LabeledDivider(label: 'or'),
                          ),
                          const SizedBox(height: AppTheme.lg),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 600),
                            child: GoogleSignInButton(
                              onPressed: _signInWithGoogle,
                              isLoading: _isGoogleLoading,
                            ),
                          ),

                          const Spacer(),
                          const SizedBox(height: AppTheme.xl),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 700),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Sign in'),
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
