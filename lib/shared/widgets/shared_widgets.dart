import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SENTINEL SHARED WIDGETS v4
// ═════════════════════════════════════════════════════════════════════════════
//
// Every reusable component lives here. No hardcoded values — all from AppTheme.
//
// Contents:
//   • AnimatedEntrance     — staggered entrance animation
//   • PageBackground       — dynamic mesh gradient background wrapper
//   • AppWordmark          — brand logo mark
//   • GlassCard            — frosted glass container
//   • PrimaryButton        — amber gradient with press animation
//   • SecondaryButton      — outlined ghost button
//   • GoogleSignInButton   — Google branded outlined button
//   • AppTextField         — input with animated focus ring
//   • LabeledDivider       — "— or —" separator
//   • ErrorBanner          — inline error display
//   • SuccessBanner        — inline success display
//   • PulsingDot           — animated status indicator
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED ENTRANCE
// ─────────────────────────────────────────────────────────────────────────────
//
// WHY THE OLD VERSION WAS "STICKY/STUCK":
//
//   OLD: StatelessWidget + TweenAnimationBuilder
//   ┌─ Bug 1: delay was accepted but NEVER applied — all elements animated
//   │         simultaneously with zero stagger effect.
//   └─ Bug 2: TweenAnimationBuilder restarts on EVERY parent rebuild —
//             BlocBuilder rebuilds during loading/error transitions,
//             causing mid-transition resets (the "stuck" snap-back).
//
//   NEW: StatefulWidget + AnimationController
//   ┌─ Fix 1: Timer(delay, ...) in initState() — delay is truly applied
//   ├─ Fix 2: AnimationController fires ONCE on mount, survives rebuilds
//   ├─ Fix 3: Two parallel tweens (opacity + slide) via Interval curves
//   │         give a richer, more cinematic feel
//   └─ Fix 4: Timer is cancelled in dispose() — no memory leaks
//
class AnimatedEntrance extends StatefulWidget {
  final Widget child;

  /// Stagger delay — how long to wait before starting the animation.
  /// Set incrementally per element: 0ms, 80ms, 160ms, 240ms...
  final Duration delay;

  /// Total animation duration. Default matches AppTheme.tSlow.
  final Duration duration;

  /// How far (in logical pixels) the widget slides up from.
  final double slideDistance;

  const AnimatedEntrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppTheme.tSlow,
    this.slideDistance = 28.0,
  });

  @override
  State<AnimatedEntrance> createState() => _AnimatedEntranceState();
}

class _AnimatedEntranceState extends State<AnimatedEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(vsync: this, duration: widget.duration);

    // Opacity fades in over the first 75% of the animation
    _opacity = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.75, curve: AppTheme.curveEntrance),
    );

    // Slide covers the full animation duration
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideDistance / 200),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: AppTheme.curveEntrance));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) => FadeTransition(
        opacity: _opacity,
        child: SlideTransition(position: _slide, child: child),
      ),
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE BACKGROUND
// ─────────────────────────────────────────────────────────────────────────────
//
// Wraps page Scaffold body content with the layered mesh background:
//   Layer 0: base gradient (void-black for dark mode, pearl for light mode)
//   Layer 1: amber radial bleed — top-left (warmth, security light)
//   Layer 2: indigo radial bleed — bottom-right (depth, cool contrast)
//   Layer 3: content
//
// Retrieves active background meshes dynamically via ThemeExtension for
// seamless Light/Dark mode support.
//
// Usage: wrap your SafeArea (or child) with this, not the Scaffold.
//
class PageBackground extends StatelessWidget {
  final Widget child;
  const PageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Pulls the active background design securely based on light/dark mode
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // The core gradient background (Aurora for dark, Pearl for light)
        Container(decoration: BoxDecoration(gradient: ext.bgGradient)),
        // Top Amber Mesh Blob
        Positioned(
          top: -150,
          left: -150,
          width: 500,
          height: 500,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: ext.meshAmber,
              shape: BoxShape.circle,
            ),
          ),
        ),
        // Bottom Indigo Mesh Blob
        Positioned(
          bottom: -100,
          right: -100,
          width: 400,
          height: 400,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: ext.meshIndigo,
              shape: BoxShape.circle,
            ),
          ),
        ),
        child, // Rest of the page content
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP WORDMARK
// ─────────────────────────────────────────────────────────────────────────────
//
// Brand mark used on all auth screens.
// Amber gradient icon box + Outfit wordmark + amber pulse dot.
//
class AppWordmark extends StatelessWidget {
  final double size;

