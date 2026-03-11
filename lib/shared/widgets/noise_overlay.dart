import 'dart:math';
import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════════════════════
// NOISE OVERLAY — film grain texture
// ═════════════════════════════════════════════════════════════════════════════
//
// WHY THIS EXISTS:
//   Dark gradients without noise look like flat paint.
//   Every premium dark UI (Raycast, Arc, Linear, Vercel) uses a film grain
//   layer. It's nearly invisible individually but transforms the perceived
//   quality of the entire background — dark surfaces gain tactile depth.
//
// HOW IT WORKS:
//   CustomPainter draws ~8000 semi-transparent dots at a FIXED random seed.
//   Fixed seed = same pattern every frame = shouldRepaint returns false =
//   zero performance cost. The dots never animate or repaint.
//
// Usage:
//   NoiseOverlay(child: myWidget)
//
// Or with explicit opacity:
//   NoiseOverlay(opacity: 0.05, child: myWidget)
//
class NoiseOverlay extends StatelessWidget {
  final Widget child;

  /// Dot opacity. Keep between 0.02 – 0.06.
  /// Dark mode: 0.04 is ideal.
  /// Light mode: 0.015 – 0.02 keeps it subtle on white backgrounds.
  final double opacity;

  const NoiseOverlay({super.key, required this.child, this.opacity = 0.04});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            // CRITICAL: IgnorePointer prevents grain from eating touch events
            child: RepaintBoundary(
              // RepaintBoundary isolates grain repaints from parent
              child: CustomPaint(painter: _NoisePainter(opacity: opacity)),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;

  _NoisePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed seed = deterministic = identical grain on every paint call
    final random = Random(42);
    final paint = Paint();

    // 8000 dots covers a typical phone screen with good density
    for (int i = 0; i < 8000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      // Each dot has its own random alpha within the opacity budget
      final alpha = (random.nextDouble() * opacity * 255).toInt();
      paint.color = Color.fromARGB(alpha, 255, 255, 255);
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(_NoisePainter old) => old.opacity != opacity;
}
