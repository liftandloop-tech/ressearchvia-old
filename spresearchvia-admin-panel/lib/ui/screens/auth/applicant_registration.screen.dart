import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_registration.controller.dart';

class ApplicantRegistrationScreen extends StatelessWidget {
  const ApplicantRegistrationScreen({super.key});

  static const Color primaryNavy = Color(0xFF1E2265);
  static const Color leftPaneBg = Color(0xFF545398);
  static const Color borderColor = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantRegistrationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 860;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 16 : 40,
                horizontal: isMobile ? 12 : 24,
              ),
              child: Obx(() {
                if (controller.isApplicationSubmitted.value) {
                  return _buildSubmissionSuccess(context, controller, isMobile);
                }

                if (!controller.isEmailVerified.value) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildCreateAccountScreen(context, controller, isMobile),
                      if (controller.isEmailOtpModalOpen.value)
                        _buildEmailOtpModal(context, controller, isMobile),
                    ],
                  );
                }

                return _buildMultiStepFormContainer(context, controller, isMobile);
              }),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // SCREEN 0: CREATE ACCOUNT (IMAGE 1 PARITY)
  // ==========================================

  Widget _buildCreateAccountScreen(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 950),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 30,
            offset: Offset(0, 10),
          )
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPrerequisitesPane(isMobile: true),
                _buildCreateAccountForm(context, controller, isMobile: true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildPrerequisitesPane(isMobile: false),
                ),
                Expanded(
                  flex: 6,
                  child: _buildCreateAccountForm(context, controller, isMobile: false),
                ),
              ],
            ),
    );
  }

  Widget _buildPrerequisitesPane({required bool isMobile}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      decoration: BoxDecoration(
        color: leftPaneBg,
        borderRadius: isMobile
            ? const BorderRadius.vertical(top: Radius.circular(16))
            : const BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kindly keep the following documents and details ready before proceeding with your application:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          _buildPrerequisiteItem('1. Updated Resume / Curriculum Vitae (PDF format, below 5MB)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('2. Recent passport size photograph (in JPEG/PNG format, below 1MB)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('3. Government Photo ID & Address Proof (Aadhaar Card / Passport / Voter ID / DL)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('4. Educational certificates & marksheets (from 10th / Graduation onwards)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('5. Previous employment details, last 3 months salary slips & relieving letter (if experienced candidate)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('6. Valid active email address and mobile number for real-time OTP verification'),
        ],
      ),
    );
  }

  Widget _buildPrerequisiteItem(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13.5,
        color: Colors.white,
        height: 1.45,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildCreateAccountForm(
    BuildContext context,
    ApplicantRegistrationController controller, {
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 44,
        vertical: isMobile ? 32 : 44,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Create Account',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: primaryNavy,
            ),
          ),
          const SizedBox(height: 24),

          // Email
          const Text(
            'Email Address *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller.createAccountEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'name@example.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B), size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Note: Certificates will be sent to this email address',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 18),

          // Confirm Email
          const Text(
            'Confirm Email Address *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller.confirmEmailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'name@example.com',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B), size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          const SizedBox(height: 18),

          // Password
          const Text(
            'Password *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Obx(
            () => TextField(
              controller: controller.createAccountPasswordController,
              obscureText: controller.obscurePassword.value,
              decoration: InputDecoration(
                hintText: 'Enter secure password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscurePassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: controller.togglePasswordVisibility,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Confirm Password
          const Text(
            'Confirm Password *',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 6),
          Obx(
            () => TextField(
              controller: controller.confirmPasswordController,
              obscureText: controller.obscureConfirmPassword.value,
              decoration: InputDecoration(
                hintText: 'Confirm password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: Icon(
                    controller.obscureConfirmPassword.value ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: controller.toggleConfirmPasswordVisibility,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Actions: CANCEL and NEXT
          isMobile
              ? Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.offAllNamed('/'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1E293B),
                          side: const BorderSide(color: Color(0xFF94A3B8)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: controller.isLoading.value ? null : controller.handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isLoading.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('NEXT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Get.offAllNamed('/'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E293B),
                        side: const BorderSide(color: Color(0xFF94A3B8)),
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: controller.isLoading.value ? null : controller.handleCreateAccount,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('NEXT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
          const SizedBox(height: 24),

          // Continue Application Link
          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Already started an application? ',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                InkWell(
                  onTap: () => Get.toNamed('/continue-application'),
                  child: const Text(
                    'Continue Application',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modal Dialog for Email OTP verification
  Widget _buildEmailOtpModal(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Container(
      color: Colors.black.withOpacity(0.45),
      alignment: Alignment.center,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.all(isMobile ? 20 : 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Color(0x20000000), blurRadius: 24, offset: Offset(0, 8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.mark_email_read_outlined, size: 48, color: primaryNavy),
            const SizedBox(height: 12),
            const Text(
              'Verify Email Address',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 4-digit verification code sent to ${controller.createAccountEmailController.text.trim()}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller.emailOtpInputController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '----',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: controller.handleResendEmailOtp,
                    child: const Text('Resend Code'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: controller.isLoading.value ? null : controller.handleVerifyEmailOtp,
                    style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white),
                    child: controller.isLoading.value
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Verify & Proceed'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // MULTI-STEP FORM SHELL (IMAGES 2, 3, 4, 5, 6)
  // ==========================================

  Widget _buildMultiStepFormContainer(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1100),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 30,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _buildMobileStepperHeader(controller),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildStepContent(context, controller, isMobile),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Stepper Sidebar
                SizedBox(
                  width: 250,
                  child: _buildStepperSidebar(controller),
                ),
                const VerticalDivider(width: 1, color: Color(0xFFE2E8F0)),
                // Right Step Form
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
                    child: _buildStepContent(context, controller, isMobile),
                  ),
                ),
              ],
            ),
    );
  }

  // Left Stepper Sidebar with decorative bottom artwork
  Widget _buildStepperSidebar(ApplicantRegistrationController controller) {
    final steps = [
      'Personal Information',
      'Contact Information',
      'Educational Details',
      'Professional Qualification',
      'Occupational Details',
      'Preview',
    ];

    return Container(
      padding: const EdgeInsets.only(top: 36, left: 24, right: 24, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFFFAFAFE),
        borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            _buildStepperItem(
              stepNumber: i + 1,
              title: steps[i],
              isCurrent: controller.currentStep.value == (i + 1),
              isCompleted: controller.currentStep.value > (i + 1),
              isLast: i == steps.length - 1,
            ),
          ],
          const SizedBox(height: 60),
          // Decorative bar-chart graphic matching reference screenshot
          _buildSidebarChartGraphic(),
        ],
      ),
    );
  }

  Widget _buildStepperItem({
    required int stepNumber,
    required String title,
    required bool isCurrent,
    required bool isCompleted,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? const Color(0xFF10B981)
                      : (isCurrent ? primaryNavy : Colors.transparent),
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF10B981)
                        : (isCurrent ? primaryNavy : const Color(0xFFCBD5E1)),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          '$stepNumber',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 24),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent
                      ? primaryNavy
                      : (isCompleted ? const Color(0xFF1E293B) : const Color(0xFF64748B)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarChartGraphic() {
    return Opacity(
      opacity: 0.35,
      child: CustomPaint(
        size: const Size(200, 70),
        painter: _ChartWavePainter(),
      ),
    );
  }

  Widget _buildMobileStepperHeader(ApplicantRegistrationController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Step ${controller.currentStep.value} of 6',
            style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy),
          ),
          Text(
            _getStepName(controller.currentStep.value),
            style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ],
      ),
    );
  }

  String _getStepName(int step) {
    switch (step) {
      case 1:
        return 'Personal Information';
      case 2:
        return 'Contact Information';
      case 3:
        return 'Educational Details';
      case 4:
        return 'Professional Qualification';
      case 5:
        return 'Occupational Details';
      case 6:
        return 'Preview';
      default:
        return '';
    }
  }

  Widget _buildStepContent(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    final step = controller.currentStep.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step < 6)
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'All fields marked with * are mandatory',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
            ),
          ),
        const SizedBox(height: 18),
        if (step == 1) _buildStep1Personal(context, controller, isMobile),
        if (step == 2) _buildStep2Contact(context, controller, isMobile),
        if (step == 3) _buildStep3Education(context, controller, isMobile),
        if (step == 4) _buildStep4Professional(context, controller, isMobile),
        if (step == 5) _buildStep5Occupational(context, controller, isMobile),
        if (step == 6) _buildStep6Preview(context, controller, isMobile),
        const SizedBox(height: 40),
        _buildBottomNavButtons(controller, isLastStep: step == 6, isMobile: isMobile),
      ],
    );
  }

  // ==========================================
  // STEP 1: PERSONAL INFORMATION (IMAGES 2 & 3)
  // ==========================================

  Widget _buildStep1Personal(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upload boxes: Candidate's Photo & Image of Proof of Address
        _buildResponsiveRow(
          isMobile,
          [
            _buildUploadBox(
              title: "Candidate's Photo *",
              specText: 'View Photograph Specifications',
              uploadedUrlObs: controller.photoUrl,
              onTap: () => controller.pickAndUploadDoc('photo'),
              onSpecTap: () => _showSpecDialog(context, 'Photograph Specifications', '1. In JPEG/JPG format below 1MB.\n2. Recent passport-sized photograph on plain light background.\n3. Clear full face view.'),
            ),
            _buildUploadBox(
              title: 'Image of Proof of Address *',
              specText: 'View POA Specifications',
              uploadedUrlObs: controller.proofOfAddressUrl,
              onTap: () => controller.pickAndUploadDoc('aadhaar'),
              onSpecTap: () => _showSpecDialog(context, 'Proof of Address Specifications', '1. Scan copy of selected address proof.\n2. Both front and back pages in JPG or PDF format below 1MB.'),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Proof of Address Type
        Obx(
          () => DropdownButtonFormField<String>(
            value: controller.selectedProofOfAddress.value,
            decoration: InputDecoration(
              labelText: 'Proof of Address Type *',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
            items: ['Aadhaar', 'Passport', 'Voter ID', 'Driving License']
                .map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13))))
                .toList(),
            onChanged: (val) => controller.selectedProofOfAddress.value = val ?? 'Aadhaar',
          ),
        ),
        const SizedBox(height: 24),

        // Notice: Name and DOB as per Government ID
        const Text(
          '* Name (First Name, Middle Name, Last Name) and Date of Birth should be as per Government ID / Proof of Address.',
          style: TextStyle(color: Color(0xFFDC2626), fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),

        // Title + First Name & Middle Name
        _buildResponsiveRow(
          isMobile,
          [
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Obx(
                    () => DropdownButtonFormField<String>(
                      value: controller.selectedTitle.value,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                      ),
                      items: ['Mr', 'Ms', 'Mrs']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (val) => controller.selectedTitle.value = val ?? 'Mr',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    controller: controller.firstNameController,
                    label: 'First Name *',
                    hint: 'First name',
                  ),
                ),
              ],
            ),
            _buildTextField(
              controller: controller.middleNameController,
              label: 'Middle Name',
              hint: 'Enter Middle Name',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Last Name & Father's Name
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.lastNameController,
              label: 'Last Name *',
              hint: 'Last name',
            ),
            _buildTextField(
              controller: controller.fatherNameController,
              label: "Father's Name *",
              hint: "Enter Father's name",
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Date of Birth & Alternate Email
        _buildResponsiveRow(
          isMobile,
          [
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().subtract(const Duration(days: 365 * 22)),
                  firstDate: DateTime(1950),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  controller.dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                }
              },
              child: IgnorePointer(
                child: _buildTextField(
                  controller: controller.dobController,
                  label: 'Date of Birth *',
                  hint: 'YYYY-MM-DD',
                  suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                ),
              ),
            ),
            _buildTextField(
              controller: controller.alternateEmailController,
              label: 'Alternate Email ID',
              hint: 'secondary@example.com',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Gender & Marital Status
        _buildResponsiveRow(
          isMobile,
          [
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedGender.value,
                decoration: InputDecoration(
                  labelText: 'Gender *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => controller.selectedGender.value = val ?? 'Male',
              ),
            ),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedMaritalStatus.value,
                decoration: InputDecoration(
                  labelText: 'Marital Status *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: ['Single', 'Married', 'Divorced', 'Other']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => controller.selectedMaritalStatus.value = val ?? 'Single',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Current Location & LinkedIn / Skype
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.currentLocationController,
              label: 'Current Location (City) *',
              hint: 'e.g. Indore, MP',
            ),
            _buildTextField(
              controller: controller.skypeAddressController,
              label: 'LinkedIn Profile / Skype ID',
              hint: 'e.g. linkedin.com/in/username',
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Position Applied For (Live Job Openings)
        _buildRoleSelector(context, controller),
      ],
    );
  }

  // ==========================================
  // STEP 2: CONTACT INFORMATION (IMAGE 4)
  // ==========================================

  Widget _buildStep2Contact(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Current Address',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
        ),
        const SizedBox(height: 14),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.addressLine1Controller, label: 'Address Line 1 *', hint: 'Flat, House No, Building'),
            _buildTextField(controller: controller.addressLine2Controller, label: 'Address Line 2', hint: 'Street, Sector, Area'),
          ],
        ),
        const SizedBox(height: 16),

        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.addressLine3Controller, label: 'Address Line 3', hint: 'Landmark / Colony'),
            _buildTextField(controller: controller.cityController, label: 'City *', hint: 'City name'),
          ],
        ),
        const SizedBox(height: 16),

        _buildResponsiveRow(
          isMobile,
          [
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedCountry.value,
                decoration: InputDecoration(labelText: 'Country *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: ['India', 'Others'].map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => controller.selectedCountry.value = val ?? 'India',
              ),
            ),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedState.value,
                decoration: InputDecoration(labelText: 'State *', border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                items: [
                  'Madhya Pradesh',
                  'Maharashtra',
                  'Delhi',
                  'Gujarat',
                  'Rajasthan',
                  'Uttar Pradesh',
                  'Karnataka',
                  'Tamil Nadu',
                  'Other'
                ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => controller.selectedState.value = val ?? 'Madhya Pradesh',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.pincodeController, label: 'Pincode', hint: '6-digit pincode'),
            Row(
              children: [
                SizedBox(
                  width: 90,
                  child: _buildTextField(controller: controller.telephoneResidenceCodeController, label: 'Code', hint: '+91'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(controller: controller.telephoneResidenceNumberController, label: 'Telephone Residence', hint: 'STD or Number'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Permanent Address Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Permanent Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
            ),
            Obx(
              () => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: controller.sameAsCurrentAddress.value,
                    onChanged: (val) => controller.toggleSameAsCurrentAddress(val ?? false),
                    activeColor: primaryNavy,
                  ),
                  const Text(
                    'Same as Current Address',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.permanentStreetController,
              label: 'Permanent Street / Address *',
              hint: 'Street, House No, Area',
            ),
            _buildTextField(
              controller: controller.permanentCityController,
              label: 'Permanent City *',
              hint: 'City name',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.permanentStateController,
              label: 'Permanent State *',
              hint: 'State name',
            ),
            _buildTextField(
              controller: controller.permanentZipController,
              label: 'Permanent Pincode *',
              hint: '6-digit pincode',
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Mobile Number Verification Card (Image 4 exact parity)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mobile Number *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: controller.phoneController,
                        enabled: !controller.isMobileVerified.value,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Enter 10-digit mobile number',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: controller.isMobileVerified.value,
                          fillColor: const Color(0xFFF1F5F9),
                          suffixIcon: controller.isMobileVerified.value
                              ? const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22)
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (!controller.isMobileVerified.value)
                      ElevatedButton(
                        onPressed: (controller.isVerifyingMobile.value || controller.mobileOtpCountdown.value > 0)
                            ? null
                            : controller.handleSendMobileOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.mobileOtpCountdown.value > 0
                              ? const Color(0xFF94A3B8)
                              : primaryNavy,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: controller.isVerifyingMobile.value
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                controller.mobileOtpCountdown.value > 0
                                    ? 'Retry in ${controller.mobileOtpCountdown.value}s'
                                    : (controller.isMobileOtpSent.value ? 'Resend' : 'Verify'),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Mobile Verified status label or Inline OTP input (Hidden until Verify is tapped)
              Obx(() {
                if (controller.isMobileVerified.value) {
                  return const Row(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 16, color: Color(0xFF10B981)),
                      SizedBox(width: 6),
                      Text(
                        'Mobile Verified',
                        style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  );
                }

                if (!controller.isMobileOtpSent.value) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter the OTP received on SMS to verify mobile number on this screen:',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: controller.mobileOtpInputController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              hintText: '4-digit OTP',
                              counterText: '',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: controller.handleVerifyMobileOtp,
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                          child: const Text('Submit OTP'),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: EDUCATIONAL DETAILS (IMAGE 5)
  // ==========================================

  Widget _buildStep3Education(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResponsiveRow(
          isMobile,
          [
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.highestQualification.value,
                decoration: InputDecoration(
                  labelText: 'Highest Qualification',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['Graduation', 'Post graduation', '12th', '10th', 'Diploma', 'Doctorate']
                    .map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => controller.highestQualification.value = val ?? 'Graduation',
              ),
            ),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.majorSubject.value,
                decoration: InputDecoration(
                  labelText: 'Major Subject',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['Engineering', 'Commerce', 'Science', 'Arts', 'Management', 'Finance', 'Other']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => controller.majorSubject.value = val ?? 'Engineering',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.instituteUniversityController,
              label: 'Institute/University',
              hint: 'e.g. Vaishnav Vidyapeeth',
            ),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.yearOfPassing.value,
                decoration: InputDecoration(
                  labelText: 'Year Of Passing',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: List.generate(25, (index) => (2026 - index).toString())
                    .map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => controller.yearOfPassing.value = val ?? '2023',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.percentageGradeController,
              label: 'Percentage/Grade',
              hint: 'e.g. 7.9 or 75%',
            ),
            _buildTextField(
              controller: controller.backlogsCountController,
              label: 'Total Backlogs / ATKTs (if any)',
              hint: 'e.g. 0',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Academic Gap Toggle & Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Any Gap during Academic Education?',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF334155)),
                    ),
                    Row(
                      children: [
                        const Text('No', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                        Switch(
                          value: controller.academicGap.value,
                          onChanged: (val) => controller.academicGap.value = val,
                          activeColor: primaryNavy,
                        ),
                        const Text('Yes', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                if (controller.academicGap.value) ...[
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: controller.academicGapDetailsController,
                    label: 'Academic Gap Details',
                    hint: 'e.g. 1 year gap due to competitive exams preparation',
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Degree Document Upload
        _buildUploadBox(
          title: 'Highest Qualification Degree / Marksheet',
          specText: 'View Degree Specifications',
          uploadedUrlObs: controller.highestEducationUrl,
          onTap: () => controller.pickAndUploadDoc('highestEducation'),
          onSpecTap: () => _showSpecDialog(context, 'Degree Specifications', '1. Clear scan or PDF of Degree Certificate or final Marksheet.\n2. PDF or JPG format below 5MB.'),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: PROFESSIONAL QUALIFICATION (MOCKUP)
  // ==========================================

  Widget _buildStep4Professional(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResponsiveRow(
          isMobile,
          [
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedProfessionalCert.value,
                decoration: InputDecoration(
                  labelText: 'Professional Certification',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ['None', 'NISM Series XV (Research Analyst)', 'NISM Series VIII (Equity Derivatives)', 'CA', 'CFA', 'CS', 'CFP']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) => controller.selectedProfessionalCert.value = val ?? 'None',
              ),
            ),
            _buildTextField(
              controller: controller.certRegistrationNumberController,
              label: 'Certificate Registration Number',
              hint: 'e.g. NISM-2023-XXXXX',
            ),
          ],
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: controller.certYearController,
          label: 'Year of Certification',
          hint: 'e.g. 2023',
        ),
        const SizedBox(height: 20),

        _buildUploadBox(
          title: 'Upload Certificate Copy (PDF or JPG)',
          specText: 'View Certificate Specifications',
          uploadedUrlObs: controller.certDocumentUrl,
          onTap: () => controller.pickAndUploadDoc('certificate'),
          onSpecTap: () => _showSpecDialog(context, 'Certificate Specifications', 'PDF or JPG format below 5MB.'),
        ),
        const SizedBox(height: 16),

        _buildTextField(
          controller: controller.licenseMembershipDetailsController,
          label: 'License / Membership Details',
          hint: 'Any relevant memberships or registrations',
        ),
      ],
    );
  }

  // ==========================================
  // STEP 5: OCCUPATIONAL DETAILS (MOCKUP)
  // ==========================================

  Widget _buildStep5Occupational(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Total Work Experience Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Work Experience',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: primaryNavy),
            ),
            Obx(
              () => Row(
                children: [
                  const Text('Experienced', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  Switch(
                    value: controller.isFresher.value,
                    onChanged: (val) => controller.isFresher.value = val,
                    activeColor: const Color(0xFF10B981),
                  ),
                  const Text('Fresher', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Obx(() {
          if (controller.isFresher.value) {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
              child: const Text('Fresher selected: Work experience details are optional.', style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF))),
            );
          }

          return Column(
            children: [
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.currentCompanyController, label: 'Current / Previous Company Name *', hint: 'Company name'),
                  _buildTextField(controller: controller.currentDesignationController, label: 'Current Designation *', hint: 'e.g. Analyst / Executive'),
                ],
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.reportingManagerController, label: 'Reporting Manager Name', hint: "Manager's name"),
                  _buildTextField(controller: controller.reportingManagerDesignationController, label: 'Reporting Manager Designation', hint: 'e.g. Team Lead / VP'),
                ],
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.totalExperienceYearsController, label: 'Total Experience (Years) *', hint: 'e.g. 2.5'),
                  _buildTextField(controller: controller.reporteesCountController, label: 'Number of Direct Reportees', hint: 'e.g. 0 or 4'),
                ],
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.fixedSalaryController, label: 'Fixed Salary (Monthly) *', hint: 'e.g. 25,000'),
                  _buildTextField(controller: controller.bonusIncentiveController, label: 'Bonus / Variable / Incentive', hint: 'e.g. 5,000'),
                ],
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.annualCtcController, label: 'Current Total CTC (Annual) *', hint: 'e.g. 3,60,000'),
                  _buildTextField(controller: controller.expectedSalaryController, label: 'Expected CTC (Annual) *', hint: 'e.g. 4,50,000'),
                ],
              ),
              const SizedBox(height: 16),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.noticePeriodDaysController, label: 'Notice Period (Days) *', hint: 'e.g. 15 or 30 or Immediate'),
                  _buildTextField(controller: controller.careerGapController, label: 'Career Gap Details (if any)', hint: 'Reason for employment gap'),
                ],
              ),
              const SizedBox(height: 16),
              _buildUploadBox(
                title: 'Upload Relieving Letter *',
                specText: 'View Relieving Letter Specifications',
                uploadedUrlObs: controller.relievingLetterUrl,
                onTap: () => controller.pickAndUploadDoc('relievingLetter'),
                onSpecTap: () => _showSpecDialog(context, 'Relieving Letter Specifications', '1. Relieving letter or experience certificate from last employer.\n2. PDF or JPG format below 5MB.'),
              ),
            ],
          );
        }),

        const SizedBox(height: 24),
        // Resume / CV Upload
        _buildUploadBox(
          title: 'Upload Updated Resume / CV *',
          specText: 'View Resume Specifications',
          uploadedUrlObs: controller.resumeUrl,
          onTap: () => controller.pickAndUploadDoc('resume'),
          onSpecTap: () => _showSpecDialog(context, 'Resume Specifications', '1. PDF format below 5MB.\n2. Ensure contact details, education, and work experience are up to date.'),
        ),

        const SizedBox(height: 32),
        const Text(
          'Emergency Contact Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
        ),
        const SizedBox(height: 14),

        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.emergencyNameController, label: 'Contact Person Name *', hint: 'Full name'),
            _buildTextField(controller: controller.emergencyRelationController, label: 'Relationship *', hint: 'e.g. Parent, Spouse'),
            _buildTextField(controller: controller.emergencyPhoneController, label: 'Contact Number *', hint: '10-digit number'),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 6: PREVIEW & SUBMISSION (MOCKUP)
  // ==========================================

  Widget _buildStep6Preview(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Application Preview & Review',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please review your application details carefully before final submission. Click Edit on any section to modify details.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),

        // Personal Information Card
        _buildPreviewCard(
          title: 'Personal Information',
          onEdit: () => controller.goToStep(1),
          children: [
            _buildPreviewRow('Full Name:', '${controller.selectedTitle.value} ${controller.firstNameController.text} ${controller.middleNameController.text} ${controller.lastNameController.text}'.replaceAll(RegExp(r'\s+'), ' ').trim(), isMobile: isMobile),
            _buildPreviewRow("Father's Name:", controller.fatherNameController.text, isMobile: isMobile),
            _buildPreviewRow('Date of Birth:', controller.dobController.text, isMobile: isMobile),
            _buildPreviewRow('Gender & Marital Status:', '${controller.selectedGender.value} | ${controller.selectedMaritalStatus.value}', isMobile: isMobile),
            _buildPreviewRow('Current Location:', controller.currentLocationController.text, isMobile: isMobile),
            if (controller.skypeAddressController.text.isNotEmpty)
              _buildPreviewRow('LinkedIn / Skype:', controller.skypeAddressController.text, isMobile: isMobile),
            _buildPreviewRow('Applied Position:', controller.appliedPositionController.text.isNotEmpty ? controller.appliedPositionController.text : 'Candidate', isMobile: isMobile),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildDocBadge('Photo', controller.photoUrl.value.isNotEmpty),
                _buildDocBadge('Address Proof', controller.proofOfAddressUrl.value.isNotEmpty),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Contact Information Card
        _buildPreviewCard(
          title: 'Contact Information',
          onEdit: () => controller.goToStep(2),
          children: [
            _buildPreviewRow('Current Address:', '${controller.addressLine1Controller.text}, ${controller.cityController.text}, ${controller.selectedState.value} - ${controller.pincodeController.text}', isMobile: isMobile),
            _buildPreviewRow('Permanent Address:', '${controller.permanentStreetController.text}, ${controller.permanentCityController.text}, ${controller.permanentStateController.text} - ${controller.permanentZipController.text}', isMobile: isMobile),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFA7F3D0))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF059669), size: 14),
                      const SizedBox(width: 4),
                      Text('Mobile Verified: +91 ${controller.phoneController.text} (Locked)', style: const TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6), border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 14),
                      const SizedBox(width: 4),
                      Text('Email Verified: ${controller.createAccountEmailController.text} (Locked)', style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Education Card
        _buildPreviewCard(
          title: 'Educational Details',
          onEdit: () => controller.goToStep(3),
          children: [
            _buildPreviewRow('Highest Qualification:', controller.highestQualification.value, isMobile: isMobile),
            _buildPreviewRow('Major Subject:', controller.majorSubject.value, isMobile: isMobile),
            _buildPreviewRow('Institute / University:', controller.instituteUniversityController.text, isMobile: isMobile),
            _buildPreviewRow('Year of Passing:', controller.yearOfPassing.value, isMobile: isMobile),
            _buildPreviewRow('Percentage / Grade:', controller.percentageGradeController.text, isMobile: isMobile),
            _buildPreviewRow('Academic Gap:', controller.academicGap.value ? (controller.academicGapDetailsController.text.isNotEmpty ? controller.academicGapDetailsController.text : 'Yes') : 'None', isMobile: isMobile),
            if (controller.backlogsCountController.text.isNotEmpty)
              _buildPreviewRow('Backlogs / ATKTs:', controller.backlogsCountController.text, isMobile: isMobile),
            const SizedBox(height: 6),
            _buildDocBadge('Degree / Marksheet', controller.highestEducationUrl.value.isNotEmpty),
          ],
        ),
        const SizedBox(height: 16),

        // Professional Qualification Card
        _buildPreviewCard(
          title: 'Professional Qualification',
          onEdit: () => controller.goToStep(4),
          children: [
            _buildPreviewRow('Certification:', controller.selectedProfessionalCert.value, isMobile: isMobile),
            if (controller.selectedProfessionalCert.value != 'None') ...[
              _buildPreviewRow('Registration Number:', controller.certRegistrationNumberController.text, isMobile: isMobile),
              _buildPreviewRow('Year:', controller.certYearController.text, isMobile: isMobile),
              const SizedBox(height: 6),
              _buildDocBadge('Certificate Document', controller.certDocumentUrl.value.isNotEmpty),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Occupational & Work Experience Card
        _buildPreviewCard(
          title: 'Occupational & Work Experience',
          onEdit: () => controller.goToStep(5),
          children: [
            _buildPreviewRow('Experience Status:', controller.isFresher.value ? 'Fresher' : 'Experienced (${controller.totalExperienceYearsController.text} Years)', isMobile: isMobile),
            if (!controller.isFresher.value) ...[
              _buildPreviewRow('Current / Previous Company:', controller.currentCompanyController.text, isMobile: isMobile),
              _buildPreviewRow('Current Designation:', controller.currentDesignationController.text, isMobile: isMobile),
              if (controller.reportingManagerController.text.isNotEmpty)
                _buildPreviewRow('Reporting Manager:', '${controller.reportingManagerController.text} (${controller.reportingManagerDesignationController.text})', isMobile: isMobile),
              if (controller.reporteesCountController.text.isNotEmpty)
                _buildPreviewRow('Direct Reportees:', controller.reporteesCountController.text, isMobile: isMobile),
              _buildPreviewRow('Fixed Salary (Monthly):', controller.fixedSalaryController.text, isMobile: isMobile),
              if (controller.bonusIncentiveController.text.isNotEmpty)
                _buildPreviewRow('Variable / Incentive:', controller.bonusIncentiveController.text, isMobile: isMobile),
              _buildPreviewRow('Current Annual CTC:', controller.annualCtcController.text, isMobile: isMobile),
              _buildPreviewRow('Expected Annual CTC:', controller.expectedSalaryController.text, isMobile: isMobile),
              _buildPreviewRow('Notice Period:', '${controller.noticePeriodDaysController.text} Days', isMobile: isMobile),
              if (controller.careerGapController.text.isNotEmpty)
                _buildPreviewRow('Career Gap:', controller.careerGapController.text, isMobile: isMobile),
            ],
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildDocBadge('Updated Resume / CV', controller.resumeUrl.value.isNotEmpty),
                if (!controller.isFresher.value)
                  _buildDocBadge('Relieving Letter', controller.relievingLetterUrl.value.isNotEmpty),
              ],
            ),
            const Divider(height: 20),
            _buildPreviewRow('Emergency Contact:', '${controller.emergencyNameController.text} (${controller.emergencyRelationController.text}) - ${controller.emergencyPhoneController.text}', isMobile: isMobile),
          ],
        ),
      ],
    );
  }

  Widget _buildDocBadge(String label, bool isUploaded) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isUploaded ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isUploaded ? Icons.check_circle_outline : Icons.pending_outlined, size: 13, color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          const SizedBox(width: 4),
          Text(
            '$label: ${isUploaded ? "Uploaded" : "Pending"}',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard({
    required String title,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: primaryNavy)),
              InkWell(
                onTap: onEdit,
                child: const Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 4),
                    Text('Edit', style: TextStyle(fontSize: 12.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, {bool isMobile = false}) {
    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF64748B))),
          ),
          Expanded(
            child: Text(value.isNotEmpty ? value : 'N/A', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED FORM ATOMS & BOTTOM BUTTONS
  // ==========================================

  Widget _buildBottomNavButtons(ApplicantRegistrationController controller, {required bool isLastStep, required bool isMobile}) {
    if (isMobile) {
      return Row(
        children: [
          if (controller.currentStep.value > 1) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: controller.previousStep,
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryNavy,
                  side: const BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : (isLastStep ? controller.handleFinalSubmission : controller.nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isLastStep ? 'Submit Application' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (controller.currentStep.value > 1) ...[
          OutlinedButton(
            onPressed: controller.previousStep,
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryNavy,
              side: const BorderSide(color: borderColor),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 14),
        ],
        ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : (isLastStep ? controller.handleFinalSubmission : controller.nextStep),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: controller.isLoading.value
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isLastStep ? 'Submit Application' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required String title,
    required String specText,
    required RxString uploadedUrlObs,
    required VoidCallback onTap,
    required VoidCallback onSpecTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
            InkWell(
              onTap: onSpecTap,
              child: Text(
                specText,
                style: const TextStyle(fontSize: 12, color: Color(0xFF2563EB), decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final hasFile = uploadedUrlObs.value.isNotEmpty;
          final fileName = hasFile ? uploadedUrlObs.value.split('/').last : '';

          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                color: hasFile ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                border: Border.all(
                  color: hasFile ? const Color(0xFF86EFAC) : const Color(0xFF94A3B8),
                  style: BorderStyle.solid,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: hasFile
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 20),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              fileName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF065F46)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.edit, size: 16, color: Color(0xFF64748B)),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 26, color: Color(0xFF64748B)),
                          SizedBox(height: 6),
                          Text('Click or drag file to upload', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showSpecDialog(BuildContext context, String title, String body) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: primaryNavy, fontSize: 16)),
        content: Text(body, style: const TextStyle(fontSize: 13.5, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleSelector(BuildContext context, ApplicantRegistrationController controller) {
    return Obx(() {
      final roles = controller.openRoles;
      return DropdownButtonFormField<String>(
        value: controller.appliedPositionController.text.isNotEmpty ? controller.appliedPositionController.text : null,
        decoration: InputDecoration(
          labelText: 'Position Applied For *',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: roles.isEmpty
            ? [
                const DropdownMenuItem(value: 'Complience Executive', child: Text('Complience Executive')),
                const DropdownMenuItem(value: 'Research Analyst', child: Text('Research Analyst')),
              ]
            : roles.map((r) {
                final name = r['name']?.toString() ?? '';
                return DropdownMenuItem(value: name, child: Text(name, style: const TextStyle(fontSize: 13)));
              }).toList(),
        onChanged: (val) {
          if (val != null) controller.appliedPositionController.text = val;
        },
      );
    });
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children) {
    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            children[i],
          ],
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 14),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _buildSubmissionSuccess(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0F000000), blurRadius: 30, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF10B981)),
          const SizedBox(height: 16),
          const Text(
            'Application Submitted Successfully!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryNavy),
          ),
          const SizedBox(height: 10),
          Text(
            'Your application ID is: ${controller.submittedApplicantId.value.isNotEmpty ? controller.submittedApplicantId.value : controller.applicantId.value}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Our HR & Recruitment team will carefully review your credentials and contact you regarding the next steps.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13.5, height: 1.5),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Get.offAllNamed('/'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryNavy,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for the decorative line chart in stepper sidebar
class _ChartWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(size.width * 0.25, size.height * 0.2, size.width * 0.5, size.height * 0.5);
    path.quadraticBezierTo(size.width * 0.75, size.height * 0.8, size.width, size.height * 0.3);

    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 3.5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.2), 3.5, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.8), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
