import 'dart:math';

/// Computes the Levenshtein edit distance between two strings.
///
/// The edit distance is the minimum number of single-character insertions,
/// deletions, or substitutions required to transform [a] into [b].
int levenshteinDistance(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Use two single-row arrays for O(min(m,n)) space complexity.
  final aLen = a.length;
  final bLen = b.length;

  var previousRow = List<int>.generate(bLen + 1, (i) => i);
  var currentRow = List<int>.filled(bLen + 1, 0);

  for (var i = 1; i <= aLen; i++) {
    currentRow[0] = i;
    for (var j = 1; j <= bLen; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      currentRow[j] = [
        currentRow[j - 1] + 1, // insertion
        previousRow[j] + 1, // deletion
        previousRow[j - 1] + cost, // substitution
      ].reduce(min);
    }
    // Swap rows
    final temp = previousRow;
    previousRow = currentRow;
    currentRow = temp;
  }

  return previousRow[bLen];
}

/// Returns `true` if [answer] is close enough to [correct] to be accepted.
///
/// For words longer than 4 characters, allows a Levenshtein distance of up to
/// `max(1, correct.length ~/ 5)` (roughly 1 typo per 5 characters).
/// For words of 4 characters or fewer, exact match is required.
bool isTypingAnswerAccepted(String answer, String correct) {
  final a = answer.trim().toLowerCase();
  final c = correct.trim().toLowerCase();

  if (a == c) return true;

  // Exact match required for short words
  if (c.length <= 4) return false;

  final maxDistance = (c.length / 5).ceil().clamp(1, 3);
  return levenshteinDistance(a, c) <= maxDistance;
}
