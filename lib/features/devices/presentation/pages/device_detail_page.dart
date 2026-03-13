import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';

/// Phase 2 — Step 2 placeholder for the device detail / live view screen.
///
/// Currently displays a holding state with device ID and a "coming soon" message.
/// Will be replaced with:
///   • Camera grid / live WebRTC stream (Phase 2 Step 2)
///   • Device settings and member management
///   • Playback controls
///
/// Back navigation uses context.go('/home') to clear the device stack entirely
/// (this page is always reached via context.go, not context.push).
class DeviceDetailPage extends StatelessWidget {
  final String deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            AppHaptics.light();
            context.go(AppConstants.homeRoute);
          },
        ),
        title: const Text('Device'),
      ),
      body: PageBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.s40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Placeholder icon ─────────────────────────────────
                  Container(
                    width: 72,
                    height: 72,
                    decoration: AppTheme.amberIconBox(
                      context,
                      radius: AppTheme.rXl,
                    ),
                    child: const Icon(
                      LucideIcons.videoOff,
                      color: AppTheme.amber,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppTheme.s24),

                  // ── Title ────────────────────────────────────────────
                  Text(
                    'Camera Dashboard',
                    style: theme.textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppTheme.s8),

                  // ── Device ID indicator ───────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.s12,
                      vertical: AppTheme.s6,
                    ),
                    decoration: AppTheme.glassCard(
                      context,
                      radius: AppTheme.rSm,
                    ),
                    child: Text(
                      'Device: ${deviceId.substring(0, 8).toUpperCase()}…',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.s16),

                  // ── Description ───────────────────────────────────────
                  Text(
                    'Live WebRTC stream and camera management\ncoming in Phase 2 Step 2.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.s32),

                  // ── Phase badge ───────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.s16,
                      vertical: AppTheme.s8,
                    ),
                    decoration: BoxDecoration(
                      gradient: theme
                          .extension<AppColorsExtension>()!
                          .amberTint,
                      borderRadius: BorderRadius.circular(AppTheme.rFull),
                      border: Border.all(
                        color: AppTheme.amber.withOpacity(0.2),
                      ),
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
                          'Phase 2 Step 2 — In development',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppTheme.amber,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
