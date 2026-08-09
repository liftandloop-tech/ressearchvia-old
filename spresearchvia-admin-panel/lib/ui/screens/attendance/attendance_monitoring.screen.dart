import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/attendance/attendance.controller.dart';
import 'package:spresearch_web/ui/layouts/dashboard_layout.widget.dart';
import 'package:spresearch_web/models/attendance.model.dart';

class AttendanceMonitoringScreen extends StatelessWidget {
  const AttendanceMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AttendanceController());

    return DefaultTabController(
      length: 2,
      child: DashboardLayout(
        child: Container(
          color: AppTheme.gray50,
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    'Attendance & Performance Reports',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      controller.fetchAttendance();
                      controller.fetchPerformance();
                    },
                    icon: Icon(Icons.refresh, color: AppTheme.primaryBlue),
                    tooltip: 'Refresh Reports',
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Tabs Navigation
              TabBar(
                labelColor: AppTheme.primaryBlue,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryBlue,
                tabs: const [
                  Tab(text: 'Daily Attendance & Activity'),
                  Tab(text: 'Employee Performance Overview'),
                ],
              ),
              const SizedBox(height: 24),

              // Tabs Content
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAttendanceTab(context, controller),
                    _buildPerformanceTab(context, controller),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceTab(BuildContext context, AttendanceController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Filters card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppTheme.gray200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.selectedStaffId.value.isEmpty ? null : controller.selectedStaffId.value,
                      hint: const Text('Filter Employee'),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      items: controller.staffList
                          .map((s) => DropdownMenuItem(value: s.id, child: Text(s.name)))
                          .toList(),
                      onChanged: (val) => controller.updateFilters(staffId: val ?? ''),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Start Date
                Expanded(
                  child: Obx(
                    () => ListTile(
                      title: const Text('Start Date', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        controller.startDate.value != null
                            ? DateFormat('yyyy-MM-dd').format(controller.startDate.value!)
                            : 'Select Date',
                      ),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.gray300),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          controller.updateFilters(start: picked);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // End Date
                Expanded(
                  child: Obx(
                    () => ListTile(
                      title: const Text('End Date', style: TextStyle(fontSize: 12)),
                      subtitle: Text(
                        controller.endDate.value != null
                            ? DateFormat('yyyy-MM-dd').format(controller.endDate.value!)
                            : 'Select Date',
                      ),
                      trailing: const Icon(Icons.calendar_today, size: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.gray300),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          controller.updateFilters(end: picked);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                TextButton(
                  onPressed: () => controller.resetFilters(),
                  child: const Text('Clear Filters'),
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Attendance list
        Expanded(
          child: Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }
            if (controller.attendanceRecords.isEmpty) {
              return Center(
                child: Text(
                  'No attendance logs recorded for selected dates.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              );
            }

            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.gray200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 12,
                  minWidth: 800,
                  columns: const [
                    DataColumn2(label: Text('Employee'), size: ColumnSize.L),
                    DataColumn2(label: Text('Login Time')),
                    DataColumn2(label: Text('Logout Time')),
                    DataColumn2(label: Text('Working Hours')),
                    DataColumn2(label: Text('Status')),
                    DataColumn2(label: Text('Face Verifications')),
                  ],
                  rows: controller.attendanceRecords.map((rec) {
                    final workingHrs = rec.totalWorkingMinutes > 0
                        ? '${(rec.totalWorkingMinutes / 60).toStringAsFixed(1)} hrs'
                        : 'Active';

                    final failCount = rec.activityLogs.where((l) => !l.faceDetected).length;

                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rec.staffName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('${rec.staffCode} - ${rec.deviceInfo ?? ""}',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(rec.loginTime))),
                        DataCell(
                          Text(rec.logoutTime != null
                              ? DateFormat('yyyy-MM-dd HH:mm').format(rec.logoutTime!)
                              : 'Session Active'),
                        ),
                        DataCell(Text(workingHrs)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (rec.isRemote ? Colors.purple : AppTheme.primaryBlue).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              rec.isRemote ? 'Remote' : 'Office Premises',
                              style: TextStyle(
                                color: rec.isRemote ? Colors.purple : AppTheme.primaryBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            failCount > 0 ? '$failCount detection failures' : 'All Clear (${rec.activityLogs.length} pings)',
                            style: TextStyle(
                              color: failCount > 0 ? Colors.red : Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }),
        )
      ],
    );
  }

  Widget _buildPerformanceTab(BuildContext context, AttendanceController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.performanceOverview.isEmpty) {
        return Center(
          child: Text(
            'No performance data generated yet.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
          ),
        );
      }

      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.gray200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 800,
            columns: const [
              DataColumn2(label: Text('Employee Name'), size: ColumnSize.L),
              DataColumn2(label: Text('Department')),
              DataColumn2(label: Text('Total Working Hours')),
              DataColumn2(label: Text('Active SessionsCount')),
              DataColumn2(label: Text('Assigned Leads')),
              DataColumn2(label: Text('Converted Leads')),
              DataColumn2(label: Text('Conversion Rate')),
            ],
            rows: controller.performanceOverview.map((row) {
              return DataRow(
                cells: [
                  DataCell(Text(row['fullName']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(row['department']?.toString() ?? '')),
                  DataCell(Text('${row['totalWorkingHours']} hrs')),
                  DataCell(Text(row['sessionsCount'].toString())),
                  DataCell(Text(row['totalLeads'].toString())),
                  DataCell(Text(row['convertedLeads'].toString())),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${row['conversionRate']}%',
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      );
    });
  }
}
