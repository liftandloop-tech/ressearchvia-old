import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/constants/app_dimensions.dart';
import '../../controllers/rm.controller.dart';
import '../../core/models/relationship_manager.dart';
import '../../services/snackbar.service.dart';

class ContactRMScreen extends StatelessWidget {
  const ContactRMScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      SnackbarService.showError('Could not launch phone dialer');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      SnackbarService.showError('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    // Reuse existing controller if already registered; otherwise create one
    final controller = Get.isRegistered<RMController>()
        ? Get.find<RMController>()
        : Get.put(RMController());

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppTheme.primaryBlue,
            size: responsive.spacing(20),
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Contact RM',
          style: TextStyle(
            fontFamily: 'Poppins',
            color: AppTheme.primaryBlue,
            fontSize: responsive.sp(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppTheme.primaryBlue,
            ),
          );
        }



        final rm = controller.assignedRM.value ??
            RelationshipManager(
              id: 'default',
              fullName: 'Jaya Verma',
              mobileNumber: '9893024309',
              emailAddress: 'info@researchvia.in',
            );

        return SingleChildScrollView(
          child: Padding(
            padding: responsive.padding(
              horizontal: AppDimensions.paddingMedium,
              vertical: AppDimensions.paddingMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Card
                Container(
                  width: double.infinity,
                  padding: responsive.padding(
                    horizontal: AppDimensions.paddingLarge,
                    vertical: AppDimensions.paddingLarge * 1.5,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryBlue,
                        AppTheme.primaryBlueDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      responsive.radius(AppDimensions.radiusLarge),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: responsive.spacing(100),
                        height: responsive.spacing(100),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            rm.fullName.isNotEmpty
                                ? rm.fullName[0].toUpperCase()
                                : 'R',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: responsive.sp(40),
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(20)),
                      // Name
                      Text(
                        rm.fullName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: responsive.sp(24),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (rm.department != null) ...[
                        SizedBox(height: responsive.spacing(8)),
                        Container(
                          padding: responsive.padding(
                            horizontal: AppDimensions.paddingMedium,
                            vertical: AppDimensions.paddingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(
                              responsive.radius(AppDimensions.radiusSmall),
                            ),
                          ),
                          child: Text(
                            rm.department!,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: responsive.sp(14),
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (rm.staffId != null) ...[
                        SizedBox(height: responsive.spacing(12)),
                        Text(
                          'ID: ${rm.staffId}',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: responsive.sp(12),
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: responsive.spacing(30)),

                // Contact Information Section
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: responsive.sp(18),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryBlue,
                  ),
                ),
                SizedBox(height: responsive.spacing(15)),

                // Phone Number Card
                _buildContactCard(
                  context: context,
                  responsive: responsive,
                  icon: Icons.phone_rounded,
                  iconColor: Colors.green,
                  title: 'Phone Number',
                  value: rm.mobileNumber,
                  onTap: () => _makePhoneCall(rm.mobileNumber),
                ),

                SizedBox(height: responsive.spacing(15)),

                // Email Card (if available)
                if (rm.emailAddress != null && rm.emailAddress!.isNotEmpty)
                  _buildContactCard(
                    context: context,
                    responsive: responsive,
                    icon: Icons.email_rounded,
                    iconColor: Colors.blue,
                    title: 'Email Address',
                    value: rm.emailAddress!,
                    onTap: () => _sendEmail(rm.emailAddress!),
                  ),

                SizedBox(height: responsive.spacing(30)),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _makePhoneCall(rm.mobileNumber),
                        icon: Icon(
                          Icons.phone,
                          size: responsive.spacing(20),
                        ),
                        label: Text(
                          'Call Now',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: responsive.sp(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: responsive.padding(
                            vertical: AppDimensions.paddingMedium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              responsive.radius(AppDimensions.radiusMedium),
                            ),
                          ),
                          elevation: 3,
                        ),
                      ),
                    ),
                    if (rm.emailAddress != null &&
                        rm.emailAddress!.isNotEmpty) ...[
                      SizedBox(width: responsive.spacing(15)),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _sendEmail(rm.emailAddress!),
                          icon: Icon(
                            Icons.email,
                            size: responsive.spacing(20),
                          ),
                          label: Text(
                            'Email',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: responsive.sp(16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: responsive.padding(
                              vertical: AppDimensions.paddingMedium,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                responsive.radius(AppDimensions.radiusMedium),
                              ),
                            ),
                            elevation: 3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required Responsive responsive,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(
        responsive.radius(AppDimensions.radiusMedium),
      ),
      child: Container(
        padding: responsive.padding(
          horizontal: AppDimensions.paddingMedium,
          vertical: AppDimensions.paddingMedium,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(
            responsive.radius(AppDimensions.radiusMedium),
          ),
          border: Border.all(
            color: AppTheme.borderGrey,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: responsive.spacing(50),
              height: responsive.spacing(50),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  responsive.radius(AppDimensions.radiusSmall),
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: responsive.spacing(25),
              ),
            ),
            SizedBox(width: responsive.spacing(15)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: responsive.sp(12),
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: responsive.sp(16),
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: responsive.spacing(16),
            ),
          ],
        ),
      ),
    );
  }
}
