import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Shown after first login when profileComplete == false.
///
/// This screen exists to reduce registration friction — users can skip
/// the phone number at sign-up and provide it here before accessing the app.
/// The phone number is required before accessing the home screen because
/// it's used for account recovery and installer contact.
///
/// Updates: Implemented CustomScrollView with SliverFillRemaining to guarantee
/// the UI never overflows when the keyboard appears. Added cascading fade/slide
/// animations for a premium, smooth entrance feel.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill name from existing profile if available
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
    // Dismiss keyboard on submit for a cleaner loading state UX
    FocusScope.of(context).unfocus();

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
        CompleteProfileRequested(
          phoneNumber: _phoneController.text.trim(),
          name: _nameController.text.trim().isEmpty
              ? null
              : _nameController.text.trim(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // GestureDetector at the root level catches taps outside text fields
      // and dismisses the keyboard, providing a polished native feel.
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final errorMessage = state is AuthError ? state.message : null;

            return SafeArea(
              // CustomScrollView replaces the Expanded+Column setup.
              // This is the optimal way to handle forms in Flutter. It allows content
              // to be centered vertically on large screens, but become scrollable
              // automatically when the keyboard intrudes.
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(AppTheme.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: AppTheme.xl),

                          // ── Header ─────────────────────────────────────────────
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
                                Icons.person_outline,
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
                                  'Complete your profile',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: AppTheme.xs),
                                Text(
                                  'Just one more step before you can access your cameras.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppTheme.xl),

                          // ── Form ──────────────────────────────────────────────
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
                                  ),
                                  const SizedBox(height: AppTheme.md),
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
                                      if (v.length < 7)
                                        return 'Enter a valid phone number';
                                      return null;
                                    },
                                  ),

                                  if (errorMessage != null) ...[
                                    const SizedBox(height: AppTheme.md),
                                    ErrorBanner(message: errorMessage),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Spacer pushes the button down to the bottom
                          const Spacer(),
                          const SizedBox(height: AppTheme.xl),

                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 400),
                            child: PrimaryButton(
                              label: 'Continue',
                              onPressed: _submit,
                              isLoading: isLoading,
                              icon: Icons.arrow_forward,
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

/// Home placeholder — camera grid will be built in Phase 2.
/// Updated to dynamically adapt to Light/Dark mode and utilize smooth entrances.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    WakelockPlus.enable();
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticated ? state.user : null;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.videocam_outlined,
              color: AppTheme.amber,
              size: 20,
            ),
            const SizedBox(width: AppTheme.sm),
            Text('Sentinel', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 20),
            onPressed: () => context.read<AuthBloc>().add(LogoutRequested()),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: Center(
        child: AnimatedEntrance(
          delay: const Duration(milliseconds: 100),
          child: Container(
            margin: const EdgeInsets.all(AppTheme.lg),
            padding: const EdgeInsets.all(AppTheme.xl),
            decoration: BoxDecoration(
              // Using colorScheme ensures it swaps to white in light mode
              // and dark elevated in dark mode automatically.
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppTheme.radiusXl),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: Column(
              mainAxisSize: MainAxisSize
                  .min, // Replaced hardcoded centering for better scaling
              children: [
                Icon(
                  Icons.videocam_off_outlined,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  size: 48,
                ),
                const SizedBox(height: AppTheme.md),
                Text(
                  'Welcome, ${user?.name ?? 'User'}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppTheme.sm),
                Text(
                  'Camera feed coming in Phase 2',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
