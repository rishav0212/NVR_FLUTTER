import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
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
      backgroundColor: AppTheme.bgBase,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
      ),
      body: PageBackground(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthActionSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppTheme.success,
                  ),
                );
                context.pop();
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

                            // ── Icon ────────────────────────────────────
                            AnimatedEntrance(
                              delay: Duration.zero,
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: AppTheme.amberIconBox(),
                                child: const Icon(
                                  Icons.lock_reset_rounded,
                                  color: AppTheme.amber,
                                  size: 24,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppTheme.s24),

                            // ── Headline ─────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 80),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Reset password',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displaySmall,
                                  ),
                                  const SizedBox(height: AppTheme.s6),
                                  Text(
                                    "Enter your email and we'll send you\ninstructions to reset your password.",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppTheme.s32),

                            // ── Form ─────────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 160),
                              child: Form(
                                key: _formKey,
                                child: AppTextField(
                                  label: 'Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.mail_outline_rounded,
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

                            // ── Error ────────────────────────────────────
                            if (errorMessage != null) ...[
                              const SizedBox(height: AppTheme.s16),
                              AnimatedEntrance(
                                delay: Duration.zero,
                                child: ErrorBanner(message: errorMessage),
                              ),
                            ],

                            const Spacer(),

                            // ── CTA ──────────────────────────────────────
                            AnimatedEntrance(
                              delay: const Duration(milliseconds: 240),
                              child: PrimaryButton(
                                label: 'Send Reset Link',
                                onPressed: _submit,
                                isLoading: isLoading,
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
