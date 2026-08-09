import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class ActivityLogHeaderCell extends StatelessWidget {
  final String text;

  const ActivityLogHeaderCell(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing12,
        vertical: AppTheme.spacing12,
      ),
      child: Text(text, style: AppTheme.tableHeaderStyle),
    );
  }
}

class ActivityLogTableHeader extends TableRow {
  ActivityLogTableHeader()
    : super(
        decoration: BoxDecoration(color: AppTheme.gray50),
        children: [
          const ActivityLogHeaderCell('Date & Time'),
          const ActivityLogHeaderCell('Activity Type'),
          const ActivityLogHeaderCell('Description'),
          const ActivityLogHeaderCell('IP / Source'),
          const ActivityLogHeaderCell('Status'),
        ],
      );
}
