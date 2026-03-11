import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
// ACCENT HEADER
// ═════════════════════════════════════════════════════════════════════════════
//
// Used for section titles on the home page and detail pages.
// The tiny amber underline bar is the brand accent — used by Stripe, Linear.
//
// Usage:
//   AccentHeader(text: 'Cameras')
//   AccentHeader(text: 'Cameras', style: textTheme.headlineLarge)
//
class AccentHeader extends StatelessWidget {
  final String text;
  final TextStyle? style;

  /// Width of the amber accent bar in logical pixels
  final double barWidth;

  const AccentHeader({
    super.key,
    required this.text,
    this.style,
    this.barWidth = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: style ?? Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTheme.s6),
        Container(
          width: barWidth,
          height: 2.5,
          decoration: const BoxDecoration(
            gradient: AppTheme.amberBtn,
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
        ),
      ],
    );
  }
}
