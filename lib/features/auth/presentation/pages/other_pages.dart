import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../bloc/auth_bloc.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COMPLETE PROFILE PAGE
// ═════════════════════════════════════════════════════════════════════════════
//
// Shown after first login when profile_complete == false.
// Collects the phone number (required before full app access).
// Pre-fills name from existing auth state.
//
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
      backgroundColor: AppTheme.bgBase,
      body: PageBackground(
        child: BlocBuilder<AuthBloc, AuthState>(
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

                    // ── Icon header ────────────────────────────────────────
                    AnimatedEntrance(
                      delay: Duration.zero,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: AppTheme.amberIconBox(),
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

                    // ── Form ───────────────────────────────────────────────
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 160),
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
                                if (v.replaceAll(RegExp(r'\D'), '').length < 7)
                                  return 'Enter a valid phone number';
                                return null;
                              },
                            ),
                          ],
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

                    // ── CTA ────────────────────────────────────────────────
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

// ═════════════════════════════════════════════════════════════════════════════
// HOME PAGE
// ═════════════════════════════════════════════════════════════════════════════
//
// Phase 1 placeholder — camera grid arrives in Phase 2.
// Designed to not look like a placeholder — it looks intentional.
//
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticated ? state.user : null;

    return Scaffold(
      backgroundColor: AppTheme.bgBase,
      body: PageBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              _HomeTopBar(userName: user?.name),

              // ── Body ─────────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.s24,
                    vertical: AppTheme.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status bar
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: const _StatusRow(),
                      ),

                      const SizedBox(height: AppTheme.s32),

                      // Section header
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Cameras',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            TextButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppTheme.s16),

                      // Empty state card
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 240),
                        child: const _EmptyStateCard(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Home sub-widgets ──────────────────────────────────────────────────────────

class _HomeTopBar extends StatelessWidget {
  final String? userName;

  const _HomeTopBar({this.userName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.s24,
        AppTheme.s16,
        AppTheme.s16,
        AppTheme.s8,
      ),
      child: Row(
        children: [
          // Wordmark compact
          AnimatedEntrance(
            delay: Duration.zero,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppTheme.amberBtn,
                    borderRadius: BorderRadius.circular(AppTheme.rSm),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    color: AppTheme.textOnAmber,
                    size: 16,
                  ),
                ),
                const SizedBox(width: AppTheme.s8),
                Text(
                  'Sentinel',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Profile avatar / logout
          AnimatedEntrance(
            delay: const Duration(milliseconds: 80),
            child: Row(
              children: [
                _AvatarButton(initials: _initials(userName)),
                const SizedBox(width: AppTheme.s4),
                IconButton(
                  icon: const Icon(
                    Icons.logout_outlined,
                    size: 18,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () =>
                      context.read<AuthBloc>().add(LogoutRequested()),
                  tooltip: 'Sign out',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}

class _AvatarButton extends StatelessWidget {
  final String initials;

  const _AvatarButton({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: AppTheme.amberTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.borderAmber),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.amber,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s16,
        vertical: AppTheme.s12,
      ),
      decoration: AppTheme.glassCard(radius: AppTheme.rMd),
      child: Row(
        children: [
          const PulsingDot(color: AppTheme.success),
          const SizedBox(width: AppTheme.s10),
          Text(
            'System online',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppTheme.success),
          ),
          const Spacer(),
          Text(
            '0 cameras connected',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.s40),
      decoration: AppTheme.glassCard(),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: AppTheme.amberIconBox(radius: AppTheme.rLg),
            child: const Icon(
              Icons.videocam_off_outlined,
              color: AppTheme.amber,
              size: 28,
            ),
          ),
          const SizedBox(height: AppTheme.s20),
          Text(
            'No cameras yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.s8),
          Text(
            'Camera provisioning and live feed\ncoming in Phase 2.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppTheme.s28),
          // Teaser badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.s16,
              vertical: AppTheme.s8,
            ),
            decoration: BoxDecoration(
              gradient: AppTheme.amberTint,
              borderRadius: BorderRadius.circular(AppTheme.rFull),
              border: Border.all(color: AppTheme.borderAmber),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.construction_rounded,
                  size: 13,
                  color: AppTheme.amber,
                ),
                const SizedBox(width: AppTheme.s6),
                Text(
                  'In development',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.amber,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
