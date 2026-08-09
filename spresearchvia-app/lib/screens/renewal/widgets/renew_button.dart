import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class RenewButton extends StatelessWidget {
  const RenewButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.successGreen,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.credit_card, color: AppTheme.textWhite, size: 20),
            SizedBox(width: 8),
            Text(
              'Renew with One Click',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
