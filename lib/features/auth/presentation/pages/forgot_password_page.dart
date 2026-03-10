import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        ForgotPasswordRequested(_emailController.text.trim()),
      );
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
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            // NEW: Listen for the specific success action, show notification, and pop safely.
            if (state is AuthActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor:
                      AppTheme.onlineGreen, // Use the success color
                ),
              );
              Navigator.pop(context);
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
                        horizontal: AppTheme.lg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.xl),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 100),
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppTheme.amberGlow,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMd,
                                ),
                                border: Border.all(color: AppTheme.amberDim),
                              ),
                              child: const Icon(
                                Icons.lock_reset_outlined,
                                color: AppTheme.amber,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.lg),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 200),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset Password',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: AppTheme.xs),
                                Text(
                                  "Enter your email and we'll send you instructions to reset your password.",
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
                              child: AppTextField(
                                label: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icons.mail_outline,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Email is required';
                                  if (!v.contains('@'))
                                    return 'Enter a valid email';
                                  return null;
                                },
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

                          const Spacer(),
                          const SizedBox(height: AppTheme.xl),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 400),
                            child: PrimaryButton(
                              label: 'Send Reset Link',
                              onPressed: _submit,
                              isLoading: isLoading,
                            ),
                          ),
                          const SizedBox(height: AppTheme.md),
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
