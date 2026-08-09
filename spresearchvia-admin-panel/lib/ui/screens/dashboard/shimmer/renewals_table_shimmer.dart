import 'package:flutter/material.dart';
import 'renewals_shimmer_row.widget.dart';

class RenewalsTableShimmer extends StatelessWidget {
  const RenewalsTableShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(6, (index) => const RenewalsShimmerRow()),
    );
  }
}
