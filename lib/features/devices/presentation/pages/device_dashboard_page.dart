import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/accent_header.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../injection_container.dart';
import '../../../../main.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart'; // Correct relative path
import '../bloc/device_bloc.dart'; // Correct relative path
import '../widgets/device_card.dart'; // Correct relative path

// ═════════════════════════════════════════════════════════════════════════════
// DEVICE DASHBOARD PAGE
// ═════════════════════════════════════════════════════════════════════════════
class DeviceDashboardPage extends StatefulWidget {
  const DeviceDashboardPage({super.key});

  @override
  State<DeviceDashboardPage> createState() => _DeviceDashboardPageState();
}

class _DeviceDashboardPageState extends State<DeviceDashboardPage> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable(); // Keep screen on during active monitoring
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch AuthBloc to get the user's name for the top bar avatar
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return BlocProvider(
      // Factory registration gives a fresh instance specifically for the dashboard list.
      create: (_) => getIt<DeviceBloc>()..add(LoadMyDevices()),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        floatingActionButton: const _AddDeviceFab(),
        body: PageBackground(
          child: SafeArea(
            child: Column(
              children: [
                _HomeTopBar(userName: user?.name),
                const Expanded(child: _DeviceBody()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAB — Add Device
// ─────────────────────────────────────────────────────────────────────────────
class _AddDeviceFab extends StatelessWidget {
  const _AddDeviceFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppTheme.amber,
      foregroundColor: Theme.of(context).colorScheme.onPrimary,
      onPressed: () async {
        AppHaptics.light();
        await context.push(AppConstants.addDeviceRoute);
        if (context.mounted) {
          context.read<DeviceBloc>().add(RefreshDevices());
        }
      },
      child: const Icon(Icons.add_rounded, size: 26),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DEVICE BODY
// ─────────────────────────────────────────────────────────────────────────────
class _DeviceBody extends StatelessWidget {
  const _DeviceBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        if (state is DeviceInitial || state is DeviceOperationLoading) {
          return const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.amber,
            ),
          );
        }

        if (state is DeviceError) {
          return Padding(
            padding: const EdgeInsets.all(AppTheme.s24),
            child: Center(child: ErrorBanner(message: state.message)),
          );
        }

        if (state is DevicesLoaded) {
          return RefreshIndicator(
            color: AppTheme.amber,
            backgroundColor: Theme.of(context).colorScheme.surface,
            onRefresh: () async {
              context.read<DeviceBloc>().add(RefreshDevices());
              await Future.delayed(const Duration(milliseconds: 500));
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.s24,
                      AppTheme.s16,
                      AppTheme.s24,
                      AppTheme.s8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 80),
                          child: _StatusRow(deviceCount: state.devices.length),
                        ),
                        const SizedBox(height: AppTheme.s28),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 160),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AccentHeader(title: 'My Devices'),
                              if (state.devices.isNotEmpty) ...[
                                const SizedBox(height: AppTheme.s6),
                                Text(
                                  '${state.devices.length} device${state.devices.length != 1 ? 's' : ''} registered',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (state.devices.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.s24),
                      child: _EmptyStateCard(), // <--- Restored!
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.s24,
                      AppTheme.s16,
                      AppTheme.s24,
                      100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => AnimatedEntrance(
                          delay: Duration(milliseconds: 80 + (index * 60)),
                          child: DeviceCard(
                            device: state.devices[index],
                            onTap: () => context.push(
                              '/devices/${state.devices[index].id}',
                            ),
                          ),
                        ),
                        childCount: state.devices.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HOME TOP BAR
// ─────────────────────────────────────────────────────────────────────────────
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
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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

// ─────────────────────────────────────────────────────────────────────────────
// STATUS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final int deviceCount;
  const _StatusRow({this.deviceCount = 0});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final isOnline = deviceCount > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s16,
        vertical: AppTheme.s12,
      ),
      decoration: AppTheme.glassCard(context, radius: AppTheme.rMd),
      child: Row(
        children: [
          PulsingDot(color: isOnline ? ext.success : AppTheme.amber),
          const SizedBox(width: AppTheme.s10),
          Text(
            'System online',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isOnline ? ext.success : AppTheme.amber,
            ),
          ),
          const Spacer(),
          Text(
            '$deviceCount device${deviceCount != 1 ? 's' : ''} registered',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE CARD (Restored)
// ─────────────────────────────────────────────────────────────────────────────
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
        mainAxisSize: MainAxisSize.min,
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
            'No devices yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppTheme.s8),
          Text(
            'Tap the + button to register your first NVR\nor link to an existing one.',
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
                const Icon(Icons.add_rounded, size: 16, color: AppTheme.amber),
                const SizedBox(width: AppTheme.s6),
                Text(
                  'Add your first device',
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
