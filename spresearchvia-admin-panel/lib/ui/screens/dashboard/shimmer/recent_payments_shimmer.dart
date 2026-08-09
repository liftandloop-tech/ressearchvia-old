import 'package:flutter/material.dart';
import 'recent_payments_shimmer_row.widget.dart';

class RecentPaymentsShimmer extends StatelessWidget {
  const RecentPaymentsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (index) => const RecentPaymentsShimmerRow()),
    );
  }
}
