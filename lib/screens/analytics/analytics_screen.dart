import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_text_styles.dart';
import '../../constants/app_theme.dart';
import '../../di/service_locator.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/word_list_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/error_message.dart';
import '../../widgets/loading_indicator.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    await context.read<AnalyticsProvider>().loadAnalytics(userId);
  }

  Future<void> _handleExport(String type) async {
    final exportService = sl<ExportService>();
    try {
      switch (type) {
        case 'stats_csv':
          final provider = context.read<AnalyticsProvider>();
          await exportService.exportStats(provider.filteredStats);
        case 'words_json':
          final words = context.read<WordListProvider>().allWords;
          await exportService.exportWordsJson(words);
        case 'words_csv':
          final words = context.read<WordListProvider>().allWords;
          await exportService.exportWords(words);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      appBar: AppBar(
        title: const Text('Analytics', style: AppTextStyles.heading3),
        backgroundColor: AppTheme.surface(context),
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.file_download_outlined, color: AppTheme.textPrimary(context)),
            tooltip: 'Export data',
            onSelected: (value) => _handleExport(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'stats_csv',
                child: Row(
                  children: [
                    Icon(Icons.table_chart_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export Stats (CSV)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'words_json',
                child: Row(
                  children: [
                    Icon(Icons.data_object_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export Words (JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'words_csv',
                child: Row(
                  children: [
                    Icon(Icons.list_alt_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Export Words (CSV)'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }
          if (provider.errorMessage != null) {
            return Center(
              child: ErrorMessage(
                message: provider.errorMessage!,
                onRetry: _loadData,
              ),
            );
          }

          return RefreshIndicator(
            color: Theme.of(context).colorScheme.primary,
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(provider),
                  const SizedBox(height: 20),
                  _buildSummaryCards(provider.summary),
                  const SizedBox(height: 24),
                  _buildXpLineChart(provider),
                  const SizedBox(height: 24),
                  _buildAccuracyChart(provider),
                  const SizedBox(height: 24),
                  _buildWordsBarChart(provider),
                  const SizedBox(height: 24),
                  _buildActivityPieChart(provider.summary),
                  const SizedBox(height: 24),
                  _buildStudyStreakInfo(provider.summary),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Period Selector ────────────────────────────────────────────────

  Widget _buildPeriodSelector(AnalyticsProvider provider) {
    return Row(
      children: AnalyticsPeriod.values.map((period) {
        final isSelected = provider.selectedPeriod == period;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                period.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) => provider.setPeriod(period),
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: AppTheme.surface(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Summary Cards ─────────────────────────────────────────────────

  Widget _buildSummaryCards(AnalyticsSummary summary) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                icon: Icons.star_rounded,
                iconColor: AppTheme.xpGold,
                value: '${summary.totalXp}',
                label: 'Total XP',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                icon: Icons.track_changes_rounded,
                iconColor: AppTheme.successGreen,
                value: '${(summary.averageAccuracy * 100).toInt()}%',
                label: 'Avg Accuracy',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _summaryCard(
                icon: Icons.menu_book_rounded,
                iconColor: Theme.of(context).colorScheme.primary,
                value: '${summary.totalWordsReviewed}',
                label: 'Words Reviewed',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _summaryCard(
                icon: Icons.calendar_today_rounded,
                iconColor: AppTheme.streakOrange,
                value: '${summary.activeDays}',
                label: 'Active Days',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: AppTextStyles.heading3
                        .copyWith(fontSize: 20),),
                const SizedBox(height: 2),
                Text(label, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── XP Line Chart ─────────────────────────────────────────────────

  Widget _buildXpLineChart(AnalyticsProvider provider) {
    final data = provider.xpChartData;
    if (data.isEmpty) return const SizedBox.shrink();

    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxY > 0 ? maxY * 1.2 : 100.0;

    return _chartContainer(
      title: 'XP Earned',
      subtitle: _buildChartSubtitle(data),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: effectiveMax / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            titlesData: _buildTitlesData(data, effectiveMax),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: effectiveMax,
            lineBarsData: [
              _lineBarData(
                data,
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  return LineTooltipItem(
                    '${spot.y.toInt()} XP',
                    AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Accuracy Line Chart ───────────────────────────────────────────

  Widget _buildAccuracyChart(AnalyticsProvider provider) {
    final data = provider.accuracyChartData;
    if (data.isEmpty) return const SizedBox.shrink();

    return _chartContainer(
      title: 'Accuracy Trend',
      subtitle: 'Correct answer rate per day',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 0.25,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            titlesData: _buildTitlesData(data, 1.0, isPercentage: true),
            borderData: FlBorderData(show: false),
            minY: 0,
            maxY: 1.05,
            lineBarsData: [
              _lineBarData(
                data,
                AppTheme.successGreen,
                AppTheme.successGreen.withValues(alpha: 0.12),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((spot) {
                  return LineTooltipItem(
                    '${(spot.y * 100).toInt()}%',
                    AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Words Bar Chart ───────────────────────────────────────────────

  Widget _buildWordsBarChart(AnalyticsProvider provider) {
    final reviewed = provider.wordsReviewedChartData;
    final learned = provider.wordsLearnedChartData;
    if (reviewed.isEmpty) return const SizedBox.shrink();

    final allValues = [
      ...reviewed.map((d) => d.value),
      ...learned.map((d) => d.value),
    ];
    final maxY =
        allValues.isEmpty ? 10.0 : allValues.reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxY > 0 ? maxY * 1.3 : 10.0;

    return _chartContainer(
      title: 'Word Activity',
      subtitle: 'Reviews and new words per day',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: effectiveMax,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: effectiveMax / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  getTitlesWidget: (value, _) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: AppTextStyles.caption.copyWith(fontSize: 10),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= reviewed.length) {
                      return const SizedBox.shrink();
                    }
                    // Show limited labels to avoid overlap
                    final step = _labelStep(reviewed.length);
                    if (index % step != 0 && index != reviewed.length - 1) {
                      return const SizedBox.shrink();
                    }
                    final date = reviewed[index].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${date.day}/${date.month}',
                        style: AppTextStyles.caption.copyWith(fontSize: 9),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(reviewed.length, (i) {
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: reviewed[i].value,
                    color: Theme.of(context).colorScheme.primary,
                    width: reviewed.length > 14 ? 4 : 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                  BarChartRodData(
                    toY: learned[i].value,
                    color: AppTheme.xpGold,
                    width: reviewed.length > 14 ? 4 : 8,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(3),
                    ),
                  ),
                ],
              );
            }),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final label = rodIndex == 0 ? 'Reviewed' : 'Learned';
                  return BarTooltipItem(
                    '$label: ${rod.toY.toInt()}',
                    AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      legendItems: [
        _legendItem(Theme.of(context).colorScheme.primary, 'Reviewed'),
        _legendItem(AppTheme.xpGold, 'Learned'),
      ],
    );
  }

  // ─── Activity Pie Chart ────────────────────────────────────────────

  Widget _buildActivityPieChart(AnalyticsSummary summary) {
    final correct = summary.totalCorrect;
    final incorrect = summary.totalIncorrect;
    final total = correct + incorrect;
    if (total == 0) {
      return _chartContainer(
        title: 'Answer Breakdown',
        subtitle: 'No answers recorded yet',
        child: const SizedBox(
          height: 180,
          child: Center(
            child: Text('Complete some quizzes to see your breakdown'),
          ),
        ),
      );
    }

    return _chartContainer(
      title: 'Answer Breakdown',
      subtitle: '$total total answers',
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sectionsSpace: 3,
                  centerSpaceRadius: 40,
                  sections: [
                    PieChartSectionData(
                      value: correct.toDouble(),
                      color: AppTheme.successGreen,
                      title: '${(correct / total * 100).toInt()}%',
                      titleStyle: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      radius: 50,
                    ),
                    PieChartSectionData(
                      value: incorrect.toDouble(),
                      color: AppTheme.errorRed,
                      title: '${(incorrect / total * 100).toInt()}%',
                      titleStyle: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      radius: 50,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _legendItem(AppTheme.successGreen, 'Correct ($correct)'),
                const SizedBox(height: 8),
                _legendItem(AppTheme.errorRed, 'Incorrect ($incorrect)'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Study Streak Info ─────────────────────────────────────────────

  Widget _buildStudyStreakInfo(AnalyticsSummary summary) {
    final avgXpStr = summary.averageDailyXp.toStringAsFixed(1);
    final studyMinutes = (summary.totalStudySeconds / 60).round();
    final bestDate = summary.bestDayDate;
    final bestDateStr = bestDate != null
        ? '${bestDate.day}/${bestDate.month}/${bestDate.year}'
        : '—';

    return _chartContainer(
      title: 'Period Highlights',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            _highlightRow(
              Icons.trending_up_rounded,
              Theme.of(context).colorScheme.primary,
              'Avg Daily XP',
              '$avgXpStr XP',
            ),
            const Divider(height: 20),
            _highlightRow(
              Icons.emoji_events_rounded,
              AppTheme.xpGold,
              'Best Day',
              '${summary.bestDayXp} XP ($bestDateStr)',
            ),
            const Divider(height: 20),
            _highlightRow(
              Icons.timer_rounded,
              AppTheme.streakOrange,
              'Study Time',
              '$studyMinutes min',
            ),
            const Divider(height: 20),
            _highlightRow(
              Icons.school_rounded,
              AppTheme.successGreen,
              'Words Learned',
              '${summary.totalWordsLearned}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _highlightRow(
      IconData icon, Color color, String label, String value,) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMedium),
        ),
        Text(
          value,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  // ─── Chart Helpers ─────────────────────────────────────────────────

  Widget _chartContainer({
    required String title,
    String? subtitle,
    required Widget child,
    List<Widget>? legendItems,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card(context),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.heading3),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.caption),
                    ],
                  ],
                ),
              ),
              if (legendItems != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: legendItems
                      .expand((w) => [w, const SizedBox(width: 12)])
                      .toList()
                    ..removeLast(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 11)),
      ],
    );
  }

  LineChartBarData _lineBarData(
    List<ChartDataPoint> data,
    Color lineColor,
    Color areaColor,
  ) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
        (i) => FlSpot(i.toDouble(), data[i].value),
      ),
      isCurved: true,
      preventCurveOverShooting: true,
      color: lineColor,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: data.length <= 14,
        getDotPainter: (spot, percent, barData, index) =>
            FlDotCirclePainter(
          radius: 3,
          color: lineColor,
          strokeWidth: 1.5,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: areaColor,
      ),
    );
  }

  FlTitlesData _buildTitlesData(
    List<ChartDataPoint> data,
    double maxY, {
    bool isPercentage = false,
  }) {
    final step = _labelStep(data.length);
    return FlTitlesData(
      topTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles:
          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 36,
          interval: isPercentage ? 0.25 : null,
          getTitlesWidget: (value, _) {
            final text = isPercentage
                ? '${(value * 100).toInt()}%'
                : value.toInt().toString();
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                text,
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            );
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, _) {
            final index = value.toInt();
            if (index < 0 || index >= data.length) {
              return const SizedBox.shrink();
            }
            if (index % step != 0 && index != data.length - 1) {
              return const SizedBox.shrink();
            }
            final date = data[index].date;
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${date.day}/${date.month}',
                style: AppTextStyles.caption.copyWith(fontSize: 9),
              ),
            );
          },
        ),
      ),
    );
  }

  int _labelStep(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 14) return 2;
    return 5;
  }

  String _buildChartSubtitle(List<ChartDataPoint> data) {
    final total = data.fold<double>(0, (sum, d) => sum + d.value);
    return '${total.toInt()} XP total';
  }
}
