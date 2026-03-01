import 'package:flutter/material.dart';

/// A simple 2D stick-figure / block character doing a bench press.
///
/// [muscleScale] grows slightly with each successful rep (1.0 → ~1.15)
/// to visually represent "gaining muscle mass".
class CharacterWidget extends StatelessWidget {
  final double muscleScale;

  const CharacterWidget({super.key, this.muscleScale = 1.0});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skinColor = isDark
        ? const Color(0xFFD4A574)
        : const Color(0xFFE8B88A);
    final shirtColor = isDark
        ? const Color(0xFF4A42DB)
        : const Color(0xFF6C63FF);
    final shortsColor = isDark
        ? const Color(0xFF2D2D44)
        : const Color(0xFF3D3D5C);
    final benchColor = isDark
        ? const Color(0xFF4A4A5E)
        : const Color(0xFF8D8D9B);

    return AnimatedScale(
      scale: muscleScale.clamp(1.0, 1.2),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: SizedBox(
        width: 160,
        height: 120,
        child: CustomPaint(
          painter: _CharacterPainter(
            skinColor: skinColor,
            shirtColor: shirtColor,
            shortsColor: shortsColor,
            benchColor: benchColor,
          ),
        ),
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final Color skinColor;
  final Color shirtColor;
  final Color shortsColor;
  final Color benchColor;

  _CharacterPainter({
    required this.skinColor,
    required this.shirtColor,
    required this.shortsColor,
    required this.benchColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final benchY = size.height * 0.7;

    // ── Bench ──
    final benchPaint = Paint()..color = benchColor;
    // Bench top (horizontal surface)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, benchY),
          width: size.width * 0.75,
          height: 8,
        ),
        const Radius.circular(2),
      ),
      benchPaint,
    );
    // Bench legs
    final legPaint = Paint()
      ..color = benchColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - size.width * 0.3, benchY + 4),
      Offset(cx - size.width * 0.3, size.height),
      legPaint,
    );
    canvas.drawLine(
      Offset(cx + size.width * 0.3, benchY + 4),
      Offset(cx + size.width * 0.3, size.height),
      legPaint,
    );

    // ── Body (lying on bench) ──
    final bodyPaint = Paint()..color = shirtColor;
    // Torso
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, benchY - 12),
          width: 40,
          height: 20,
        ),
        const Radius.circular(6),
      ),
      bodyPaint,
    );

    // Shorts/legs
    final shortsPaint = Paint()..color = shortsColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + 28, benchY - 10),
          width: 22,
          height: 14,
        ),
        const Radius.circular(4),
      ),
      shortsPaint,
    );

    // ── Head ──
    final headPaint = Paint()..color = skinColor;
    canvas.drawCircle(Offset(cx - 30, benchY - 16), 10, headPaint);

    // Eyes
    final eyePaint = Paint()..color = Colors.black87;
    canvas.drawCircle(Offset(cx - 33, benchY - 18), 1.5, eyePaint);
    canvas.drawCircle(Offset(cx - 27, benchY - 18), 1.5, eyePaint);

    // ── Arms (reaching up to hold barbell) ──
    final armPaint = Paint()
      ..color = skinColor
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    // Left arm
    canvas.drawLine(
      Offset(cx - 14, benchY - 16),
      Offset(cx - 20, benchY - 45),
      armPaint,
    );
    // Right arm
    canvas.drawLine(
      Offset(cx + 14, benchY - 16),
      Offset(cx + 20, benchY - 45),
      armPaint,
    );

    // Hands (small circles at arm tips)
    canvas.drawCircle(Offset(cx - 20, benchY - 45), 4, headPaint);
    canvas.drawCircle(Offset(cx + 20, benchY - 45), 4, headPaint);
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter old) =>
      old.skinColor != skinColor ||
      old.shirtColor != shirtColor;
}
