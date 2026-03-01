import 'package:flutter/material.dart';

/// A 2D barbell with weight plates drawn via CustomPaint.
///
/// [weight] is displayed as a label on the centre bar.
/// The widget itself does not handle positioning — the parent
/// wraps it in an animated container that moves it vertically.
class BarbellWidget extends StatelessWidget {
  final int weight;
  final bool isShaking;

  const BarbellWidget({
    super.key,
    required this.weight,
    this.isShaking = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget barbell = SizedBox(
      width: 220,
      height: 48,
      child: CustomPaint(
        painter: _BarbellPainter(
          isDark: isDark,
          weight: weight,
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$weight kg',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );

    if (isShaking) {
      barbell = TweenAnimationBuilder<double>(
        tween: Tween(begin: -4.0, end: 0.0),
        duration: const Duration(milliseconds: 400),
        curve: Curves.elasticOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(value, 0),
            child: child,
          );
        },
        child: barbell,
      );
    }

    return barbell;
  }
}

class _BarbellPainter extends CustomPainter {
  final bool isDark;
  final int weight;

  _BarbellPainter({required this.isDark, required this.weight});

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final barColor = isDark ? const Color(0xFFB0B0C0) : const Color(0xFF6D6D80);
    final plateColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFFCFB53B);
    final plateDark = isDark ? const Color(0xFF8B7500) : const Color(0xFF8B7500);

    // ── Main bar ──
    final barPaint = Paint()..color = barColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(size.width / 2, cy), width: size.width * 0.85, height: 6),
        const Radius.circular(3),
      ),
      barPaint,
    );

    // ── Weight plates ──
    // Number of plates per side scales with weight
    final plateSets = ((weight - 20) / 20).clamp(1, 4).toInt();
    const plateWidth = 10.0;
    final plateHeight = 28.0 + plateSets * 3;

    for (int side = -1; side <= 1; side += 2) {
      for (int i = 0; i < plateSets; i++) {
        final offset = side * (size.width * 0.38 + i * (plateWidth + 2));
        final paint = Paint()..color = i.isEven ? plateColor : plateDark;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(size.width / 2 + offset, cy),
              width: plateWidth,
              height: plateHeight,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
    }

    // ── Bar collars ──
    final collarPaint = Paint()..color = barColor.withValues(alpha: 0.7);
    for (int side = -1; side <= 1; side += 2) {
      canvas.drawCircle(
        Offset(size.width / 2 + side * size.width * 0.42, cy),
        5,
        collarPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarbellPainter old) =>
      old.isDark != isDark || old.weight != weight;
}
