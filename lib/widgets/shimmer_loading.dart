import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A shimmer/skeleton placeholder for a word list card.
class ShimmerWordCard extends StatelessWidget {
  const ShimmerWordCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// A shimmer placeholder list for word list screen.
class ShimmerWordList extends StatelessWidget {
  final int itemCount;
  const ShimmerWordList({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const ShimmerWordCard(),
    );
  }
}

/// A shimmer placeholder for dashboard profile summary card.
class ShimmerProfileCard extends StatelessWidget {
  const ShimmerProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: double.infinity,
        height: 160,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

/// A shimmer placeholder for dashboard stat cards row.
class ShimmerStatCards extends StatelessWidget {
  const ShimmerStatCards({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
