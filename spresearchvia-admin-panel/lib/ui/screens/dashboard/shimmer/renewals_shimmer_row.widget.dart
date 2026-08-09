import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'shimmer_box.widget.dart';

class RenewalsShimmerRow extends StatelessWidget {
  const RenewalsShimmerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border(bottom: BorderSide(color: AppTheme.gray200)),
      ),
      child: Shimmer.fromColors(
        baseColor: AppTheme.gray100,
        highlightColor: AppTheme.gray50,
        child: Row(
          children: [
            Expanded(flex: 17, child: const ShimmerBox(width: 120, height: 16)),
            Expanded(flex: 20, child: const ShimmerBox(width: 150, height: 16)),
            Expanded(flex: 15, child: const ShimmerBox(width: 100, height: 16)),
            Expanded(flex: 12, child: const ShimmerBox(width: 80, height: 24)),
            Expanded(flex: 18, child: const ShimmerBox(width: 100, height: 16)),
            Expanded(flex: 18, child: const ShimmerBox(width: 120, height: 36)),
          ],
        ),
      ),
    );
  }
}
