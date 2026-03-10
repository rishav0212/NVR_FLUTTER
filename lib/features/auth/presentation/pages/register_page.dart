import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart'; // <--- Added for Google Auth
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/constants/app_constants.dart';

/// Registration page.
///
/// Phone number is optional here — the user is taken to CompleteProfilePage
/// after registration if they skip it. This reduces sign-up friction while
/// still collecting the data we need before they can use the app fully.
/// 
/// Updates: Implemented CustomScrollView with SliverFillRemaining to guarantee
/// the UI never overflows when the keyboard appears. Added cascading fade/slide
/// animations for a premium, smooth entrance feel. Fixed Google sign-in launching.
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
    // Dismiss keyboard on submit for a cleaner loading state UX
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
    final Uri url = Uri.parse('${AppConstants.baseUrl}${AppConstants.googleAuthEndpoint}');
    
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // GestureDetector at the root level catches taps outside text fields
      // and dismisses the keyboard, providing a polished native feel.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthAuthenticated) {
              // Registration succeeded — go to home, clear entire nav stack
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppConstants.homeRoute, (route) => false);
            } else if (state is AuthProfileIncomplete) {
              // Registered but skipped phone number — go to complete profile
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppConstants.completeProfileRoute,
                (route) => false,
              );
            }
          },
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
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.sm),
                          
                          // ── Wordmark with Animation ────────────────────────
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 100),
                            child: const AppWordmark(),
                          ),
                          const SizedBox(height: AppTheme.xl),

                          // ── Headers with Animation ─────────────────────────
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Create account',
                                  style: Theme.of(context).textTheme.headlineLarge,
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

                          // ── Form with Animation ────────────────────────────
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
                                      if (v.length < 2) return 'Name is too short';
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
                                      if (!v.contains('@')) return 'Enter a valid email';
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

                                  // ── Phone (optional) ──────────────────────────────
                                  AppTextField(
                                    label: 'Phone Number (optional)',
                                    controller: _phoneController,
                                    keyboardType: TextInputType.phone,
                                    prefixIcon: Icons.phone_outlined,
                                    textInputAction: TextInputAction.done,
                                    onSubmitted: (_) => _submit(),
                                  ),

                                  // ── Phone skip hint ───────────────────────────────
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      top: AppTheme.xs,
                                      left: AppTheme.xs,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'You can add this later',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Error Banner ───────────────────────────────────
                          if (errorMessage != null) ...[
                            const SizedBox(height: AppTheme.md),
                            AnimatedEntrance(
                              delay: Duration.zero,
                              child: ErrorBanner(message: errorMessage),
                            ),
                          ],

                          const SizedBox(height: AppTheme.xl),

                          // ── Primary action ──────────────────────────────────
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

                          // ── Google ──────────────────────────────────────────
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 600),
                            child: GoogleSignInButton(
                              onPressed: _signInWithGoogle,
                              isLoading: _isGoogleLoading,
                            ),
                          ),

                          // Spacer pushes the bottom section down, allowing the 
                          // form to stay centered above it.
                          const Spacer(),
                          const SizedBox(height: AppTheme.xl),

                          // ── Login link ──────────────────────────────────────
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
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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