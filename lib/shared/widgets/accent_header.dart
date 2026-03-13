import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ACCENT HEADER
// ═════════════════════════════════════════════════════════════════════════════
//
// Section heading with a small amber underline accent bar.
// Used on the home page, device wizard pages, and detail pages.
//
// The optional [subtitle] is rendered as secondary body text below the bar —
// used for contextual instructions in the device wizard flow.
//
// Usage:
//   AccentHeader(title: 'Cameras')
//   AccentHeader(title: 'Add Device', subtitle: 'Enter the serial number...')
//   AccentHeader(title: 'Cameras', style: textTheme.headlineLarge)
//
class AccentHeader extends StatelessWidget {
  /// Main heading text.
  final String title;

  /// Optional secondary description shown below the amber bar.
  final String? subtitle;

  /// Override the heading text style. Defaults to headlineMedium.
  final TextStyle? style;

  /// Width of the amber accent underline bar in logical pixels.
  final double barWidth;

  const AccentHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.style,
    this.barWidth = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Heading ──────────────────────────────────────────────────────────
        Text(title, style: style ?? Theme.of(context).textTheme.headlineMedium),

        // ── Amber underline bar ───────────────────────────────────────────
        const SizedBox(height: AppTheme.s6),
        Container(
          width: barWidth,
          height: 2.5,
          decoration: const BoxDecoration(
            gradient: AppTheme.amberBtn,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),

        // ── Optional subtitle ─────────────────────────────────────────────
        if (subtitle != null) ...[
          const SizedBox(height: AppTheme.s10),
          Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}
