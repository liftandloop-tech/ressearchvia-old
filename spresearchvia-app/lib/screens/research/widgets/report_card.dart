import 'package:flutter/material.dart';
import '../../../core/models/research_report.dart';
import 'report_update_card.dart';

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.description,
    required this.onTap,
    required this.onView,
    this.updates = const [],
    this.isLocked = false,
  });

  final String title;
  final String category;
  final String date;
  final String description;
  final VoidCallback onTap;
  final VoidCallback onView;
  final List<ReportUpdate> updates;
  final bool isLocked;

  @override
  Widget build(BuildContext context) {
    final baseCard = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xffE5E7EB), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff163174),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: onView,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xff2C7F38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.visibility,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              date,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xff6B7280),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xff4B5563),
                height: 1.5,
              ),
            ),
            if (updates.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...updates.map(
                (update) => ReportUpdateCard(
                  update: update,
                  compact: true,
                  margin: const EdgeInsets.only(top: 8),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    
    // Wrap with blur overlay if locked
    if (isLocked) {
      return Stack(
        children: [
          baseCard,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: const Color(0xff163174).withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Content published before\nyour plan started',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff163174).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return baseCard;
  }
}
