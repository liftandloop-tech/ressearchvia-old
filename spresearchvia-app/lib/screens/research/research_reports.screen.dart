import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/controllers/auth.controller.dart';
import '../../controllers/report.controller.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/trading_call_tab.dart';
import 'widgets/reports_tab.dart';

class ResearchReportsScreen extends StatefulWidget {
  const ResearchReportsScreen({super.key});

  @override
  State<ResearchReportsScreen> createState() => _ResearchReportsScreenState();
}

class _ResearchReportsScreenState extends State<ResearchReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ReportController reportController;

  @override
  void initState() {
    super.initState();
    reportController = Get.put(ReportController());
    
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: reportController.selectedTabIndex.value,
    );
    
    // Subscribe to external tab changes (e.g. from Notifications)
    ever(reportController.selectedTabIndex, (index) {
      if (_tabController.index != index) {
        _tabController.animateTo(index);
      }
    });

    // Fetch fresh data when screen is mounted
    reportController.refreshData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final isSuspended = authController.currentUser.value?.userStatus == 'SUSPENDED';

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundWhite,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Research Reports',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryBlueDark,
          ),
        ),
        centerTitle: true,
        actions: [
          if (!isSuspended)
            IconButton(
              icon: const Icon(
                Icons.filter_list,
                color: AppTheme.primaryBlueDark,
              ),
              onPressed: () {
                _showDateBottomSheet(context, reportController);
              },
            ),
        ],
        bottom: isSuspended
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Container(
                  color: AppTheme.backgroundWhite,
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryBlue,
                    indicatorWeight: 3,
                    labelColor: AppTheme.primaryBlueDark,
                    unselectedLabelColor: AppTheme.textGrey,
                    labelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    onTap: (index) {
                      reportController.selectedTabIndex.value = index;
                    },
                    tabs: const [
                      Tab(text: 'Trading Call'),
                      Tab(text: 'Reports'),
                    ],
                  ),
                ),
              ),
      ),
      body: isSuspended
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_person_rounded, size: 80, color: AppTheme.error.withOpacity(0.5)),
                    SizedBox(height: 24),
                    Text(
                      'Access Restricted',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlueDark,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Trading calls and research reports are not available for suspended accounts. Please contact the administrator.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : TabBarView(
        controller: _tabController,
        children: [
          TradingCallTab(reportController: reportController),
          ReportsTab(reportController: reportController),
        ],
      ),
    );
  }

  void _showDateBottomSheet(
    BuildContext context,
    ReportController reportController,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryBlueDark,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Today',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              onTap: () {
                final now = DateTime.now();
                final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
                final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                reportController.onDateFilterChanged(
                  startOfDay.toIso8601String(),
                  endOfDay.toIso8601String(),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Last 7 Days',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              onTap: () {
                final now = DateTime.now();
                final start = now.subtract(const Duration(days: 7));
                final startOfRange = DateTime(start.year, start.month, start.day, 0, 0, 0);
                final endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                reportController.onDateFilterChanged(
                  startOfRange.toIso8601String(),
                  endOfRange.toIso8601String(),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Last 30 Days',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              onTap: () {
                final now = DateTime.now();
                final start = now.subtract(const Duration(days: 30));
                final startOfRange = DateTime(start.year, start.month, start.day, 0, 0, 0);
                final endOfRange = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
                reportController.onDateFilterChanged(
                  startOfRange.toIso8601String(),
                  endOfRange.toIso8601String(),
                );
                Navigator.pop(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.clear, color: AppTheme.primaryBlueDark),
              title: const Text(
                'Clear Filter',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              onTap: () {
                reportController.onDateFilterChanged(null, null);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
