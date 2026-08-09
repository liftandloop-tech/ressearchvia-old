import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/activity_log.controller.dart';
import 'activity_log_dropdown.widget.dart';
import 'activity_log_table_header.widget.dart';
import 'activity_log_row.widget.dart';
import 'activity_log_page_button.widget.dart';

class ActivityLog extends StatelessWidget {
  final String? userId;
  const ActivityLog({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ActivityLogController());

    if (userId != null) {
      controller.fetchActivities(userId!);
    }

    return Obx(() {
      final filtered = controller.filteredActivities;
      final totalPages = (filtered.length / controller.itemsPerPage).ceil();
      final startIndex =
          (controller.currentPage.value - 1) * controller.itemsPerPage;
      final endIndex = (startIndex + controller.itemsPerPage).clamp(
        0,
        filtered.length,
      );
      final currentPageActivities = filtered.sublist(startIndex, endIndex);

      return Container(
        padding: EdgeInsets.all(AppTheme.spacing24),
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border.all(color: AppTheme.gray200),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Row(
              children: [
                Icon(
                  Icons.list_alt,
                  size: AppTheme.iconSizeDefault,
                  color: AppTheme.primaryBlue,
                ),
                SizedBox(width: AppTheme.spacing8),
                Text(
                  'Activity Log',
                  style: AppTheme.h4Style.copyWith(color: AppTheme.primaryBlue),
                ),
                const Spacer(),
                // Severity legend chips
                _SeverityChip(
                  'CRITICAL',
                  const Color(0xFFDC2626),
                  const Color(0xFFFEE2E2),
                ),
                SizedBox(width: AppTheme.spacing4),
                _SeverityChip(
                  'SECURITY',
                  const Color(0xFFD97706),
                  const Color(0xFFFEF3C7),
                ),
                SizedBox(width: AppTheme.spacing4),
                _SeverityChip(
                  'WARNING',
                  const Color(0xFF0284C7),
                  const Color(0xFFE0F2FE),
                ),
                SizedBox(width: AppTheme.spacing4),
                _SeverityChip(
                  'INFO',
                  const Color(0xFF16A34A),
                  const Color(0xFFDCFCE7),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing4),
            Text(
              'Complete compliance-grade audit trail with severity classification.',
              style: AppTheme.bodySmallStyle.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.spacing24),

            // ── Filter Row ────────────────────────────────────────────────
            Wrap(
              spacing: AppTheme.spacing12,
              runSpacing: AppTheme.spacing8,
              children: [
                // Search (static for now)
                SizedBox(
                  width: 260,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search activities…',
                      hintStyle: AppTheme.bodySmallStyle.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                        borderSide: BorderSide(color: AppTheme.gray200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusSmall,
                        ),
                        borderSide: BorderSide(color: AppTheme.primaryBlue),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing12,
                        vertical: AppTheme.spacing12,
                      ),
                      isDense: true,
                    ),
                  ),
                ),

                // Type filter
                Obx(
                  () => SizedBox(
                    width: 150,
                    child: ActivityLogDropdown(
                      value: controller.selectedType.value,
                      items: controller.activityTypes,
                      onChanged: controller.updateType,
                    ),
                  ),
                ),

                // Severity filter
                Obx(
                  () => SizedBox(
                    width: 155,
                    child: ActivityLogDropdown(
                      value: controller.selectedSeverity.value,
                      items: controller.severityLevels,
                      onChanged: controller.updateSeverity,
                    ),
                  ),
                ),

                // Time range filter
                Obx(
                  () => SizedBox(
                    width: 140,
                    child: ActivityLogDropdown(
                      value: controller.selectedTimeRange.value,
                      items: controller.timeRanges,
                      onChanged: controller.updateTimeRange,
                    ),
                  ),
                ),

                // Refresh / clear filters
                ElevatedButton.icon(
                  onPressed: controller.clearFilters,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Clear', style: TextStyle(fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.white,
                    foregroundColor: AppTheme.textPrimary,
                    side: BorderSide(color: AppTheme.gray200),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.spacing16,
                      vertical: AppTheme.spacing12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTheme.borderRadiusSmall,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing24),

            // ── Loading indicator ─────────────────────────────────────────
            if (controller.isLoading.value)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              // ── Table ─────────────────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.gray200),
                  borderRadius: BorderRadius.circular(
                    AppTheme.borderRadiusDefault,
                  ),
                ),
                child: Table(
                  columnWidths: const {
                    0: FlexColumnWidth(2.2), // Date & Time
                    1: FlexColumnWidth(1.5), // Activity Type
                    2: FlexColumnWidth(3.5), // Description
                    3: FlexColumnWidth(2), // IP / Source
                    4: FlexColumnWidth(1.4), // Severity
                    5: FlexColumnWidth(1.6), // Status
                  },
                  children: [
                    TableRow(
                      decoration: BoxDecoration(color: AppTheme.gray50),
                      children: [
                        ActivityLogHeaderCell('Date & Time'),
                        ActivityLogHeaderCell('Activity Type'),
                        ActivityLogHeaderCell('Description'),
                        ActivityLogHeaderCell('IP / Source'),
                        ActivityLogHeaderCell('Severity'),
                        ActivityLogHeaderCell('Status'),
                      ],
                    ),
                    ...currentPageActivities.map(
                      (activity) => ActivityLogRow(
                        dateTime: activity['dateTime'],
                        type: activity['type'],
                        icon: activity['icon'],
                        description: activity['description'],
                        source: activity['source'],
                        status: activity['status'],
                        statusColor: activity['color'],
                        severity: activity['severity'] ?? 'INFO',
                        severityColor: activity['severityColor'],
                        severityBgColor: controller.getSeverityBgColor(
                          activity['severity'] ?? 'INFO',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacing16),

              // ── Footer: count + pagination ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: ${filtered.length} entries',
                    style: AppTheme.bodySmallStyle.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  if (totalPages > 1)
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          onPressed: controller.currentPage.value > 1
                              ? controller.previousPage
                              : null,
                          color: AppTheme.textSecondary,
                        ),
                        ...List.generate(totalPages > 5 ? 5 : totalPages, (
                          index,
                        ) {
                          int pageNum;
                          if (totalPages <= 5) {
                            pageNum = index + 1;
                          } else if (controller.currentPage.value <= 3) {
                            pageNum = index + 1;
                          } else if (controller.currentPage.value >=
                              totalPages - 2) {
                            pageNum = totalPages - 4 + index;
                          } else {
                            pageNum = controller.currentPage.value - 2 + index;
                          }
                          return Padding(
                            padding: EdgeInsets.only(right: AppTheme.spacing8),
                            child: ActivityLogPageButton(
                              text: '$pageNum',
                              isActive: controller.currentPage.value == pageNum,
                              onTap: () => controller.goToPage(pageNum),
                            ),
                          );
                        }),
                        if (totalPages > 5) ...[
                          Text('…', style: AppTheme.bodySmallStyle),
                          SizedBox(width: AppTheme.spacing8),
                          ActivityLogPageButton(
                            text: '$totalPages',
                            isActive:
                                controller.currentPage.value == totalPages,
                            onTap: () => controller.goToPage(totalPages),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          onPressed: controller.currentPage.value < totalPages
                              ? controller.nextPage
                              : null,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

/// Small severity legend chip shown in the header
class _SeverityChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;
  const _SeverityChip(this.label, this.color, this.bgColor);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
