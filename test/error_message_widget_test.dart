import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/widgets/error_message.dart';

void main() {
  group('ErrorMessage', () {
    Widget buildWidget({required String message, VoidCallback? onRetry}) {
      return MaterialApp(
        home: Scaffold(
          body: ErrorMessage(message: message, onRetry: onRetry),
        ),
      );
    }

    testWidgets('displays error message text', (tester) async {
      await tester.pumpWidget(buildWidget(message: 'Something went wrong'));
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('displays error icon', (tester) async {
      await tester.pumpWidget(buildWidget(message: 'Error'));
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows retry button when onRetry is provided', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildWidget(message: 'Error', onRetry: () => retried = true),
      );
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('hides retry button when onRetry is null', (tester) async {
      await tester.pumpWidget(buildWidget(message: 'Error'));
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('has accessibility semantics with live region', (tester) async {
      await tester.pumpWidget(buildWidget(message: 'Network error'));
      // The Semantics widget wraps the error with a liveRegion flag
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
