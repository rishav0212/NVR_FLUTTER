import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';

// ═════════════════════════════════════════════════════════════════════════════
// NOISE OVERLAY — film grain texture (GPU Optimized)
// ═════════════════════════════════════════════════════════════════════════════
//
// WHY THIS EXISTS:
//   Dark gradients without noise look like flat paint.
//   Every premium UI uses a film grain layer. It's nearly invisible individually
//   but transforms the perceived quality of the entire background — surfaces gain tactile depth.
//
// UPDATE WHY WE CHANGED THIS:
//   The previous version used a `for` loop to execute `canvas.drawCircle` 8,000 times.
//   In Flutter, each `drawCircle` is a separate GPU instruction. 8,000 instructions
//   per frame choked the UI thread and caused severe lag during route transitions and animations.
//   We migrated to `Float32List` caching and `canvas.drawRawPoints`, which sends all
//   8,000 dots to the GPU in exactly 1 instruction, instantly fixing the UI hanging/lag.
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
    // Automatically detect the theme to determine the grain color
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            // CRITICAL: IgnorePointer prevents grain from eating touch events
            child: RepaintBoundary(
              // RepaintBoundary isolates grain repaints from the parent widget tree
              child: CustomPaint(
                painter: _NoisePainter(opacity: opacity, isDark: isDark),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoisePainter extends CustomPainter {
  final double opacity;
  final bool isDark;

  // CACHE MEMORY:
  // We declare these as static so they persist across repaints and widget rebuilds.
  // Calculating 8000 * 2 coordinates is mathematically heavy. By caching them,
  // we only calculate the random positions ONCE per screen size, rather than every single frame.
  static Float32List? _cachedPoints;
  static Size? _cachedSize;

  _NoisePainter({required this.opacity, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    // We only generate the point coordinates if it's the very first time rendering,
    // or if the user rotated their device / changed screen size.
    if (_cachedPoints == null || _cachedSize != size) {
      // Fixed seed (42) guarantees the grain pattern is deterministic and never shifts/flickers
      final random = Random(42);
      const numPoints = 8000;

      // Float32List is a highly optimized low-level data structure for C++/Skia engine communication.
      // It holds X and Y coordinates consecutively: [x1, y1, x2, y2, x3, y3...]
      _cachedPoints = Float32List(numPoints * 2);

      for (int i = 0; i < numPoints; i++) {
        _cachedPoints![i * 2] =
            random.nextDouble() * size.width; // Generate X coordinate
        _cachedPoints![i * 2 + 1] =
            random.nextDouble() * size.height; // Generate Y coordinate
      }
      _cachedSize = size;
    }

    // We create a single paint profile for the entire batch of points.
    // Previously, we calculated random alphas for every single dot inside the loop.
    // By combining them into one solid color with low opacity here, we achieve the exact
    // same visual film grain effect while saving thousands of math calculations per frame.
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(opacity)
      ..strokeWidth = 1.0;

    // PERFORMANCE LEAP: `drawRawPoints` is a hardware-accelerated method.
    // Instead of looping 8,000 times, it passes the entire Float32List directly to
    // the GPU in one single memory block. This is the exact code that cures the UI lag.
    canvas.drawRawPoints(PointMode.points, _cachedPoints!, paint);
  }

  @override
  bool shouldRepaint(_NoisePainter old) =>
      old.opacity != opacity || old.isDark != isDark; // Only repaint if theme/opacity changes
}
