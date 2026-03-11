import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

/// Presentation layer for new account creation.
/// 
/// Includes form validation, password strength feedback, and Google Sign-In integration.
/// Listens to AuthBloc for success/error states, providing haptic feedback and error shaking on failure.
/// Designed with accessibility and responsive layout in mind, ensuring a smooth registration experience across devices.
/// Note: The actual registration logic is handled by AuthBloc; this page focuses on user input and feedback.
/// 
/// RegisterPage allows users to create a new Sentinel account using email/password or Google Sign-In.
/// 
///   • BlocConsumer — listener fires haptics + shake on error
///   • ShakeWidget wraps the form
///   • autofocus: true on name field
///   • Password strength bar below password field
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isGoogleLoading = false;

  @override
  void initState() {
    super.initState();
    // Binds a listener to trigger localized state rebuilds when the password
    // input mutates, allowing the entropy/strength bar to evaluate dynamically.
    _passwordController.addListener(() => setState(() {}));
  }

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
      AppHaptics.medium();
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
    final uri = Uri.parse(
      '${AppConstants.baseUrl}${AppConstants.googleAuthEndpoint}',
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication))
        throw 'Could not launch';
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to open Google Sign-In')),
        );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            AppHaptics.light();
            context.pop();
          },
        ),
      ),
      body: PageBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
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
                            const SizedBox(height: AppTheme.s16),
                            AnimatedEntrance(
                              delay: Duration.zero,
                              child: const AppWordmark(),
                            ),
                            const SizedBox(height: AppTheme.s32),
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 80),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Create account',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                  const SizedBox(height: AppTheme.s6),
                                  Text(
                                    'Set up your Sentinel account',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppTheme.s28),

                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 160),
                              child: ShakeWidget(
                                key: _shakeKey,
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
                                        autofocus: true,
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
                                        textInputAction: TextInputAction.next,
                                        validator: (v) {
                                          if (v == null || v.isEmpty)
                                            return 'Password is required';
                                          if (v.length < 8)
                                            return 'Minimum 8 characters';
                                          return null;
                                        },
                                      ),

                                      if (_passwordController.text.isNotEmpty)
                                        _PasswordStrengthBar(
                                          password: _passwordController.text,
                                        ),

                                      const SizedBox(height: AppTheme.s12),
                                      AppTextField(
                                        label: 'Phone Number',
                                        hint: 'Optional — add later',
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        prefixIcon: Icons.phone_outlined,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _submit(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            if (errorMessage != null) ...[
                              const SizedBox(height: AppTheme.s16),
                              AnimatedEntrance(
                                delay: Duration.zero,
                                child: ErrorBanner(message: errorMessage),
                              ),
                            ],

                            const SizedBox(height: AppTheme.s28),
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
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 360),
                              child: GoogleSignInButton(
                                onPressed: _signInWithGoogle,
                                isLoading: _isGoogleLoading,
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: AppTheme.s24),
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 420),
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Already have an account?  ',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        AppHaptics.selection();
                                        context.pop();
                                      },
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

// ─────────────────────────────────────────────────────────────────────────────
// PASSWORD STRENGTH COMPONENT
// ─────────────────────────────────────────────────────────────────────────────
//
// Evaluates string entropy based on length, alphanumeric variance, and symbol
// inclusion, providing real-time color-coded visual feedback to the user.
class _PasswordStrengthBar extends StatelessWidget {
  final String password;

  const _PasswordStrengthBar({required this.password});

  int get strength {
    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }

  Color _color(BuildContext context) {
    return switch (strength) {
      1 => AppTheme.error,
      2 => Theme.of(context).extension<AppColorsExtension>()!.warning,
      3 => AppTheme.amberLight,
      4 => Theme.of(context).extension<AppColorsExtension>()!.success,
      _ => Colors.transparent,
    };
  }

  String get _label {
    return switch (strength) {
      1 => 'Weak',
      2 => 'Fair',
      3 => 'Good',
      4 => 'Strong',
      _ => '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: List.generate(4, (i) {
              final filled = i < strength;
              return Expanded(
                child: AnimatedContainer(
                  duration: AppTheme.tMid,
                  curve: AppTheme.curveSmooth,
                  height: 3,
                  margin: EdgeInsets.only(right: i < 3 ? AppTheme.s4 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: filled ? color : ext.borderSubtle,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: AppTheme.s4),
          AnimatedSwitcher(
            duration: AppTheme.tFast,
            child: Text(
              _label,
              key: ValueKey(strength),
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color, fontSize: 10.5),
            ),
          ),
        ],
      ),
    );
  }
}
