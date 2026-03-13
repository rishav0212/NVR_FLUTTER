import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COMPLETE PROFILE PAGE
// ═════════════════════════════════════════════════════════════════════════════
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the name if it was captured from Google OAuth
    final state = context.read<AuthBloc>().state;
    if (state is AuthProfileIncomplete) {
      _nameController.text = state.user.name;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState?.validate() ?? false) {
      AppHaptics.medium();
      context.read<AuthBloc>().add(
        CompleteProfileRequested(
          phoneNumber: _phoneController.text.trim(),
          name: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        ),
      );
    } else {
      _shakeKey.currentState?.shake();
      AppHaptics.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageBackground(
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppTheme.s48),
                    AnimatedEntrance(
                      delay: Duration.zero,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: AppTheme.amberIconBox(context),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          color: AppTheme.amber,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.s24),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'One more step',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: AppTheme.s6),
                          Text(
                            'Add your phone number to complete your profile.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.s32),
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
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: AppTheme.s12),
                              AppTextField(
                                label: 'Phone Number',
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_outlined,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submit(),
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'Phone number is required';
                                  if (v.replaceAll(RegExp(r'\D'), '').length <
                                      7)
                                    return 'Enter a valid phone number';
                                  return null;
                                },
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
                    const Spacer(),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 240),
                      child: PrimaryButton(
                        label: 'Continue',
                        onPressed: _submit,
                        isLoading: isLoading,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ),
                    const SizedBox(height: AppTheme.s32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
