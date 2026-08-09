import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.strings.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    final dayName = days[now.weekday % 7];
    final monthName = months[now.month - 1];

    return '$dayName, $monthName ${now.day}, ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.welcomeBack,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Today is ${_getFormattedDate()}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.white.withValues(alpha: 0.9),
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
            ),
            child: Icon(Icons.menu, color: AppTheme.white, size: 20),
          ),
        ],
      ),
    );
  }
}
