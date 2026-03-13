import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/noise_overlay.dart';

class DeviceDetailPage extends StatelessWidget {
  final String deviceId;
  const DeviceDetailPage({super.key, required this.deviceId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.darkGradient)),
          const NoiseOverlay(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.videoOff, size: 64, color: Colors.white30),
                const SizedBox(height: 16),
                Text('Device Dashboard', style: AppTheme.heading2),
                const SizedBox(height: 8),
                Text(
                  'Camera playback and WebRTC implementation\ncoming in Phase 2 Step 2.',
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium.copyWith(color: Colors.white60),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}