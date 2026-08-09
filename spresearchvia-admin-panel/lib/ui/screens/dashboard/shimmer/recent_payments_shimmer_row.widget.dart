import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'shimmer_box.widget.dart';

class RecentPaymentsShimmerRow extends StatelessWidget {
  const RecentPaymentsShimmerRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Shimmer.fromColors(
        baseColor: AppTheme.gray100,
        highlightColor: AppTheme.gray50,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.gray100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              ShimmerBox(
                width: MediaQuery.of(context).size.width * 0.15,
                height: 16,
              ),
              ShimmerBox(
                width: MediaQuery.of(context).size.width * 0.15,
                height: 16,
              ),
              ShimmerBox(
                width: MediaQuery.of(context).size.width * 0.11,
                height: 16,
              ),
              ShimmerBox(
                width: MediaQuery.of(context).size.width * 0.11,
                height: 16,
              ),
              ShimmerBox(
                width: MediaQuery.of(context).size.width * 0.13,
                height: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
