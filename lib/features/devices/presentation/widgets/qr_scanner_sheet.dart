// lib/features/devices/presentation/widgets/qr_scanner_sheet.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class QrScannerSheet extends StatelessWidget {
  const QrScannerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.rLg),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Handle for visual affordance
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.s24),
            child: Row(
              children: [
                Text(
                  'Scan Device QR',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.s24),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                child: Stack(
                  children: [
                    MobileScanner(
                      fit: BoxFit.cover,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty) {
                          final String? code = barcodes.first.rawValue;
                          if (code != null) {
                            Navigator.pop(context, code);
                          }
                        }
                      },
                    ),
                    // Standard Scanner Overlay
                    CustomPaint(
                      painter: ScannerOverlayPainter(),
                      child: const SizedBox.expand(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.s48),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final cutOutRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.7,
      height: size.width * 0.7,
    );

    // Draw darkened background with a hole
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(
          RRect.fromRectAndRadius(
            cutOutRect,
            const Radius.circular(AppTheme.rMd),
          ),
        ),
      ),
      paint,
    );

    // Draw amber corners
    final linePaint = Paint()
      ..color = AppTheme.amber
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    double cornerSize = 20;

    // Top Left
    path.moveTo(cutOutRect.left, cutOutRect.top + cornerSize);
    path.lineTo(cutOutRect.left, cutOutRect.top);
    path.lineTo(cutOutRect.left + cornerSize, cutOutRect.top);

    // Top Right
    path.moveTo(cutOutRect.right - cornerSize, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top);
    path.lineTo(cutOutRect.right, cutOutRect.top + cornerSize);

    // Bottom Right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - cornerSize);
    path.lineTo(cutOutRect.right, cutOutRect.bottom);
    path.lineTo(cutOutRect.right - cornerSize, cutOutRect.bottom);

    // Bottom Left
    path.moveTo(cutOutRect.left + cornerSize, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom);
    path.lineTo(cutOutRect.left, cutOutRect.bottom - cornerSize);

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
