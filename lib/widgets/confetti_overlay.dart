import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

/// A reusable confetti overlay that can be triggered programmatically.
///
/// Wrap any screen / section with this widget and call
/// `ConfettiOverlay.of(context).play()` to fire confetti.
class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.child});

  final Widget child;

  /// Retrieves the nearest [ConfettiOverlayState] from the widget tree.
  static ConfettiOverlayState of(BuildContext context) {
    final state = context.findAncestorStateOfType<ConfettiOverlayState>();
    assert(state != null, 'No ConfettiOverlay found in context');
    return state!;
  }

  /// Safe variant that returns null if no overlay is present.
  static ConfettiOverlayState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ConfettiOverlayState>();
  }

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class ConfettiOverlayState extends State<ConfettiOverlay> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Fire a burst of confetti.
  void play() {
    _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _controller,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            numberOfParticles: 30,
            maxBlastForce: 30,
            minBlastForce: 10,
            emissionFrequency: 0.06,
            gravity: 0.2,
            colors: const [
              Color(0xFF6C63FF), // primary
              Color(0xFFFFD700), // gold
              Color(0xFFFF6B35), // orange
              Color(0xFF4CAF50), // green
              Color(0xFF9D97FF), // light primary
              Color(0xFFFF4081), // pink
            ],
            createParticlePath: _drawStar,
          ),
        ),
      ],
    );
  }

  /// Draws a small star-shaped particle.
  Path _drawStar(Size size) {
    final path = Path();
    final mid = size.width / 2;
    final min = size.width / 4;
    // Random shape variety
    final random = Random();
    if (random.nextBool()) {
      // Circle
      path.addOval(Rect.fromCircle(center: Offset(mid, mid), radius: mid));
    } else {
      // Star
      path.moveTo(mid, 0);
      path.lineTo(mid + min / 2, mid - min / 2);
      path.lineTo(size.width, mid);
      path.lineTo(mid + min / 2, mid + min / 2);
      path.lineTo(mid, size.height);
      path.lineTo(mid - min / 2, mid + min / 2);
      path.lineTo(0, mid);
      path.lineTo(mid - min / 2, mid - min / 2);
      path.close();
    }
    return path;
  }
}
