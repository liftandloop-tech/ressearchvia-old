import 'package:flutter/material.dart';

class PaymentTableRow extends TableRow {
  final String type;
  final String planName;
  final String segmentName;
  final String amount;
  final String date;
  final String status;
  final VoidCallback? onEdit;
  final bool showEdit;

  PaymentTableRow({
    required this.type,
    required this.planName,
    required this.segmentName,
    required this.amount,
    required this.date,
    required this.status,
    this.onEdit,
    this.showEdit = true,
  }) : super(
         children: [
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
             child: Text(
               type,
               style: const TextStyle(
                 fontSize: 13,
                 fontWeight: FontWeight.w500,
               ),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
             child: Text(planName, style: const TextStyle(fontSize: 13)),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
             child: Text(segmentName, style: const TextStyle(fontSize: 13)),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
             child: Text(
               amount,
               style: const TextStyle(
                 fontSize: 13,
                 fontWeight: FontWeight.bold,
               ),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
             child: Text(
               date,
               style: const TextStyle(fontSize: 13, color: Colors.grey),
             ),
           ),
           Padding(
             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
             child: Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: _getStatusColor(status).withOpacity(0.1),
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
               padding: const EdgeInsets.all(8),
               child: onEdit != null
                   ? IconButton(
                       icon: const Icon(
                         Icons.edit_note,
                         size: 20,
                         color: Colors.indigo,
                       ),
                       onPressed: onEdit,
                       tooltip: 'Correct Entry',
                     )
                   : const SizedBox.shrink(),
             ),
         ],
       );

  static Color _getStatusColor(String status) {
    status = status.toUpperCase();
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
