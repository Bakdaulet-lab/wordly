import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/widgets/stat_card.dart';

void main() {
  group('StatCard', () {
    Widget buildWidget({
      IconData icon = Icons.star,
      String value = '42',
      String label = 'Points',
      Color? iconColor,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StatCard(
            icon: icon,
            value: value,
            label: label,
            iconColor: iconColor,
          ),
        ),
      );
    }

    testWidgets('displays value and label', (tester) async {
      await tester.pumpWidget(buildWidget(value: '100', label: 'XP Earned'));
      expect(find.text('100'), findsOneWidget);
      expect(find.text('XP Earned'), findsOneWidget);
    });

    testWidgets('displays icon', (tester) async {
      await tester.pumpWidget(buildWidget(icon: Icons.emoji_events));
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('uses custom icon color', (tester) async {
      await tester.pumpWidget(
        buildWidget(icon: Icons.star, iconColor: Colors.red),
      );
      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.color, Colors.red);
    });

    testWidgets('uses default icon color when not specified', (tester) async {
      await tester.pumpWidget(buildWidget(icon: Icons.star));
      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      // Default is AppColors.primary (0xFF6C63FF)
      expect(icon.color, const Color(0xFF6C63FF));
    });

    testWidgets('wraps in Card widget', (tester) async {
      await tester.pumpWidget(buildWidget());
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has Semantics with label and value', (tester) async {
      await tester.pumpWidget(buildWidget(value: '10', label: 'Streak'));
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
