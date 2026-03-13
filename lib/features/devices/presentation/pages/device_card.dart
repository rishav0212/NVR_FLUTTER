import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/device_models.dart';

class DeviceCard extends StatelessWidget {
  final NvrDevice device;
  final VoidCallback onTap;

  const DeviceCard({super.key, required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    
    // Determine status colors based on backend enum
    Color statusColor;
    if (device.isOnline) {
      statusColor = ext.success;
    } else if (device.isOffline) {
      statusColor = ext.surfaceLight;
    } else {
      statusColor = AppTheme.amber;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCard(context),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(LucideIcons.server, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.name, style: AppTheme.heading3),
                  const SizedBox(height: 4),
                  Text(
                    device.location ?? 'No location set', 
                    style: AppTheme.bodySmall.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      device.status.replaceAll('_', ' '),
                      style: AppTheme.bodySmall.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Icon(LucideIcons.chevronRight, color: Colors.white30, size: 20),
              ],
            )
          ],
        ),
      ),
    );
  }
}