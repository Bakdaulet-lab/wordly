import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../models/word_model.dart';
import '../models/user_word_progress_model.dart';
import '../models/daily_stats_model.dart';

/// Service that exports user data in CSV format via the system share sheet.
class ExportService {
  /// Export word list as CSV.
  Future<void> exportWords(List<WordModel> words) async {
    final buffer = StringBuffer();
    buffer.writeln('ID,English Word,Russian Translation,Category,Difficulty,Example');
    for (final w in words) {
      buffer.writeln(
        '${w.id},'
        '${_escapeCsv(w.englishWord)},'
        '${_escapeCsv(w.russianTranslation)},'
        '${_escapeCsv(w.category)},'
        '${w.difficultyLevel},'
        '${_escapeCsv(w.exampleSentence ?? '')}',
      );
    }
    await _share(buffer.toString(), 'wordly_words.csv');
  }

  /// Export user word progress as CSV.
  Future<void> exportProgress(
    List<UserWordProgressModel> progressList,
    List<WordModel> words,
  ) async {
    // Build a word lookup map
    final wordMap = {for (final w in words) w.id: w};

    final buffer = StringBuffer();
    buffer.writeln(
      'Word ID,English Word,Russian Translation,'
      'Ease Factor,Interval Days,Repetition Count,'
      'Next Review Date,Last Review Date,'
      'Correct Count,Incorrect Count,Accuracy %',
    );

    for (final p in progressList) {
      final word = wordMap[p.wordId];
      final total = p.correctCount + p.incorrectCount;
      final accuracy = total > 0 ? (p.correctCount / total * 100).toStringAsFixed(1) : 'N/A';

      buffer.writeln(
        '${p.wordId},'
        '${_escapeCsv(word?.englishWord ?? 'Unknown')},'
        '${_escapeCsv(word?.russianTranslation ?? '')},'
        '${p.easeFactor.toStringAsFixed(2)},'
        '${p.intervalDays},'
        '${p.repetitionCount},'
        '${p.nextReviewDate.toIso8601String().split('T')[0]},'
        '${p.lastReviewDate?.toIso8601String().split('T')[0] ?? ''},'
        '${p.correctCount},'
        '${p.incorrectCount},'
        '$accuracy',
      );
    }
    await _share(buffer.toString(), 'wordly_progress.csv');
  }

  /// Export daily stats as CSV.
  Future<void> exportStats(List<DailyStatsModel> stats) async {
    final buffer = StringBuffer();
    buffer.writeln(
      'Date,Words Learned,Words Reviewed,'
      'Correct Answers,Incorrect Answers,'
      'XP Earned,Session Duration (seconds)',
    );

    for (final s in stats) {
      buffer.writeln(
        '${s.date.toIso8601String().split('T')[0]},'
        '${s.wordsLearned},'
        '${s.wordsReviewed},'
        '${s.correctAnswers},'
        '${s.incorrectAnswers},'
        '${s.xpEarned},'
        '${s.sessionDurationSeconds}',
      );
    }
    await _share(buffer.toString(), 'wordly_stats.csv');
  }

  /// Export a combined summary of all user data.
  Future<void> exportAll({
    required List<WordModel> words,
    required List<UserWordProgressModel> progress,
    required List<DailyStatsModel> stats,
    required String displayName,
    required int level,
    required int totalXp,
  }) async {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Wordly Export');
    buffer.writeln('User: $displayName');
    buffer.writeln('Level: $level | Total XP: $totalXp');
    buffer.writeln('Exported: ${DateTime.now().toIso8601String().split('T')[0]}');
    buffer.writeln('');

    // Words summary
    buffer.writeln('=== WORD LIST (${words.length} words) ===');
    buffer.writeln('English,Russian,Category,Difficulty');
    for (final w in words) {
      buffer.writeln(
        '${_escapeCsv(w.englishWord)},'
        '${_escapeCsv(w.russianTranslation)},'
        '${_escapeCsv(w.category)},'
        '${w.difficultyLevel}',
      );
    }
    buffer.writeln('');

    // Progress summary
    final wordMap = {for (final w in words) w.id: w};
    buffer.writeln('=== PROGRESS (${progress.length} entries) ===');
    buffer.writeln('Word,Correct,Incorrect,Next Review');
    for (final p in progress) {
      final word = wordMap[p.wordId];
      buffer.writeln(
        '${_escapeCsv(word?.englishWord ?? '?')},'
        '${p.correctCount},'
        '${p.incorrectCount},'
        '${p.nextReviewDate.toIso8601String().split('T')[0]}',
      );
    }
    buffer.writeln('');

    // Stats summary
    buffer.writeln('=== DAILY STATS (${stats.length} days) ===');
    buffer.writeln('Date,Reviewed,Correct,XP');
    for (final s in stats) {
      buffer.writeln(
        '${s.date.toIso8601String().split('T')[0]},'
        '${s.wordsReviewed},'
        '${s.correctAnswers},'
        '${s.xpEarned}',
      );
    }

    await _share(buffer.toString(), 'wordly_export.csv');
  }

  /// Share content via the system share sheet.
  Future<void> _share(String content, String filename) async {
    try {
      await Share.share(
        content,
        subject: filename,
      );
    } catch (e) {
      debugPrint('[ExportService] Share failed: $e');
      rethrow;
    }
  }

  /// Escape a value for safe inclusion in CSV.
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}
