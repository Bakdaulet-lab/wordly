import 'package:flutter_test/flutter_test.dart';
import 'package:wordly/utils/response_validator.dart';
import 'package:wordly/utils/result.dart';

void main() {
  group('ResponseValidator', () {
    group('validateList', () {
      test('succeeds with a valid list of maps', () {
        final response = [
          {'id': 1, 'name': 'apple'},
          {'id': 2, 'name': 'banana'},
        ];

        final result = ResponseValidator.validateList(response);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, hasLength(2));
        expect(result.dataOrNull!.first['name'], 'apple');
      });

      test('succeeds with an empty list', () {
        final result = ResponseValidator.validateList([]);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isEmpty);
      });

      test('fails when response is not a list', () {
        final result = ResponseValidator.validateList('not a list');
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull!.type, AppExceptionType.validation);
      });

      test('fails when response is null', () {
        final result = ResponseValidator.validateList(null);
        expect(result.isFailure, isTrue);
      });

      test('fails when response is a map instead of list', () {
        final result = ResponseValidator.validateList({'key': 'value'});
        expect(result.isFailure, isTrue);
        expect(result.errorOrNull!.message, contains('Expected list'));
      });

      test('includes context in error message', () {
        final result = ResponseValidator.validateList(
          42,
          context: 'fetchWords',
        );
        expect(result.errorOrNull!.message, contains('fetchWords'));
      });
    });

    group('validateSingleRow', () {
      test('returns first row from non-empty list', () {
        final response = [
          {'id': 1, 'name': 'alice'},
          {'id': 2, 'name': 'bob'},
        ];

        final result = ResponseValidator.validateSingleRow(response);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!['name'], 'alice');
      });

      test('returns null for empty list', () {
        final result = ResponseValidator.validateSingleRow([]);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });

      test('handles direct map response', () {
        final response = {'id': 1, 'name': 'alice'};
        final result = ResponseValidator.validateSingleRow(response);
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!['id'], 1);
      });

      test('fails for non-list non-map', () {
        final result = ResponseValidator.validateSingleRow(42);
        expect(result.isFailure, isTrue);
      });

      test('fails when list item is not a map', () {
        final result = ResponseValidator.validateSingleRow(['not a map']);
        expect(result.isFailure, isTrue);
      });
    });

    group('validateMap', () {
      test('succeeds with Map<String, dynamic>', () {
        final result = ResponseValidator.validateMap({'id': 1, 'name': 'a'});
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!['id'], 1);
      });

      test('fails with non-map input', () {
        final result = ResponseValidator.validateMap([1, 2, 3]);
        expect(result.isFailure, isTrue);
      });

      test('fails with string input', () {
        final result = ResponseValidator.validateMap('hello');
        expect(result.isFailure, isTrue);
      });
    });

    group('validateAndMapList', () {
      test('parses list of maps using fromJson', () {
        final response = [
          {'value': 10},
          {'value': 20},
        ];

        final result = ResponseValidator.validateAndMapList(
          response,
          (json) => json['value'] as int,
          context: 'test',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, [10, 20]);
      });

      test('fails when fromJson throws', () {
        final response = [
          {'value': 'not_an_int'},
        ];

        final result = ResponseValidator.validateAndMapList(
          response,
          (json) => json['missing_key'] as int, // will throw
          context: 'test',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull!.type, AppExceptionType.validation);
      });

      test('fails when response is not a list', () {
        final result = ResponseValidator.validateAndMapList(
          'invalid',
          (json) => json,
          context: 'test',
        );

        expect(result.isFailure, isTrue);
      });
    });

    group('validateAndMapSingleRow', () {
      test('parses first row using fromJson', () {
        final response = [
          {'id': 1, 'name': 'alice'},
        ];

        final result = ResponseValidator.validateAndMapSingleRow(
          response,
          (json) => json['name'] as String,
          context: 'test',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, 'alice');
      });

      test('returns null for empty list', () {
        final result = ResponseValidator.validateAndMapSingleRow(
          [],
          (json) => json['name'] as String,
          context: 'test',
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });

      test('fails when fromJson throws', () {
        final response = [
          {'id': 1},
        ];

        final result = ResponseValidator.validateAndMapSingleRow(
          response,
          (json) => json['missing'] as String, // will throw
          context: 'test',
        );

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull!.type, AppExceptionType.validation);
      });
    });
  });
}
