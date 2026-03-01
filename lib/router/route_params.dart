/// Typed route parameter classes for type-safe navigation.
///
/// Instead of passing raw strings and maps through the router,
/// screens receive validated, strongly-typed parameter objects.
library;

/// Parameters for the quiz route.
///
/// Currently the quiz screen doesn't require external arguments
/// (words are loaded from provider), but this class is ready to
/// accept optional overrides such as a specific category or count.
class QuizRouteParams {
  /// Optional category filter for the quiz.
  final String? category;

  /// Number of questions to include (defaults to provider constant).
  final int? questionCount;

  const QuizRouteParams({
    this.category,
    this.questionCount,
  });

  /// Construct from [GoRouterState.uri.queryParameters].
  factory QuizRouteParams.fromQueryParameters(Map<String, String> params) {
    return QuizRouteParams(
      category: params['category'],
      questionCount: params['count'] != null
          ? int.tryParse(params['count']!)
          : null,
    );
  }

  /// Serialize to query parameters for [GoRouter.go] / [GoRouter.push].
  Map<String, String> toQueryParameters() {
    return {
      if (category != null) 'category': category!,
      if (questionCount != null) 'count': questionCount.toString(),
    };
  }

  @override
  String toString() =>
      'QuizRouteParams(category: $category, questionCount: $questionCount)';
}

/// Parameters for the word detail route (`/words/:id`).
class WordDetailRouteParams {
  /// The word's primary key.
  final int wordId;

  const WordDetailRouteParams({required this.wordId});

  /// Construct from [GoRouterState.pathParameters].
  ///
  /// Returns `null` if the `id` parameter is missing or not a valid integer.
  static WordDetailRouteParams? fromPathParameters(
    Map<String, String> params,
  ) {
    final rawId = params['id'];
    if (rawId == null) return null;
    final parsed = int.tryParse(rawId);
    if (parsed == null) return null;
    return WordDetailRouteParams(wordId: parsed);
  }

  @override
  String toString() => 'WordDetailRouteParams(wordId: $wordId)';
}
