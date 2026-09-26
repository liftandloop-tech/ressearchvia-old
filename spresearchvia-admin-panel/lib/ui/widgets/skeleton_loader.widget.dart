import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spresearch_web/config/theme.config.dart';

/// Base Shimmer Wrapper with calibrated subtle enterprise tones
class AppShimmer extends StatelessWidget {
  final Widget child;

  const AppShimmer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE2E8F0), // Subtle slate-200
      highlightColor: const Color(0xFFF8FAFC), // Subtle slate-50
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

/// Generic Shimmer Box element
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 6,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Generic Shimmer Circle (e.g. Avatars, Icon Buttons)
class ShimmerCircle extends StatelessWidget {
  final double size;

  const ShimmerCircle({super.key, this.size = 36});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Reusable Table Skeleton mimicking real enterprise data tables
class TableSkeleton extends StatelessWidget {
  final int rowCount;
  final int columnCount;
  final double minWidth;
  final bool hasAvatarColumn;
  final bool showPaginationBar;
  final bool isExpanded;

  const TableSkeleton({
    super.key,
    this.rowCount = 7,
    this.columnCount = 6,
    this.minWidth = 850,
    this.hasAvatarColumn = true,
    this.showPaginationBar = true,
    this.isExpanded = false,
  });

  Widget _buildRow(int index) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(columnCount, (colIndex) {
          if (colIndex == 0) {
            // ID column
            return const Expanded(
              flex: 1,
              child: Padding(
                padding: EdgeInsets.only(right: 12),
                child: ShimmerBox(height: 14, width: 70),
              ),
            );
          } else if (hasAvatarColumn && colIndex == 1) {
            // Name + Avatar column
            return Expanded(
              flex: 2,
              child: Row(
                children: [
                  const ShimmerCircle(size: 30),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(height: 12, width: 110),
                      SizedBox(height: 6),
                      ShimmerBox(height: 10, width: 80),
                    ],
                  ),
                ],
              ),
            );
          } else if (colIndex == 2) {
            // Status Badge
            return const Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ShimmerBox(
                  height: 22,
                  width: 75,
                  borderRadius: 12,
                ),
              ),
            );
          } else {
            // Generic data cell
            return Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ShimmerBox(
                  height: 13,
                  width: (colIndex % 2 == 0) ? 90 : 65,
                ),
              ),
            );
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rowsWidget = isExpanded
        ? Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rowCount,
              separatorBuilder: (context, _) =>
                  const Divider(height: 1, color: AppTheme.gray100),
              itemBuilder: (context, index) => _buildRow(index),
            ),
          )
        : Column(
            children: List.generate(rowCount, (index) {
              return Column(
                children: [
                  _buildRow(index),
                  if (index < rowCount - 1)
                    const Divider(height: 1, color: AppTheme.gray100),
                ],
              );
            }),
          );

    return AppShimmer(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gray200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Header Row
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: AppTheme.gray50,
              child: Row(
                children: List.generate(
                  columnCount,
                  (index) => Expanded(
                    flex: (hasAvatarColumn && index == 1) ? 2 : 1,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ShimmerBox(
                        height: 14,
                        width: index == 0 ? 60 : (index == 1 ? 140 : 80),
                        borderRadius: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppTheme.gray200),

            // Skeleton Data Rows
            rowsWidget,

            // Bottom Pagination Skeleton
            if (showPaginationBar)
              Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppTheme.gray200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ShimmerBox(height: 14, width: 140),
                    Row(
                      children: const [
                        ShimmerBox(height: 28, width: 28, borderRadius: 4),
                        SizedBox(width: 6),
                        ShimmerBox(height: 28, width: 28, borderRadius: 4),
                        SizedBox(width: 6),
                        ShimmerBox(height: 28, width: 28, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Metrics Cards Skeleton (for Dashboard Sales Metrics)
class MetricsCardsSkeleton extends StatelessWidget {
  final int count;

  const MetricsCardsSkeleton({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 1000;
          final cardWidth = isDesktop
              ? (constraints.maxWidth - 40) / 3
              : (constraints.maxWidth > 600
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth);

          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: List.generate(
              count,
              (index) => Container(
                width: cardWidth,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.gray200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        ShimmerBox(height: 38, width: 38, borderRadius: 10),
                        ShimmerBox(height: 20, width: 50, borderRadius: 10),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const ShimmerBox(height: 14, width: 130),
                    const SizedBox(height: 10),
                    const ShimmerBox(height: 28, width: 110),
                    const SizedBox(height: 12),
                    const ShimmerBox(height: 11, width: 160),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Page Header Skeleton (Title + Subtitle + Action buttons)
class PageHeaderSkeleton extends StatelessWidget {
  const PageHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBox(height: 26, width: 220),
              SizedBox(height: 8),
              ShimmerBox(height: 14, width: 340),
            ],
          ),
          Row(
            children: const [
              ShimmerBox(height: 40, width: 40, borderRadius: 8),
              SizedBox(width: 12),
              ShimmerBox(height: 40, width: 120, borderRadius: 8),
            ],
          ),
        ],
      ),
    );
  }
}

/// Filter Bar Skeleton (Search field + Dropdowns)
class FilterBarSkeleton extends StatelessWidget {
  const FilterBarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: Row(
          children: const [
            Expanded(
              flex: 2,
              child: ShimmerBox(height: 40, borderRadius: 6),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: ShimmerBox(height: 40, borderRadius: 6),
            ),
            SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: ShimmerBox(height: 40, borderRadius: 6),
            ),
          ],
        ),
      ),
    );
  }
}

/// Complete Screen Skeleton combining Header, Filter Bar, and Table
class ScreenSkeleton extends StatelessWidget {
  final bool hasFilterBar;
  final int rowCount;

  const ScreenSkeleton({
    super.key,
    this.hasFilterBar = true,
    this.rowCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.gray50,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeaderSkeleton(),
          const SizedBox(height: 20),
          if (hasFilterBar) ...[
            const FilterBarSkeleton(),
            const SizedBox(height: 16),
          ],
          Expanded(child: TableSkeleton(rowCount: rowCount)),
        ],
      ),
    );
  }
}
