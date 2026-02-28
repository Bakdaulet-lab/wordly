import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/widgets/quiz_option_button.dart';
import 'package:wordly/models/quiz_option_model.dart';

void main() {
  group('QuizOptionButton', () {
    Widget buildWidget({
      required QuizOptionModel option,
      int index = 0,
      int? selectedIndex,
      bool isAnswered = false,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: QuizOptionButton(
            option: option,
            index: index,
            selectedIndex: selectedIndex,
            isAnswered: isAnswered,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('displays option text', (tester) async {
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Кошка',
        isCorrect: false,
      );
      await tester.pumpWidget(buildWidget(option: option));
      expect(find.text('Кошка'), findsOneWidget);
    });

    testWidgets('displays option letter (A, B, C, D)', (tester) async {
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Test',
        isCorrect: false,
      );

      await tester.pumpWidget(buildWidget(option: option, index: 0));
      expect(find.text('A'), findsOneWidget);

      await tester.pumpWidget(buildWidget(option: option, index: 2));
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('fires onTap when not answered', (tester) async {
      bool tapped = false;
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Test',
        isCorrect: false,
      );
      await tester.pumpWidget(
        buildWidget(option: option, onTap: () => tapped = true),
      );
      await tester.tap(find.text('Test'));
      expect(tapped, isTrue);
    });

    testWidgets('does not fire onTap when answered', (tester) async {
      bool tapped = false;
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Test',
        isCorrect: false,
      );
      await tester.pumpWidget(
        buildWidget(
          option: option,
          isAnswered: true,
          onTap: () => tapped = true,
        ),
      );
      await tester.tap(find.text('Test'));
      expect(tapped, isFalse);
    });

    testWidgets('shows check icon for correct answer when answered',
        (tester) async {
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Correct',
        isCorrect: true,
      );
      await tester.pumpWidget(
        buildWidget(
          option: option,
          isAnswered: true,
          selectedIndex: 0,
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows cancel icon for incorrect selected answer',
        (tester) async {
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Wrong',
        isCorrect: false,
      );
      await tester.pumpWidget(
        buildWidget(
          option: option,
          index: 0,
          isAnswered: true,
          selectedIndex: 0,
        ),
      );
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('no icon for non-selected incorrect option when answered',
        (tester) async {
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Other',
        isCorrect: false,
      );
      await tester.pumpWidget(
        buildWidget(
          option: option,
          index: 1,
          isAnswered: true,
          selectedIndex: 0,
        ),
      );
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });

    testWidgets('has Semantics wrapper', (tester) async {
      const option = QuizOptionModel(
        wordId: 1,
        text: 'Test option',
        isCorrect: false,
      );
      await tester.pumpWidget(buildWidget(option: option));
      expect(find.byType(Semantics), findsWidgets);
    });
  });
}
