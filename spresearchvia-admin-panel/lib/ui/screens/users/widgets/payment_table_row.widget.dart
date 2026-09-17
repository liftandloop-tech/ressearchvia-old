import 'package:flutter/material.dart';

class PaymentTableRow extends TableRow {
  final String type;
  final String planName;
  final String segmentName;
  final String amount;
  final String date;
  final String status;
  final VoidCallback? onEdit;
  final VoidCallback? onViewDetails;
  final bool showEdit;
  final bool isRefund;
  final String? subtitle;

  PaymentTableRow({
    required this.type,
    required this.planName,
    required this.segmentName,
    required this.amount,
    required this.date,
    required this.status,
    this.onEdit,
    this.onViewDetails,
    this.showEdit = true,
    this.isRefund = false,
    this.subtitle,
  }) : super(
         decoration: isRefund
             ? const BoxDecoration(
                 color: Color(0xFFFDF2F8), // Soft subtle rose/purple tint for refunds
               )
             : null,
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
             child: Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 if (isRefund) ...[
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                     decoration: BoxDecoration(
                       color: const Color(0xFF9333EA).withValues(alpha: 0.15),
                       borderRadius: BorderRadius.circular(4),
                     ),
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Icon(Icons.currency_exchange, size: 11, color: Color(0xFF9333EA)),
                         SizedBox(width: 4),
                         Text(
                           'REFUND',
                           style: TextStyle(
                             fontSize: 10,
                             fontWeight: FontWeight.w800,
                             color: Color(0xFF9333EA),
                           ),
                         ),
                       ],
                     ),
                   ),
                 ] else ...[
                   Text(
                     type,
                     style: const TextStyle(
                       fontSize: 13,
                       fontWeight: FontWeight.w500,
                     ),
                   ),
                 ],
               ],
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               mainAxisSize: MainAxisSize.min,
               children: [
                 Text(
                   planName,
                   style: TextStyle(
                     fontSize: 13,
                     fontWeight: isRefund ? FontWeight.w600 : FontWeight.normal,
                     color: isRefund ? const Color(0xFF831843) : const Color(0xFF1E293B),
                   ),
                 ),
                 if (subtitle != null && subtitle.isNotEmpty) ...[
                   const SizedBox(height: 3),
                   Text(
                     subtitle,
                     style: const TextStyle(
                       fontSize: 11,
                       color: Color(0xFF64748B),
                       height: 1.2,
                     ),
                   ),
                 ],
               ],
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
             child: Text(segmentName, style: const TextStyle(fontSize: 13)),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
             child: Text(
               amount,
               style: TextStyle(
                 fontSize: 13,
                 fontWeight: FontWeight.bold,
                 color: isRefund ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
               ),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
             child: Text(
               date,
               style: const TextStyle(fontSize: 13, color: Colors.grey),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: _getStatusColor(status).withValues(alpha: 0.12),
                 borderRadius: BorderRadius.circular(4),
               ),
               child: Text(
                 status,
                 style: TextStyle(
                   fontSize: 11,
                   fontWeight: FontWeight.bold,
                   color: _getStatusColor(status),
                 ),
                 textAlign: TextAlign.center,
               ),
             ),
           ),
           if (showEdit)
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   if (onViewDetails != null)
                     IconButton(
                       icon: const Icon(
                         Icons.receipt_long_outlined,
                         size: 19,
                         color: Color(0xFF9333EA),
                       ),
                       onPressed: onViewDetails,
                       tooltip: 'View Refund Policy & Breakdown',
                       splashRadius: 16,
                     ),
                   if (onEdit != null)
                     IconButton(
                       icon: const Icon(
                         Icons.edit_note,
                         size: 20,
                         color: Colors.indigo,
                       ),
                       onPressed: onEdit,
                       tooltip: 'Correct Entry',
                       splashRadius: 16,
                     ),
                 ],
               ),
             ),
         ],
       );

  static Color _getStatusColor(String status) {
    status = status.toUpperCase();
    if (status.contains('REFUND')) {
      return const Color(0xFF9333EA); // Purple for refunded
    }
    if (status.contains('PAID') ||
        status.contains('APPROVED') ||
        status.contains('COMPLETE') ||
        status.contains('ACTIVE')) {
      return Colors.green;
    }
    if (status.contains('REJECTED') || status.contains('FAILED')) {
      return Colors.red;
    }
    if (status.contains('PENDING') || status.contains('CREATED')) {
      return Colors.orange;
    }
    return Colors.grey;
  }
}
