import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../injection_container.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../stream/presentation/bloc/stream_bloc.dart';
import '../../../stream/presentation/widgets/live_stream_grid_player.dart';
import '../../data/models/device_models.dart';
import '../bloc/device_bloc.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DEVICE DETAIL PAGE — Live Camera Matrix
//
// Design principles:
//   • Matches the app's PageBackground + glass card aesthetic (no black shell).
//   • Only the VISIBLE page's tiles stream — all others show placeholders.
//   • Global mute defaults to ON to prevent audio feedback on multi-camera grids.
//   • Channels are cached in DeviceBloc — navigating back never re-fetches.
//   • All active WebRTC sessions are cleaned up when the page is left (PopScope).
//   • GB28181 channel type codes 131/132 = video camera; 134 = alarm input (filtered).
// ═════════════════════════════════════════════════════════════════════════════
class DeviceDetailPage extends StatefulWidget {
  final String deviceId;

  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  State<DeviceDetailPage> createState() => _DeviceDetailPageState();
}

class _DeviceDetailPageState extends State<DeviceDetailPage> {
  // Grid state
  int _columns = 2; // 2 = 2×2, 3 = 3×3, 4 = 4×4
  bool _isMuted = true; // default mute prevents feedback loops
  int _activePage = 0;

  // Set to true briefly on back-press so all tiles receive isActive=false
  // and send their stop events before the widget tree is torn down.
  bool _isTearingDown = false;

  final PageController _pageController = PageController();

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Uses cache in DeviceBloc — no-op if channels are already loaded
    context.read<DeviceBloc>().add(LoadDeviceChannels(widget.deviceId));
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int get _tilesPerPage => _columns * _columns;

  // ── Actions ───────────────────────────────────────────────────────────────

  void _cycleGrid() {
    AppHaptics.light();
    setState(() {
      _columns = _columns == 2
          ? 3
          : _columns == 3
          ? 4
          : 2;
      _activePage = 0;
      _pageController.jumpToPage(0);
    });
  }

  void _toggleMute() {
    AppHaptics.selection();
    setState(() => _isMuted = !_isMuted);
  }

