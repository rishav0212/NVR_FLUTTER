import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Primary action button — amber fill, full width.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: AppTheme.sm),
                ],
                Text(label),
              ],
            ),
    );
  }
}

/// Input field with consistent styling.
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
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      style: Theme.of(context).textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, size: 18)
            : null,
        suffixIcon: widget.obscureText
            ? GestureDetector(
                onTap: () => setState(() => _obscure = !_obscure),
                child: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  // Adapts to light/dark mode automatically
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                ),
              )
            : widget.suffixWidget,
      ),
    );
  }
}

/// Divider with centered text label — used for "or continue with".
class LabeledDivider extends StatelessWidget {
  final String label;

  const LabeledDivider({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.md),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

/// Google Sign-In button — outlined, with Google logo.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const GoogleSignInButton({super.key, this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" logo using colored text — no image asset needed
                const _GoogleLogo(),
                const SizedBox(width: AppTheme.sm),
                Text(
                  'Continue with Google',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          Center(
            child: Text(
              'G',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4285F4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error message banner — shown inside the form area.
/// Dynamically uses theme colors to look correct in both Light and Dark modes.
class ErrorBanner extends StatelessWidget {
  final String message;

  const ErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? AppTheme.offlineRed.withOpacity(0.1)
        : AppTheme.offlineRed.withOpacity(0.05);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.md,
        vertical: AppTheme.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: AppTheme.offlineRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.offlineRed, size: 16),
          const SizedBox(width: AppTheme.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.offlineRed),
            ),
          ),
        ],
      ),
    );
  }
}

/// A highly reusable, zero-dependency wrapper that creates a smooth
/// slide-up and fade-in entrance animation. Used across all screens to
/// eliminate jarring jumps and add high-end polish.
class AnimatedEntrance extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const AnimatedEntrance({super.key, required this.child, required this.delay});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// The app wordmark — adapts to Light/Dark automatically
class AppWordmark extends StatelessWidget {
  const AppWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.amberGlow,
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            border: Border.all(color: AppTheme.amberDim, width: 1),
          ),
          child: const Icon(
            Icons.videocam_outlined,
            color: AppTheme.amber,
            size: 22,
          ),
        ),
        const SizedBox(width: AppTheme.sm),
        Text(
          'Sentinel',
          style: Theme.of(context).textTheme.displayMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface, // Adapts to Light/Dark mode
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(width: 3),
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: const BoxDecoration(
            color: AppTheme.amber,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}
