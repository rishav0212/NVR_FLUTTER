import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
// GRADIENT TEXT
// ═════════════════════════════════════════════════════════════════════════════
//
// Renders text with a gradient fill using ShaderMask + BlendMode.srcIn.
// Used primarily for large headlines and the brand wordmark to make typography
// feel dimensional and physical rather than flat.
//
// If no explicit gradient is provided, it dynamically defaults to the active
// theme's surface text colors (onSurface -> onSurfaceVariant), ensuring
// perfect legibility and aesthetic blending in both Light and Dark modes.
//
// Usage:
//   GradientText('Sentinel', style: textTheme.displayMedium)
//
//   GradientText(
//     'Welcome back',
//     style: textTheme.displaySmall,
//     gradient: GradientText.amberGradient,
//   )
//
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient? gradient;
  final TextAlign? textAlign;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient,
    this.textAlign,
  });

  /// Amber variant — specifically tuned for the brand wordmark on splash/auth.
  /// Kept static as the brand accent colors do not invert in light/dark mode.
  static const LinearGradient amberGradient = LinearGradient(
    colors: [AppTheme.amberLight, AppTheme.amber, AppTheme.amberDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    // Dynamically resolve the gradient based on the active Material 3 ColorScheme.
    // Top is solid primary text, bottom is muted secondary text.
    final resolvedGradient =
        gradient ??
        LinearGradient(
          colors: [
            Theme.of(context).colorScheme.onSurface,
            Theme.of(context).colorScheme.onSurfaceVariant,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => resolvedGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style, textAlign: textAlign),
    );
  }
}
