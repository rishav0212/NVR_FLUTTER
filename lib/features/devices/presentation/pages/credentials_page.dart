import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/accent_header.dart';
import '../../../../shared/widgets/noise_overlay.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/device_models.dart';

class CredentialsPage extends StatelessWidget {
  final DeviceCredentials credentials;

  const CredentialsPage({super.key, required this.credentials});

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    AppHaptics.success();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied!')));
  }

  @override
  Widget build(BuildContext context) {
    // PopScope prevents the user from swiping back to the registration form
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Stack(
          children: [
            Container(decoration: const BoxDecoration(gradient: AppTheme.darkGradient)),
            const NoiseOverlay(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const AnimatedEntrance(
                      delay: Duration(milliseconds: 100),
                      child: AccentHeader(
                        title: 'Registration Complete',
                        subtitle: 'Enter these SIP credentials into your physical NVR to connect it to the cloud platform.',
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withOpacity(0.1),
                          border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: AppTheme.error),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Save these details now. For security reasons, the SIP Password will never be shown again.',
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 300),
                      child: _buildRow(context, 'SIP Server IP', credentials.sipServerIp),
                    ),
                    const SizedBox(height: 12),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 400),
                      child: _buildRow(context, 'SIP Server Port', credentials.sipServerPort.toString()),
                    ),
                    const SizedBox(height: 12),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 500),
                      child: _buildRow(context, 'SIP Device ID', credentials.sipDeviceId),
                    ),
                    const SizedBox(height: 12),
                    AnimatedEntrance(
                      delay: const Duration(milliseconds: 600),
                      child: _buildRow(context, 'SIP Password', credentials.sipPassword, isPassword: true),
                    ),
                    const Spacer(),
                    PrimaryButton(
                      text: "I've Saved These Details",
                      onPressed: () {
                        AppHaptics.light();
                        // Go directly to the new device's detail page
                        context.go('/devices/${credentials.deviceId}');
                      },
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String value, {bool isPassword = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassCard(context), // Using your specific Glassmorphic theme
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.bodySmall.copyWith(color: Colors.white60)),
              const SizedBox(height: 4),
              Text(
                value, 
                style: AppTheme.bodyLarge.copyWith(
                  fontFamily: 'monospace', 
                  color: isPassword ? AppTheme.accentColor : Colors.white
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(LucideIcons.copy, color: AppTheme.primaryColor),
            onPressed: () => _copy(context, value, label),
          )
        ],
      ),
    );
  }
}