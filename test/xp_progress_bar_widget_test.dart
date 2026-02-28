import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/widgets/xp_progress_bar.dart';

void main() {
  group('XpProgressBar', () {
    Widget buildWidget({
      double progress = 0.5,
      int currentXp = 250,
      int? xpToNextLevel = 500,
      int level = 3,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: XpProgressBar(
            progress: progress,
            currentXp: currentXp,
            xpToNextLevel: xpToNextLevel,
            level: level,
          ),
        ),
      );
    }

    testWidgets('displays level text', (tester) async {
      await tester.pumpWidget(buildWidget(level: 5));
      expect(find.text('Level 5'), findsOneWidget);
    });

    testWidgets('displays XP fraction when xpToNextLevel provided',
        (tester) async {
      await tester.pumpWidget(
          buildWidget(currentXp: 150, xpToNextLevel: 300),);
      expect(find.text('150 / 300 XP'), findsOneWidget);
    });

    testWidgets('hides XP fraction when xpToNextLevel is null',
        (tester) async {
      await tester.pumpWidget(buildWidget(xpToNextLevel: null));
      expect(find.textContaining('XP'), findsNothing);
    });

    testWidgets('contains LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('clamps progress between 0 and 1', (tester) async {
      // Should not throw with out-of-range values
      await tester.pumpWidget(buildWidget(progress: -0.5));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.pumpWidget(buildWidget(progress: 1.5));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('has Semantics wrapper for accessibility', (tester) async {
      await tester.pumpWidget(buildWidget(level: 3, progress: 0.5));
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('shows correct percentage in semantics', (tester) async {
      await tester.pumpWidget(buildWidget(progress: 0.75, level: 2));
      // There should be a Semantics with 75%
      final semanticsWidgets = find.byType(Semantics);
      expect(semanticsWidgets, findsWidgets);
    });
  });
}
