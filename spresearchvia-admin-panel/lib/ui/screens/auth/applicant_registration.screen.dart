import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_registration.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';

class ApplicantRegistrationScreen extends StatelessWidget {
  const ApplicantRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantRegistrationController());

    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
          child: Container(
            width: 800,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.gray200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(40),
            child: Obx(() {
              if (controller.isVerified.value) {
                return _buildOnboardingUploads(context, controller);
              }
              if (controller.isRegistered.value) {
                return _buildVerificationScreen(context, controller);
              }
              return _buildApplicationForm(context, controller);
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationForm(BuildContext context, ApplicantRegistrationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Join ResearchVia Team',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Complete the application form to begin the onboarding process.',
          style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Divider(height: 48),

        // Personal Section
        _buildSectionTitle('1. Personal Details'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.nameController, label: 'Full Name *', hint: 'Enter your full name'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(controller: controller.phoneController, label: 'Mobile Number *', hint: 'Enter 10-digit number'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.emailController, label: 'Email Address *', hint: 'Enter your email address'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // default to 18 years ago
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    controller.dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
                child: IgnorePointer(
                  child: _buildTextField(
                    controller: controller.dobController,
                    label: 'Date of Birth (YYYY-MM-DD) *',
                    hint: 'Select your birth date',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedGender.value.isEmpty ? null : controller.selectedGender.value,
            decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (val) => controller.selectedGender.value = val ?? '',
          ),
        ),

        const SizedBox(height: 32),
        // Address Section
        _buildSectionTitle('2. Addresses'),
        const SizedBox(height: 16),
        const Text('Current Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        _buildTextField(controller: controller.currentStreetController, label: 'Street Address', hint: 'Street, building name'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.currentCityController, label: 'City', hint: 'City'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(controller: controller.currentStateController, label: 'State', hint: 'State'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(controller: controller.currentZipController, label: 'ZIP Code', hint: 'ZIP'),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text('Permanent Address (If different)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        _buildTextField(controller: controller.permanentStreetController, label: 'Street Address', hint: 'Street, building name'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.permanentCityController, label: 'City', hint: 'City'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(controller: controller.permanentStateController, label: 'State', hint: 'State'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(controller: controller.permanentZipController, label: 'ZIP Code', hint: 'ZIP'),
            ),
          ],
        ),

        const SizedBox(height: 32),
        // Emergency Contact Section
        _buildSectionTitle('3. Emergency Contact'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.emergencyNameController, label: 'Contact Person Name', hint: 'Full name'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(controller: controller.emergencyRelationController, label: 'Relationship', hint: 'Relation (e.g. Spouse, Parent)'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(controller: controller.emergencyPhoneController, label: 'Contact Number', hint: 'Phone number'),
            ),
          ],
        ),

        const SizedBox(height: 32),
        // Professional Section
        _buildSectionTitle('4. Experience Details'),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.experienceYearsController, label: 'Years of Experience', hint: 'e.g. 3'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(controller: controller.previousCompanyController, label: 'Previous/Current Employer', hint: 'Company name'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(controller: controller.lastCtcController, label: 'Last CTC (Annual)', hint: 'e.g. 5,00,000'),
            ),
          ],
        ),

        const SizedBox(height: 48),
        Obx(
          () => Button(
            title: controller.isLoading.value ? 'Submitting...' : 'Register & Verify',
            buttonType: ButtonType.green,
            onTap: controller.isLoading.value ? null : () => controller.submitApplication(),
          ),
        )
      ],
    );
  }

  Widget _buildVerificationScreen(BuildContext context, ApplicantRegistrationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Contact Verification',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the verification codes sent to your phone and email to proceed.',
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: controller.mobileOtpController,
          decoration: const InputDecoration(labelText: 'Mobile OTP *', border: OutlineInputBorder(), hintText: 'Enter 4-digit code'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: controller.emailOtpController,
          decoration: const InputDecoration(labelText: 'Email OTP *', border: OutlineInputBorder(), hintText: 'Enter 4-digit code'),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => controller.isRegistered.value = false,
              child: const Text('Back to Form'),
            ),
            Button(
              title: 'Verify Codes',
              buttonType: ButtonType.green,
              onTap: () => controller.verifyOtps(),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildOnboardingUploads(BuildContext context, ApplicantRegistrationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Document Uploads',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Upload required files to complete your onboarding application.',
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Divider(height: 48),
        _buildUploadRow(context, 'Profile Photo', 'photo', controller),
        const SizedBox(height: 12),
        _buildUploadRow(context, 'Resume / CV', 'resume', controller),
        const SizedBox(height: 12),
        _buildUploadRow(context, 'PAN Card', 'pan', controller),
        const SizedBox(height: 12),
        _buildUploadRow(context, 'Aadhaar Card', 'aadhaar', controller),
        const SizedBox(height: 12),
        _buildUploadRow(context, 'NISM Certificate', 'nism', controller),
        const SizedBox(height: 12),
        _buildUploadRow(context, 'Highest Education Certificate', 'education', controller),
        const SizedBox(height: 12),
        _buildUploadRow(context, 'KYC Verification Video', 'video', controller),
        const SizedBox(height: 48),
        Button(
          title: 'Complete Onboarding Application',
          buttonType: ButtonType.green,
          onTap: () {
            Get.offAllNamed('/'); // Back to Login page
            Get.snackbar('Application Completed', 'Your application is submitted. Our HR team will contact you.', backgroundColor: Colors.green.withOpacity(0.1));
          },
        )
      ],
    );
  }

  Widget _buildUploadRow(BuildContext context, String title, String type, ApplicantRegistrationController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFDEE2E6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(type == 'video' ? Icons.video_library : Icons.description, color: const Color(0xFF6C757D)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => controller.uploadDoc(type),
            icon: const Icon(Icons.upload, size: 14),
            label: const Text('Upload File'),
            style: ElevatedButton.styleFrom(elevation: 0),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
