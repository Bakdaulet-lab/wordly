import 'package:flutter/material.dart';

/// Animates from `oldValue` to `value` using `TweenAnimationBuilder<int>`.
///
/// Pass an optional [suffix] (e.g. '%') appended after the number.
/// The [style] controls the text appearance.
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.suffix = '',
    this.prefix = '',
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.curve = Curves.easeOutCubic,
  });

  final int value;
  final String suffix;
  final String prefix;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, animatedValue, child) {
        return Text(
          '$prefix$animatedValue$suffix',
          style: style,
        );
      },
    );
  }
}