  /// Graceful back: signal all tiles to stop streaming, then pop.
  Future<void> _handleBack() async {
    setState(() => _isTearingDown = true);
    // Give tiles one frame to receive isActive=false and enqueue StopStreamEvent
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) context.pop();
  }

  // ── Channel filtering ─────────────────────────────────────────────────────

  /// GB28181 type codes: 131 = front-end video, 132 = front-end digital.
  /// 134 = alarm input — we filter these out entirely.
  List<NvrChannel> _videoChannels(List<NvrChannel> all) {
    return all.where((ch) {
      final id = ch.channelId;
      if (id.length == 20) {
        final type = id.substring(10, 13);
        return type == '131' || type == '132';
      }
      // Non-standard ID: keep anything that doesn't look like an alarm channel
      return !id.contains('134');
    }).toList();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: PageBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Top bar — same visual language as home
                _TopBar(
                  onBack: _handleBack,
                  onGridToggle: _cycleGrid,
                  onMuteToggle: _toggleMute,
                  columns: _columns,
                  isMuted: _isMuted,


                ),
                // Main content
                Expanded(
                  child: BlocBuilder<DeviceBloc, DeviceState>(
                    builder: (context, state) {
                      if (state is DeviceOperationLoading ||
                          state is DeviceInitial) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.amber,
                            strokeWidth: 2,
                          ),
                        );
                      }

                      if (state is DeviceError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppTheme.s24),
                            child: ErrorBanner(message: state.message),
                          ),
                        );
                      }

                      if (state is DeviceChannelsLoaded) {
                        final channels = _videoChannels(state.channels);

                        if (channels.isEmpty) {
                          return const _EmptyChannelsView();
                        }

                        final totalPages = (channels.length / _tilesPerPage)
                            .ceil();

                        return Column(
                          children: [
                            // Status strip
                            _StatusStrip(
                              total: channels.length,
                              online: channels.where((c) => c.isOnline).length,
                            ),
                            // Grid pages
                            Expanded(
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (page) =>
                                    setState(() => _activePage = page),
                                itemCount: totalPages,
                                itemBuilder: (context, pageIndex) {
                                  return _CameraGridPage(
                                    channels: channels,
                                    pageIndex: pageIndex,
                                    tilesPerPage: _tilesPerPage,
                                    columns: _columns,
                                    // Tiles are only active on the current
                                    // visible page — prevents N pages × N
                                    // streams running simultaneously.
                                    // Also deactivated during teardown so
                                    // streams stop before dispose fires.
                                    isPageActive:
                                        !_isTearingDown &&
                                        pageIndex == _activePage,
                                    isMuted: _isMuted,
                                    deviceId: widget.deviceId,
                                    onFullScreen: (ch) => context.push(
                                      '/devices/${widget.deviceId}/channels/${ch.channelId}/live',
                                      extra: {'channelName': ch.name},
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Page indicator (only if more than one page)
                            if (totalPages > 1)
                              _PageIndicator(
                                total: totalPages,
                                current: _activePage,
                                onPrev: _activePage > 0
                                    ? () => _pageController.previousPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      )
                                    : null,
                                onNext: _activePage < totalPages - 1
                                    ? () => _pageController.nextPage(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeInOut,
                                      )
                                    : null,
                              ),
                          ],
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR
// Matches the home page top bar aesthetic: glass card, amber accents.
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onGridToggle;
  final VoidCallback onMuteToggle;
  final int columns;
  final bool isMuted;

  const _TopBar({
    required this.onBack,
    required this.onGridToggle,
    required this.onMuteToggle,
    required this.columns,
    required this.isMuted,
  });

  String get _gridLabel => '${columns}×$columns';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.s16,
        AppTheme.s8,
        AppTheme.s16,
        AppTheme.s4,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s8,
          vertical: AppTheme.s8,
        ),
        decoration: AppTheme.glassCard(context, radius: AppTheme.rLg),
        child: Row(
          children: [
            // Back
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              onPressed: onBack,
              tooltip: 'Back',
            ),
            const SizedBox(width: AppTheme.s4),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Live View',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Container(
                    width: 28,
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: AppTheme.amberBtn,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
            // Grid size toggle — shows current grid label
            _ControlButton(
              label: _gridLabel,
              icon: Icons.grid_view_rounded,
              onTap: onGridToggle,
              isActive: false,
              tooltip:
                  'Change grid (${columns == 2
                      ? '3×3'
                      : columns == 3
                      ? '4×4'
                      : '2×2'} next)',
            ),
            const SizedBox(width: AppTheme.s8),
            // Mute toggle — amber when unmuted
            _ControlButton(
              label: isMuted ? 'Muted' : 'Live',
              icon: isMuted
                  ? Icons.volume_off_rounded
                  : Icons.volume_up_rounded,
              onTap: onMuteToggle,
              isActive: !isMuted,
              tooltip: isMuted ? 'Unmute all cameras' : 'Mute all cameras',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTROL BUTTON — small pill button used in the top bar
// ─────────────────────────────────────────────────────────────────────────────
class _ControlButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final String tooltip;

  const _ControlButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.isActive,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.s10,
            vertical: AppTheme.s6,
          ),
          decoration: BoxDecoration(
            gradient: isActive ? ext.amberTint : null,
            color: isActive ? null : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.rFull),
            border: Border.all(
              color: isActive
                  ? AppTheme.amber.withOpacity(0.4)
                  : ext.borderSubtle,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive
                    ? AppTheme.amber
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? AppTheme.amber
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STATUS STRIP — shows total / online channel count
// ─────────────────────────────────────────────────────────────────────────────
class _StatusStrip extends StatelessWidget {
  final int total;
  final int online;

  const _StatusStrip({required this.total, required this.online});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.s16,
        AppTheme.s4,
        AppTheme.s16,
        AppTheme.s8,
      ),
      child: Row(
        children: [
          PulsingDot(color: online > 0 ? ext.success : AppTheme.amber, size: 7),
          const SizedBox(width: AppTheme.s8),
          Text(
            '$online of $total cameras online',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: online > 0 ? ext.success : AppTheme.amber,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CAMERA GRID PAGE — one page of the PageView
// Each tile gets an isolated StreamBloc. isPageActive controls streaming.
// ─────────────────────────────────────────────────────────────────────────────
class _CameraGridPage extends StatelessWidget {
  final List<NvrChannel> channels;
  final int pageIndex;
  final int tilesPerPage;
  final int columns;
  final bool isPageActive;
  final bool isMuted;
  final String deviceId;
  final void Function(NvrChannel channel) onFullScreen;

  const _CameraGridPage({
    super.key,
    required this.channels,
    required this.pageIndex,
    required this.tilesPerPage,
    required this.columns,
    required this.isPageActive,
    required this.isMuted,
    required this.deviceId,
    required this.onFullScreen,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s8,
        vertical: AppTheme.s4,
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 16 / 9,
          crossAxisSpacing: AppTheme.s4,
          mainAxisSpacing: AppTheme.s4,
        ),
        itemCount: tilesPerPage,
        itemBuilder: (context, gridIndex) {
          final channelIndex = pageIndex * tilesPerPage + gridIndex;

          // Empty grid slots (last page may not be full)
          if (channelIndex >= channels.length) {
            return _EmptyTile();
          }

          final channel = channels[channelIndex];

          // Offline channels show a static placeholder — no stream attempt
          if (!channel.isOnline) {
            return _OfflineTile(name: channel.name);
          }

          // Each tile gets a fresh, isolated StreamBloc.
          // ValueKey ensures the bloc is recreated if the channel changes.
          return BlocProvider<StreamBloc>(
            key: ValueKey('stream_${deviceId}_${channel.channelId}'),
            create: (_) => getIt<StreamBloc>(),
            child: LiveStreamGridPlayer(
              deviceId: deviceId,
              channelId: channel.channelId,
              channelName: channel.name,
              // Only stream if this page is the currently visible page
              isActive: isPageActive,
              isMuted: isMuted,
              gridIndex: gridIndex,
              onFullScreenTap: () => onFullScreen(channel),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE INDICATOR — prev/next arrows + "Page N of M"
// ─────────────────────────────────────────────────────────────────────────────
class _PageIndicator extends StatelessWidget {
  final int total;
  final int current;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PageIndicator({
    required this.total,
    required this.current,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.s16,
        AppTheme.s4,
        AppTheme.s16,
        AppTheme.s12,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.s4,
          vertical: AppTheme.s4,
        ),
        decoration: AppTheme.glassCard(
          context,
          radius: AppTheme.rFull,
          addShadow: false,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                Icons.chevron_left_rounded,
                color: onPrev != null
                    ? Theme.of(context).colorScheme.onSurface
                    : ext.borderSubtle,
              ),
              onPressed: onPrev,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.s12),
              child: Text(
                '${current + 1} / $total',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            IconButton(
              iconSize: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              icon: Icon(
                Icons.chevron_right_rounded,
                color: onNext != null
                    ? Theme.of(context).colorScheme.onSurface
                    : ext.borderSubtle,
              ),
              onPressed: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY TILE — placeholder for unfilled grid slots
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.rSm),
        border: Border.all(
          color: Theme.of(
            context,
          ).extension<AppColorsExtension>()!.borderSubtle,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.videocam_off_outlined,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withOpacity(0.2),
          size: 20,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// OFFLINE TILE — shown when a channel's status is OFFLINE
// ─────────────────────────────────────────────────────────────────────────────
class _OfflineTile extends StatelessWidget {
  final String name;

  const _OfflineTile({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(AppTheme.rSm),
        border: Border.all(
          color: Theme.of(
            context,
          ).extension<AppColorsExtension>()!.borderSubtle,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.videocam_off_rounded,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.3),
              size: 22,
            ),
          ),
          Positioned(
            bottom: AppTheme.s4,
            left: AppTheme.s6,
            right: AppTheme.s6,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY CHANNELS VIEW — shown when device has no video channels
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyChannelsView extends StatelessWidget {
  const _EmptyChannelsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.s32),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.s32),
          decoration: AppTheme.glassCard(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: AppTheme.amberIconBox(context),
                child: const Icon(
                  Icons.videocam_off_outlined,
                  color: AppTheme.amber,
                  size: 26,
                ),
              ),
              const SizedBox(height: AppTheme.s16),
              Text(
                'No cameras found',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppTheme.s8),
              Text(
                'The NVR reported no video channels.\nCheck the SIP registration and NVR settings.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
