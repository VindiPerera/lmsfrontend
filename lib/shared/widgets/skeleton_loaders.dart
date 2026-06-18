import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lms/core/providers/theme_provider.dart';

/// Skeleton loader for lecture cards (horizontal scrolling)
class SkeletonLectureCard extends StatelessWidget {
  const SkeletonLectureCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDark
        ? const Color(0xFF2A1F45)
        : const Color(0xFFE8E0F0);
    final highlightColor = isDark
        ? const Color(0xFF3D2D5C)
        : const Color(0xFFF5F0FF);
    final shapeColor = isDark
        ? const Color(0xFF2A1F45)
        : const Color(0xFFE0D4F0);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: shapeColor,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 150,
              decoration: BoxDecoration(
                color: shapeColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 20,
                  width: 60,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                Container(
                  height: 14,
                  width: 40,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: 24,
                  width: 50,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 35,
                  width: 100,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for category stat cards
class SkeletonCategoryCard extends StatelessWidget {
  const SkeletonCategoryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDark
        ? const Color(0xFF2A1F45)
        : const Color(0xFFE8E0F0);
    final highlightColor = isDark
        ? const Color(0xFF3D2D5C)
        : const Color(0xFFF5F0FF);
    final shapeColor = isDark
        ? const Color(0xFF2A1F45)
        : const Color(0xFFE0D4F0);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: 235,
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 18,
              width: 130,
              decoration: BoxDecoration(
                color: shapeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(bottom: 12),
            ),
            Container(
              height: 42,
              width: 72,
              decoration: BoxDecoration(
                color: shapeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(bottom: 8),
            ),
            Container(
              height: 14,
              width: 90,
              decoration: BoxDecoration(
                color: shapeColor,
                borderRadius: BorderRadius.circular(4),
              ),
              margin: const EdgeInsets.only(bottom: 18),
            ),
            Row(
              children: [
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 13,
                  width: 105,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  height: 18,
                  width: 18,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  height: 13,
                  width: 120,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader for ongoing course cards (list view)
class SkeletonOngoingCard extends StatelessWidget {
  const SkeletonOngoingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final baseColor = isDark
        ? const Color(0xFF2A1F45)
        : const Color(0xFFE8E0F0);
    final highlightColor = isDark
        ? const Color(0xFF3D2D5C)
        : const Color(0xFFF5F0FF);
    final shapeColor = isDark
        ? const Color(0xFF2A1F45)
        : const Color(0xFFE0D4F0);
    final cardBg = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.white.withValues(alpha: 0.75);
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.9);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              height: 70,
              width: 100,
              decoration: BoxDecoration(
                color: shapeColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: shapeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(
                      color: shapeColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: shapeColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    margin: const EdgeInsets.only(bottom: 6),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                Container(
                  height: 10,
                  width: 40,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                ),
                Container(
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    color: shapeColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton loader list generators
class SkeletonLoaders {
  /// Generate list of skeleton lecture cards
  static List<Widget> lectureSkeletons(int count) {
    return List.generate(count, (index) => const SkeletonLectureCard());
  }

  /// Generate list of skeleton category cards
  static List<Widget> categorySkeletons(int count) {
    return List.generate(count, (index) => const SkeletonCategoryCard());
  }

  /// Generate list of skeleton ongoing cards
  static List<Widget> ongoingSkeletons(int count) {
    return List.generate(count, (index) => const SkeletonOngoingCard());
  }
}
