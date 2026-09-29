import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AutomatedStepperHeader extends StatelessWidget {
  final int currentStep; // 0 to 4
  final Function(int) onStepTapped;

  const AutomatedStepperHeader({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  @override
  Widget build(BuildContext context) {
    const steps = [
      'Agreement',
      'Static IP',
      'Broker Setup',
      'Strategy',
      'Live Session',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${currentStep + 1} of 5: ${steps[currentStep]}',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff11416B),
                ),
              ),
              Text(
                '${((currentStep + 1) / 5 * 100).round()}% Completed',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: currentStep == 4 ? AppTheme.primaryGreen : AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stepper bar
          Row(
            children: List.generate(5, (index) {
              final isCompleted = index < currentStep;
              final isCurrent = index == currentStep;

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Allow tapping any past or current step
                    if (index <= currentStep) {
                      onStepTapped(index);
                    }
                  },
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppTheme.primaryGreen
                          : (isCurrent ? AppTheme.primaryBlue : Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
