import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/manage_segments.controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';

class ManageSegmentsScreen extends StatelessWidget {
  const ManageSegmentsScreen({super.key});

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateValue.toString());
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return dateValue.toString();
    }
  }

  IconData _getSegmentIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('banknifty') || lower.contains('bank nifty')) {
      return Icons.account_balance_outlined;
    } else if (lower.contains('nifty')) {
      return Icons.trending_up_outlined;
    } else if (lower.contains('equity') || lower.contains('stock')) {
      return Icons.show_chart_outlined;
    } else if (lower.contains('commodity') || lower.contains('gold') || lower.contains('crude')) {
      return Icons.monetization_on_outlined;
    } else if (lower.contains('crypto')) {
      return Icons.currency_bitcoin_outlined;
    } else if (lower.contains('forex') || lower.contains('currency')) {
      return Icons.currency_exchange_outlined;
    } else if (lower.contains('option')) {
      return Icons.stacked_line_chart_outlined;
    } else if (lower.contains('future')) {
      return Icons.candlestick_chart_outlined;
    }
    return Icons.pie_chart_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final ManageSegmentsController controller = Get.put(ManageSegmentsController());

    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xff111827)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Manage Segments',
          style: TextStyle(
            color: Color(0xff11416B),
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xff11416B)),
            tooltip: 'Refresh',
            onPressed: () => controller.fetchUserPlanSegments(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryBlue),
          );
        }

        if (!controller.hasActivePlan.value) {
          return RefreshIndicator(
            onRefresh: controller.fetchUserPlanSegments,
            color: AppTheme.primaryBlue,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: const Color(0xffEFF6FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xffBFDBFE), width: 2),
                      ),
                      child: const Icon(
                        Icons.layers_clear_outlined,
                        size: 42,
                        color: Color(0xff11416B),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Active Plan Found',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You currently do not have an active subscription plan. Purchase a plan first to activate and manage market segments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Color(0xff6B7280),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Get.toNamed(AppRoutes.choosePlan),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff11416B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Choose a Plan',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final plan = controller.activePlan;
        final planName = plan['planName']?.toString() ?? 'Active Plan';
        final isLifetime = plan['isLifetime'] == true;
        final remainingDays = plan['remainingDays'];
        final endDate = plan['endDate'];
        final isHni = plan['isHni'] == true;
        final activeCount = controller.segments.where((s) => s.isActive.value).length;

        return RefreshIndicator(
          onRefresh: controller.fetchUserPlanSegments,
          color: AppTheme.primaryBlue,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Active Plan Card
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xff11416B), Color(0xff1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff11416B).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ACTIVE SUBSCRIPTION',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1,
                                  color: Color(0xff93C5FD),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                planName,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isHni)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xffF59E0B),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'HNI',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff10B981).withOpacity(0.2),
                            border: Border.all(color: const Color(0xff34D399)),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Color(0xff34D399)),
                              SizedBox(width: 4),
                              Text(
                                'Active',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff34D399),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available_outlined, size: 16, color: Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              isLifetime
                                  ? 'Lifetime Access'
                                  : 'Valid till: ${_formatDate(endDate)}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (!isLifetime && remainingDays != null)
                          Text(
                            '$remainingDays days left',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xffFDE047),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Policy Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xffEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xffBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Color(0xff1D4ED8)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'You can activate multiple market segments simultaneously under your plan. At least 1 segment must stay active at all times.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xff1E40AF),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Available Segments',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xff111827),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xffE0E7FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$activeCount Active',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff3730A3),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Segment Items List
              if (controller.segments.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  child: const Text(
                    'No segments available',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xff6B7280),
                    ),
                  ),
                )
              else
                ...controller.segments.map((segment) {
                  return Obx(() {
                    final isActive = segment.isActive.value;
                    final isToggling = segment.isToggling.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xff11416B).withOpacity(0.4)
                              : const Color(0xffE5E7EB),
                          width: isActive ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? const Color(0xff11416B).withOpacity(0.1)
                                  : const Color(0xffF3F4F6),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getSegmentIcon(segment.name),
                              size: 22,
                              color: isActive
                                  ? const Color(0xff11416B)
                                  : const Color(0xff6B7280),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        segment.name,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isActive
                                              ? const Color(0xff111827)
                                              : const Color(0xff4B5563),
                                        ),
                                      ),
                                    ),
                                    if (isActive)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffD1FAE5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xff065F46),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (segment.description.isNotEmpty) ...[
                                  const SizedBox(height: 3),
                                  Text(
                                    segment.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 11,
                                      color: Color(0xff6B7280),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (isToggling)
                            const SizedBox(
                              width: 32,
                              height: 32,
                              child: Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xff11416B),
                                  ),
                                ),
                              ),
                            )
                          else
                            Switch.adaptive(
                              value: isActive,
                              activeColor: const Color(0xff11416B),
                              onChanged: (val) => controller.toggleSegment(segment),
                            ),
                        ],
                      ),
                    );
                  });
                }),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }
}
