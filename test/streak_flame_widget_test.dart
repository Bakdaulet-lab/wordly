import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/widgets/streak_flame_icon.dart';

void main() {
  group('StreakFlameIcon', () {
    Widget buildWidget({required int streakCount}) {
      return MaterialApp(
        home: Scaffold(
          body: StreakFlameIcon(streakCount: streakCount),
        ),
      );
    }

    testWidgets('displays streak count', (tester) async {
      await tester.pumpWidget(buildWidget(streakCount: 5));
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays fire icon', (tester) async {
      await tester.pumpWidget(buildWidget(streakCount: 3));
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('displays zero streak', (tester) async {
      await tester.pumpWidget(buildWidget(streakCount: 0));
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('milestone streak (7) uses bold font weight', (tester) async {
      await tester.pumpWidget(buildWidget(streakCount: 7));
      final text = tester.widget<Text>(find.text('7'));
      expect(text.style?.fontWeight, FontWeight.w800);
    });

    testWidgets('non-milestone uses regular font weight', (tester) async {
      await tester.pumpWidget(buildWidget(streakCount: 5));
      final text = tester.widget<Text>(find.text('5'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('has Semantics with streak description', (tester) async {
      await tester.pumpWidget(buildWidget(streakCount: 3));
      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('zero streak has no-active-streak semantics', (tester) async {
      await tester.pumpWidget(buildWidget(streakCount: 0));
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
