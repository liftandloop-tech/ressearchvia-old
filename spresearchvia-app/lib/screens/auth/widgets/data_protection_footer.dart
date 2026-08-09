part of '../login.screen.dart';

class DataProtection extends StatelessWidget {
  const DataProtection({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    return SizedBox(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            color: AppTheme.textGrey,
            size: responsive.spacing(AppDimensions.iconMedium),
          ),
          Flexible(
            child: Text(
              " ${AppStrings.dataProtection}",
              style: AppStyles.caption.copyWith(fontSize: responsive.sp(12)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
