import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/accent_header.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../main.dart';
import '../bloc/auth_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// ═════════════════════════════════════════════════════════════════════════════
// COMPLETE PROFILE PAGE
// ═════════════════════════════════════════════════════════════════════════════
// Presented immediately post-registration if the user OAuth payload did not
// include a required phone number.
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

// ═════════════════════════════════════════════════════════════════════════════
// HOME PAGE
// ═════════════════════════════════════════════════════════════════════════════
// Stateful component necessary for managing hardware device APIs (Wakelock).
// Ensures the screen does not auto-dim while monitoring live camera feeds.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Wakelock must be bound to the lifecycle logic, preventing memory leaks
    // or unexpected battery drain when routing to background layers.
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AuthBloc>().state;
    final user = state is AuthAuthenticated ? state.user : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: PageBackground(
        child: SafeArea(
          child: Column(
            children: [
              _HomeTopBar(userName: user?.name),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.s24,
                    vertical: AppTheme.s16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 80),
                        child: const _StatusRow(),
                      ),
                      const SizedBox(height: AppTheme.s32),
                      AnimatedEntrance(
                        delay: const Duration(milliseconds: 160),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const AccentHeader(text: 'Cameras'),
                            TextButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTheme.s16),
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
                  child: Icon(
                    Icons.videocam_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
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
          AnimatedEntrance(
            delay: const Duration(milliseconds: 80),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    AppHaptics.selection();
                    // Modifying the static ValueNotifier triggers a global UI repaint
                    // at the top-level MaterialApp, instantly swapping theme extensions.
                    NvrApp.themeMode.value =
                        Theme.of(context).brightness == Brightness.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                  },
                ),
                _AvatarButton(initials: _initials(userName)),
                const SizedBox(width: AppTheme.s4),
                IconButton(
                  icon: Icon(
                    Icons.logout_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    AppHaptics.medium();
                    context.read<AuthBloc>().add(LogoutRequested());
                  },
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
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        gradient: ext.amberTint,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.amber.withOpacity(0.2)),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow();

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s16,
        vertical: AppTheme.s12,
      ),
      decoration: AppTheme.glassCard(context, radius: AppTheme.rMd),
      child: Row(
        children: [
          PulsingDot(color: ext.success),
          const SizedBox(width: AppTheme.s10),
          Text(
            'System online',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: ext.success),
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

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE CARD
// ─────────────────────────────────────────────────────────────────────────────
//
// Displayed when the user has zero registered NVR instances.
// Includes an infinite, ambient breathing animation on the icon container
// to maintain a feeling of system activity even when data is empty.
class _EmptyStateCard extends StatefulWidget {
  const _EmptyStateCard();
  @override
  State<_EmptyStateCard> createState() => _EmptyStateCardState();
}

class _EmptyStateCardState extends State<_EmptyStateCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _breathe, curve: Curves.easeInOutSine));
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.all(AppTheme.s40),
      decoration: AppTheme.glassCard(context),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: _scale,
            builder: (_, child) =>
                Transform.scale(scale: _scale.value, child: child),
            child: Container(
              width: 64,
              height: 64,
              decoration: AppTheme.amberIconBox(context, radius: AppTheme.rLg),
              child: const Icon(
                Icons.videocam_off_outlined,
                color: AppTheme.amber,
                size: 28,
              ),
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.s16,
              vertical: AppTheme.s8,
            ),
            decoration: BoxDecoration(
              gradient: ext.amberTint,
              borderRadius: BorderRadius.circular(AppTheme.rFull),
              border: Border.all(color: AppTheme.amber.withOpacity(0.2)),
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
