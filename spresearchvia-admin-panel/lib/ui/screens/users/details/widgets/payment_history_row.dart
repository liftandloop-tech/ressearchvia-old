import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class PaymentHistoryRow extends TableRow {
  PaymentHistoryRow({
    required String txn,
    required String amount,
    required String method,
    required String date,
    required String status,
    required Color color,
    Widget? action,
  }) : super(
         children: [
           Padding(
             padding: EdgeInsets.all(AppTheme.spacing12),
             child: Text(txn, style: AppTheme.tableDataStyle),
           ),
           Padding(
             padding: EdgeInsets.all(AppTheme.spacing12),
             child: Text(amount, style: AppTheme.tableDataStyle),
           ),
           Padding(
             padding: EdgeInsets.all(AppTheme.spacing12),
             child: Text(method, style: AppTheme.tableDataStyle),
           ),
           Padding(
             padding: EdgeInsets.all(AppTheme.spacing12),
             child: Text(date, style: AppTheme.tableDataStyle),
           ),
           Padding(
             padding: EdgeInsets.all(AppTheme.spacing12),
             child: Container(
               padding: EdgeInsets.symmetric(
                 horizontal: AppTheme.spacing8,
                 vertical: AppTheme.spacing4,
               ),
               decoration: BoxDecoration(
                 color: color.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(AppTheme.borderRadiusTiny),
               ),
               child: Text(
                 status,
                 style: AppTheme.labelStyle.copyWith(
                   fontWeight: FontWeight.w500,
                   color: color,
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
           ),
           if (action != null)
             Padding(
               padding: EdgeInsets.all(AppTheme.spacing8),
               child: Center(child: action),
             )
           else
             const SizedBox.shrink(),
         ],
       );
}
