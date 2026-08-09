import 'package:flutter/material.dart';

class KycStepIndicator extends StatelessWidget {
  const KycStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
  });

  final int currentStep;
  final int totalSteps;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xff6B7280),
                  fontWeight: FontWeight.w400,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Color(0xff11416B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              totalSteps,
              (index) => Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(
                    right: index < totalSteps - 1 ? 8 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: index < currentStep
                        ? const Color(0xff11416B)
                        : const Color(0xffE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
