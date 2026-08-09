import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import '../../../../models/report.model.dart';
import 'report_status_badge.widget.dart';
import 'report_actions.widget.dart';
import 'report_cell.widget.dart';

class ReportRow extends TableRow {
  ReportRow({required ReportModel report, String? categoryName})
    : super(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
                if (report.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.gray50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gray200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 4, right: 8),
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                report.description,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (report.updates.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Updates:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...report.updates.map(
                    (update) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 5),
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  update['text'] ?? '',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                                if (update['timestamp'] != null &&
                                    update['timestamp']!.isNotEmpty)
                                  Text(
                                    update['timestamp']!,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textSecondary.withOpacity(
                                        0.6,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ReportStatusBadge(status: report.status),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child:
                (report.reportOriginalName != null &&
                    report.reportOriginalName!.isNotEmpty)
                ? const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.successGreen,
                    size: 18,
                  )
                : Text(
                    '-',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          ReportCell(text: report.createdDate, color: AppTheme.textSecondary),
          ReportCell(text: report.lastUpdated, color: AppTheme.textSecondary),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: ReportActions(report: report),
          ),
        ],
      );
}
