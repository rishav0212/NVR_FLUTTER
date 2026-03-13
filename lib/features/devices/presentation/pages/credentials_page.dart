import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../data/models/device_models.dart';

/// Displays the generated SIP credentials immediately after registration.
///
/// CRITICAL UX RULES:
///   - PopScope(canPop: false) — user CANNOT swipe back. They must tap "Done".
///   - context.pushReplacement was used to get here, so the registration form
///     is already gone from the back-stack.
///   - context.go() on "Done" clears the remaining wizard stack.

/// Each credential is shown in a tappable row. Tap → Clipboard + haptic + snackbar.
/// The amber warning banner at the top explains the password is shown only once.


class CredentialsPage extends StatelessWidget {
  final DeviceCredentials credentials;

  const CredentialsPage({super.key, required this.credentials});

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    AppHaptics.light();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: PageBackground(
          child: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.s24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: AppTheme.s48,
                        ), // Matched spacing to Auth
                        // ── Icon (Phase 1 Consistent) ────────────────────────
                        AnimatedEntrance(
                          delay: Duration.zero,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: AppTheme.amberIconBox(context),
                            child: const Icon(
                              Icons.vpn_key_rounded, // Standard Material Icon
                              color: AppTheme.amber,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.s24),

                        // ── Header (Phase 1 Consistent) ──────────────────────
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 80),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registration Complete',
                                style: Theme.of(context).textTheme.displaySmall,
                              ),
                              const SizedBox(height: AppTheme.s6),
                              Text(
                                'Enter these SIP credentials into your NVR to connect it to the platform.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTheme.s24),

                        // ── Amber warning banner ────────────────────────────
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 160),
                          child: Container(
                            padding: const EdgeInsets.all(AppTheme.s16),
                            decoration: BoxDecoration(
                              color: AppTheme.amber.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(AppTheme.rMd),
                              border: Border.all(
                                color: AppTheme.amber.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons
                                      .warning_amber_rounded, // Standard Material Icon
                                  color: AppTheme.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: AppTheme.s12),
                                Expanded(
                                  child: Text(
                                    'Save these details now. The SIP Password will never be shown again for security.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.amberLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppTheme.s28),

                        // ── Credential rows ───────────────────────────────
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 240),
                          child: Column(
                            children: [
                              _CredentialRow(
                                label: 'SIP Server',
                                value: credentials.sipServerIp,
                                onCopy: () => _copyToClipboard(
                                  context,
                                  credentials.sipServerIp,
                                  'SIP Server',
                                ),
                              ),
                              const SizedBox(height: AppTheme.s8),
                              _CredentialRow(
                                label: 'SIP Port',
                                value: credentials.sipServerPort.toString(),
                                onCopy: () => _copyToClipboard(
                                  context,
                                  credentials.sipServerPort.toString(),
                                  'SIP Port',
                                ),
                              ),
                              const SizedBox(height: AppTheme.s8),
                              _CredentialRow(
                                label: 'SIP Device ID',
                                value: credentials.sipDeviceId,
                                onCopy: () => _copyToClipboard(
                                  context,
                                  credentials.sipDeviceId,
                                  'SIP Device ID',
                                ),
                              ),
                              const SizedBox(height: AppTheme.s8),
                              _CredentialRow(
                                label: 'SIP Password',
                                value: credentials.sipPassword,
                                isHighlighted: true,
                                onCopy: () => _copyToClipboard(
                                  context,
                                  credentials.sipPassword,
                                  'SIP Password',
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: AppTheme.s28),

                        // ── Done CTA ──────────────────────────────────────
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 320),
                          child: PrimaryButton(
                            label: "I've saved these — Done",
                            icon: Icons.check_circle_outline_rounded,
                            onPressed: () {
                              AppHaptics.success();
                              context.go('/devices/${credentials.deviceId}');
                            },
                          ),
                        ),
                        const SizedBox(height: AppTheme.s32),
                      ],
                    ),
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
// CREDENTIAL ROW
// ─────────────────────────────────────────────────────────────────────────────
class _CredentialRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool isHighlighted;

  const _CredentialRow({
    required this.label,
    required this.value,
    required this.onCopy,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s16,
        vertical: AppTheme.s12,
      ),
      decoration: AppTheme.glassCard(context, radius: AppTheme.rMd),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTheme.s4),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                    color: isHighlighted
                        ? AppTheme.amber
                        : theme.colorScheme.onSurface,
                    fontWeight: isHighlighted ? FontWeight.w600 : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCopy,
            icon: const Icon(
              Icons.copy_rounded,
              size: 18,
            ), // Standard Material Icon
            color: AppTheme.amber,
            tooltip: 'Copy $label',
          ),
        ],
      ),
    );
  }
}
