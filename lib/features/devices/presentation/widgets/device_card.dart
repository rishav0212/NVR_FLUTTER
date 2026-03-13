import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/device_models.dart';

// ═════════════════════════════════════════════════════════════════════════════
// DEVICE CARD
// ═════════════════════════════════════════════════════════════════════════════
//
// Reusable card for each NVR device in the home screen list.
// Uses AppTheme.glassCard for the surface and resolves all colours from
// the active theme/extension — no hardcoded hex values.
//
// Status indicators:
//   ONLINE             → ext.success + PulsingDot (live animation)
//   OFFLINE            → colorScheme.onSurfaceVariant (muted, static dot)
//   PENDING_CONNECTION → AppTheme.amber (waiting, static dot)
//
class DeviceCard extends StatelessWidget {
  final NvrDevice device;
  final VoidCallback onTap; // <--- 1. Added onTap parameter

  const DeviceCard({
    super.key,
    required this.device,
    required this.onTap, // <--- 2. Required in constructor
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ext = theme.extension<AppColorsExtension>()!;

    // Resolve status colour and label from device state
    final Color statusColor;
    final String statusLabel;

    if (device.isOnline) {
      statusColor = ext.success;
      statusLabel = 'Online';
    } else if (device.isOffline) {
      statusColor = theme.colorScheme.onSurfaceVariant;
      statusLabel = 'Offline';
    } else {
      // PENDING_CONNECTION
      statusColor = AppTheme.amber;
      statusLabel = 'Pending';
    }

    return GestureDetector(
      onTap: () {
        AppHaptics.light();
        onTap(); // <--- 3. Trigger the passed function instead of hardcoding GoRouter here
      },
      behavior:
          HitTestBehavior.opaque, // Ensures the entire card area is clickable
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.s12),
        padding: const EdgeInsets.all(AppTheme.s16),
        decoration: AppTheme.glassCard(context),
        child: Row(
          children: [
            // ── Device icon ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppTheme.s12),
              decoration: AppTheme.amberIconBox(context, radius: AppTheme.rMd),
              child: const Icon(
                Icons.dns_rounded, // <--- Swapped to standard Material Icon
                color: AppTheme.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: AppTheme.s16),

            // ── Name + location ────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: theme.textTheme.headlineSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppTheme.s4),
                  Text(
                    device.location ?? 'No location set',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Status + chevron ───────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulsing dot only for ONLINE — static for other states
                    if (device.isOnline)
                      PulsingDot(color: statusColor, size: 7)
                    else
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    const SizedBox(width: AppTheme.s6),
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.s8),
                Icon(
                  Icons
                      .chevron_right_rounded, // <--- Swapped to standard Material Icon
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