  const AppWordmark({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    // Dynamically accesses the proper high-contrast icon color for the theme
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Icon container with amber gradient + dynamic glow
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: AppTheme.amberBtn,
            borderRadius: BorderRadius.circular(AppTheme.rMd),
            boxShadow: [
              BoxShadow(
                color: AppTheme.amber.withOpacity(0.20),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.videocam_rounded,
            color: onPrimary,
            size: size * 0.5,
          ),
        ),
        const SizedBox(width: AppTheme.s12),
        Text(
          'Sentinel',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(width: AppTheme.s4),
        // Amber pulse dot — floated to top-right of wordmark
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.amber.withOpacity(0.35),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS CARD
// ─────────────────────────────────────────────────────────────────────────────
//
// Frosted glass container for grouping related content.
// Utilizes context to inject the theme-appropriate soft shadows and border opacities.
//
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? borderColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppTheme.s20),
      decoration: AppTheme.glassCard(
        context, // Injects active ThemeExtension for light/dark properties
        radius: borderRadius ?? AppTheme.rLg,
        borderColor: borderColor,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIMARY BUTTON
// ─────────────────────────────────────────────────────────────────────────────
//
// Amber gradient button with:
//   • Press scale (0.97) via AnimationController — feels physical
//   • Glow shadow that disappears when loading/disabled
//   • Loading spinner adapting to context onPrimary color
//
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.height = 54,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 160),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  bool get _isActive => !widget.isLoading && widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: _isActive ? (_) => _press.forward() : null,
      onTapUp: _isActive
          ? (_) {
              _press.reverse();
              widget.onPressed?.call();
            }
          : null,
      onTapCancel: _isActive ? () => _press.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedOpacity(
          opacity: _isActive ? 1.0 : 0.55,
          duration: AppTheme.tFast,
          child: Container(
            width: double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: _isActive ? AppTheme.amberBtn : null,
              color: _isActive ? null : AppTheme.amberDim,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
              boxShadow: _isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.amber.withOpacity(0.20),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                      BoxShadow(
                        color: ext.amberGlow10,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: onPrimary,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18, color: onPrimary),
                        const SizedBox(width: AppTheme.s8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onPrimary,
                          letterSpacing: 0.15,
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
// SECONDARY BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rMd),
          ),
          textStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18),
                    const SizedBox(width: AppTheme.s8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GOOGLE SIGN IN BUTTON
// ─────────────────────────────────────────────────────────────────────────────

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          backgroundColor: Colors.transparent,
          side: BorderSide(color: colorScheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.rMd),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GoogleGlyph(),
                  const SizedBox(width: AppTheme.s10),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ],
              ),
      ),
    );
  }
}

/// Google "G" glyph rendered with colored text spans — no SVG asset needed.
class _GoogleGlyph extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 18,
      height: 18,
      child: Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP TEXT FIELD
// ─────────────────────────────────────────────────────────────────────────────
//
// Enhanced input field:
//   • AnimatedSwitcher on the visibility toggle icon
//   • Subtle amber glow container on focus dynamically sourced from ThemeExtension
//
class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final Widget? suffixWidget;
  final TextInputAction textInputAction;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final bool enabled;
  final int maxLines;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixWidget,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;
  final FocusNode _focus = FocusNode();
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
    _focus.addListener(() {
      if (mounted) setState(() => _hasFocus = _focus.hasFocus);
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;
    final hintColor = Theme.of(context).colorScheme.onSurfaceVariant;

    return AnimatedContainer(
      duration: AppTheme.tMid,
      curve: AppTheme.curveSmooth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.rMd),
        boxShadow: _hasFocus
            ? [
                BoxShadow(
                  color: ext.amberGlow10,
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        obscureText: _obscure,
        keyboardType: widget.keyboardType,
        validator: widget.validator,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        enabled: widget.enabled,
        maxLines: _obscure ? 1 : widget.maxLines,
        autofocus: widget.autofocus,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.2),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, size: 18)
              : null,
          suffixIcon: widget.obscureText
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.s12,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppTheme.tFast,
                      child: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        key: ValueKey(_obscure),
                        size: 18,
                        color: hintColor,
                      ),
                    ),
                  ),
                )
              : widget.suffixWidget,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LABELED DIVIDER
// ─────────────────────────────────────────────────────────────────────────────

class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.s16),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ERROR BANNER
// ─────────────────────────────────────────────────────────────────────────────

class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s16,
        vertical: AppTheme.s12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.error.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.rSm),
        border: Border.all(color: AppTheme.error.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: AppTheme.s2),
            child: Icon(
              Icons.error_outline_rounded,
              color: AppTheme.error,
              size: 15,
            ),
          ),
          const SizedBox(width: AppTheme.s8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.error,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUCCESS BANNER
// ─────────────────────────────────────────────────────────────────────────────

class SuccessBanner extends StatelessWidget {
  final String message;

  const SuccessBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final ext = Theme.of(context).extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.s16,
        vertical: AppTheme.s12,
      ),
      decoration: BoxDecoration(
        color: ext.success.withOpacity(0.07),
        borderRadius: BorderRadius.circular(AppTheme.rSm),
        border: Border.all(color: ext.success.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: ext.success,
            size: 15,
          ),
          const SizedBox(width: AppTheme.s8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ext.success,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSING DOT — animated status indicator
// ─────────────────────────────────────────────────────────────────────────────
//
// Defaults dynamically to the active theme's success status color unless
// explicitly provided.
//
class PulsingDot extends StatefulWidget {
  final Color? color;
  final double size;

  const PulsingDot({super.key, this.color, this.size = 8});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scale = Tween<double>(
      begin: 0.85,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Dynamically fallback to the ThemeExtension success color if none is passed
    final activeColor =
        widget.color ??
        Theme.of(context).extension<AppColorsExtension>()!.success;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: activeColor.withOpacity(0.4),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
