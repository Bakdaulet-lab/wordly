import 'package:flutter/material.dart';

/// Full-screen gradient simulating a gym floor / lifting platform.
class GymBackgroundWidget extends StatelessWidget {
  const GymBackgroundWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                  const Color(0xFF0F3460),
                ]
              : [
                  const Color(0xFFE8EAF6),
                  const Color(0xFFC5CAE9),
                  const Color(0xFF9FA8DA),
                ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _GymFloorPainter(isDark: isDark),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Paints subtle gym-floor lines for atmosphere.
class _GymFloorPainter extends CustomPainter {
  final bool isDark;
  _GymFloorPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04)
      ..strokeWidth = 1;

    // Horizontal floor lines in bottom third
    final floorTop = size.height * 0.65;
    for (double y = floorTop; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GymFloorPainter old) => old.isDark != isDark;
}
