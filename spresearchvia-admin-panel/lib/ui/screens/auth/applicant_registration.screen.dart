import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_registration.controller.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';

class ApplicantRegistrationScreen extends StatelessWidget {
  const ApplicantRegistrationScreen({super.key});

  static const Color primaryNavy = Color(0xFF1E2265);
  static const Color leftPaneBg = Color(0xFF545398);
  static const Color borderColor = Color(0xFFCBD5E1);

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<ApplicantRegistrationController>()
        ? Get.find<ApplicantRegistrationController>()
        : Get.put(ApplicantRegistrationController());

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
          _buildPrerequisiteItem('1. Recent Passport Size Profile Photo (in JPG/PNG format, below 2MB)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('2. Updated Resume / Curriculum Vitae (PDF format, below 5MB)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('3. Valid Aadhaar Card (Front and Back both mandatory) & 12-digit Number (in JPG/PNG/PDF format, below 2MB)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('4. Valid PAN Card (Optional, in JPG/PNG/PDF format, below 2MB)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('5. Educational degree / marksheets (Highest degree certificate)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('6. NISM or Professional Certification (Optional, if applicable)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('7. Previous employment details & relieving letter (if experienced candidate)'),
          const SizedBox(height: 16),
          _buildPrerequisiteItem('8. Device camera (mobile phone or laptop) for live Video KYC recording'),
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

  // Left Stepper Sidebar with decorative bottom artwork (3 Merged Steps)
  Widget _buildStepperSidebar(ApplicantRegistrationController controller) {
    final steps = [
      'Personal & Contact Details',
      'Education & Professional Details',
      'Occupational & KYC Details',
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
            'Step ${controller.currentStep.value} of 3',
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
        return 'Personal & Contact Details';
      case 2:
        return 'Education & Professional Details';
      case 3:
        return 'Occupational & KYC Details';
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
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'All fields marked with * are mandatory',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
        ),
        const SizedBox(height: 18),
        if (step == 1) _buildStep1PersonalAndContact(context, controller, isMobile),
        if (step == 2) _buildStep2EducationAndProfessional(context, controller, isMobile),
        if (step == 3) _buildStep3Occupational(context, controller, isMobile),
        const SizedBox(height: 40),
        _buildBottomNavButtons(context, controller, isLastStep: step == 3, isMobile: isMobile),
      ],
    );
  }

  // ==========================================
  // STEP 1: PERSONAL & CONTACT INFORMATION
  // ==========================================

  Widget _buildStep1PersonalAndContact(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Upload boxes: Profile Photo *, Resume/CV *, Aadhaar Card *, and PAN Card (Optional)
        _buildDocumentsGrid(
          children: [
            _buildUploadBox(
              context: context,
              title: "Profile Photo *",
              specText: 'View Photo Specs',
              uploadedUrlObs: controller.photoUrl,
              onTap: () => controller.pickAndUploadDoc('photo'),
              onSpecTap: () => _showSpecDialog(context, 'Profile Photo Specifications', '1. Clear front-facing or passport size photograph.\n2. In JPG or PNG format below 2MB.'),
            ),
            _buildUploadBox(
              context: context,
              title: "Resume / CV *",
              specText: 'View Resume Specifications',
              uploadedUrlObs: controller.resumeUrl,
              onTap: () => controller.pickAndUploadDoc('resume'),
              onSpecTap: () => _showSpecDialog(context, 'Resume Specifications', '1. In PDF, DOC, DOCX format below 5MB.\n2. Ensure contact information, education, and career history are accurate.'),
            ),
            _buildUploadBox(
              context: context,
              title: 'Aadhaar Card (Front) *',
              specText: 'View Specifications',
              uploadedUrlObs: controller.proofOfAddressUrl,
              onTap: () => controller.pickAndUploadDoc('aadhaarFront'),
              onSpecTap: () => _showSpecDialog(context, 'Aadhaar (Front) Specifications', '1. Clear photo or scanned copy of Aadhaar Card front side showing your photo and name.\n2. In JPG, PNG, or PDF format below 2MB.'),
            ),
            _buildUploadBox(
              context: context,
              title: 'Aadhaar Card (Back) *',
              specText: 'View Specifications',
              uploadedUrlObs: controller.aadhaarBackUrl,
              onTap: () => controller.pickAndUploadDoc('aadhaarBack'),
              onSpecTap: () => _showSpecDialog(context, 'Aadhaar (Back) Specifications', '1. Clear photo or scanned copy of Aadhaar Card back side showing your address.\n2. In JPG, PNG, or PDF format below 2MB.'),
            ),
            _buildUploadBox(
              context: context,
              title: 'PAN Card (Optional)',
              specText: 'View PAN Specifications',
              uploadedUrlObs: controller.panUrl,
              onTap: () => controller.pickAndUploadDoc('pan'),
              onSpecTap: () => _showSpecDialog(context, 'PAN Card Specifications', '1. Clear photo or scanned copy of PAN Card (Optional).\n2. In JPG, PNG, or PDF format below 2MB.'),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Notice: Name and DOB as per Government ID / Aadhaar Card
        const Text(
          '* Name (First Name, Middle Name, Last Name) and Date of Birth should be as per Government ID / Aadhaar Card.',
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

        // Aadhaar Number (Mandatory) & PAN Number (Optional)
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.aadhaarNumberController,
              label: 'Aadhaar Card Number *',
              hint: '12-digit Aadhaar number',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(12),
              ],
            ),
            _buildTextField(
              controller: controller.panNumberController,
              label: 'PAN Card Number (Optional)',
              hint: 'e.g. ABCDE1234F',
              inputFormatters: [
                LengthLimitingTextInputFormatter(10),
              ],
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
              label: 'Current City *',
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
        const SizedBox(height: 28),

        // Section: Current Address
        const Row(
          children: [
            Icon(Icons.location_on_outlined, color: primaryNavy, size: 20),
            SizedBox(width: 8),
            Text(
              'Current Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy),
            ),
          ],
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
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy),
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

        // Mobile Number Section (Direct input, no OTP verification needed!)
        Container(
          padding: const EdgeInsets.all(18),
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
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF334155)),
              ),
              const SizedBox(height: 8),
              Row(
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
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Enter 10-digit mobile number',
                        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 2: EDUCATIONAL & PROFESSIONAL DETAILS
  // ==========================================

  Widget _buildStep2EducationAndProfessional(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.school_outlined, color: primaryNavy, size: 20),
            SizedBox(width: 8),
            Text(
              'Educational Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy),
            ),
          ],
        ),
        const SizedBox(height: 14),
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

        _buildTextField(
          controller: controller.percentageGradeController,
          label: 'Percentage/Grade',
          hint: 'e.g. 7.9 or 75%',
        ),
        const SizedBox(height: 20),

        // Degree Document Upload
        _buildUploadBox(
          context: context,
          title: 'Highest Qualification Degree / Marksheet',
          specText: 'View Degree Specifications',
          uploadedUrlObs: controller.highestEducationUrl,
          onTap: () => controller.pickAndUploadDoc('highestEducation'),
          onSpecTap: () => _showSpecDialog(context, 'Degree Specifications', '1. Clear scan or PDF of Degree Certificate or final Marksheet.\n2. PDF or JPG format below 5MB.'),
        ),
        const SizedBox(height: 32),

        // Professional Qualifications & NISM Section (With Toggle)
        const Row(
          children: [
            Icon(Icons.workspace_premium_outlined, color: primaryNavy, size: 20),
            SizedBox(width: 8),
            Text(
              'Professional & NISM Qualifications',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy),
            ),
          ],
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Do you have NISM or Professional Certification?',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Toggle YES if you have a certificate to select and upload. If not, keep this OFF.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Text('No', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Switch(
                          value: controller.hasNismCert.value,
                          onChanged: (val) => controller.hasNismCert.value = val,
                          activeColor: primaryNavy,
                        ),
                        const Text('Yes', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                if (controller.hasNismCert.value) ...[
                  const Divider(height: 28),
                  DropdownButtonFormField<String>(
                    value: controller.selectedProfessionalCert.value == 'None'
                        ? 'NISM Series XV (Research Analyst)'
                        : controller.selectedProfessionalCert.value,
                    decoration: InputDecoration(
                      labelText: 'Select Certification *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      'NISM Series XV (Research Analyst)',
                      'NISM Series VIII (Equity Derivatives)',
                      'NISM Series X-A (Investment Adviser Level 1)',
                      'NISM Series X-B (Investment Adviser Level 2)',
                      'CA',
                      'CFA',
                      'CS',
                      'CFP',
                      'Other Certification'
                    ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (val) => controller.selectedProfessionalCert.value = val ?? 'NISM Series XV (Research Analyst)',
                  ),
                  const SizedBox(height: 18),
                  _buildUploadBox(
                    context: context,
                    title: 'Upload Certificate Copy (PDF or JPG) *',
                    specText: 'View Certificate Specifications',
                    uploadedUrlObs: controller.certDocumentUrl,
                    onTap: () => controller.pickAndUploadDoc('certificate'),
                    onSpecTap: () => _showSpecDialog(context, 'Certificate Specifications', 'PDF or JPG format below 5MB.'),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: controller.licenseMembershipDetailsController,
                    label: 'Certificate / Membership / Registration Number',
                    hint: 'e.g. NISM-2023-XXXXX or registration number',
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: OCCUPATIONAL & KYC DETAILS
  // ==========================================

  Widget _buildStep3Occupational(
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
                context: context,
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
        const Text(
          'Emergency Contact Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
        ),
        const SizedBox(height: 14),

        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.emergencyNameController,
              label: 'Contact Person Name *',
              hint: 'Full name',
            ),
            Obx(
              () => DropdownButtonFormField<String>(
                value: ['Mother', 'Father', 'Friend', 'Sister', 'Brother', 'Other']
                        .contains(controller.selectedEmergencyRelation.value)
                    ? controller.selectedEmergencyRelation.value
                    : 'Mother',
                decoration: InputDecoration(
                  labelText: 'Relationship *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
                items: ['Mother', 'Father', 'Friend', 'Sister', 'Brother', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    controller.selectedEmergencyRelation.value = val;
                    if (val != 'Other') {
                      controller.emergencyRelationController.text = val;
                    }
                  }
                },
              ),
            ),
            _buildTextField(
              controller: controller.emergencyPhoneController,
              label: 'Contact Number (Digits Only) *',
              hint: '10-digit mobile number',
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
            ),
          ],
        ),
        Obx(() {
          if (controller.selectedEmergencyRelation.value == 'Other') {
            return Padding(
              padding: const EdgeInsets.only(top: 14),
              child: _buildTextField(
                controller: controller.otherRelationController,
                label: 'Specify Other Relationship *',
                hint: 'e.g. Uncle / Guardian / Relative',
              ),
            );
          }
          return const SizedBox.shrink();
        }),

        const SizedBox(height: 32),
        const Text(
          'Video KYC Verification',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
        ),
        const SizedBox(height: 6),
        const Text(
          'Live Video KYC recording with your device camera is mandatory for applicant verification.',
          style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),

        Obx(() {
          final hasVideo = controller.kycVideoUrl.value.isNotEmpty;
          final isUploading = controller.isUploadingVideo.value;

          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: hasVideo ? const Color(0xFFF0FDF4) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasVideo ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                width: hasVideo ? 1.5 : 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: hasVideo ? const Color(0xFFDCFCE7) : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        hasVideo ? Icons.check_circle_rounded : Icons.videocam_rounded,
                        color: hasVideo ? const Color(0xFF10B981) : primaryNavy,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasVideo ? 'Video KYC Completed' : 'Record Video KYC *',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasVideo
                                ? 'Verification video successfully recorded and verified.'
                                : 'Use your mobile camera or laptop webcam to record your live verification declaration.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: hasVideo ? const Color(0xFF059669) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: isUploading ? null : () => controller.handleVideoKyc(context),
                      icon: isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(hasVideo ? Icons.refresh_rounded : Icons.videocam_rounded, size: 18),
                      label: Text(hasVideo ? 'Re-record Video KYC' : 'Record Video KYC with Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasVideo ? const Color(0xFF059669) : primaryNavy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (hasVideo) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          final fullUrl = AppConfig.buildImageUrl(controller.kycVideoUrl.value);
                          showDialog(
                            context: context,
                            builder: (ctx) => FilePreviewDialog(
                              fileName: 'Video KYC Recording',
                              fileUrl: fullUrl,
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: const Text('Preview Video'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryNavy,
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, color: Color(0xFF059669), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Recorded (${controller.kycVideoUrl.value.split('/').last})',
                              style: const TextStyle(color: Color(0xFF065F46), fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Note: Live camera recording is mandatory. Uploading pre-recorded video files is disabled. If your device does not have a camera, you will be prompted to continue via mobile or a laptop with camera.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8), fontStyle: FontStyle.italic),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // PREVIEW DIALOG & CONTENT
  // ==========================================

  void _showPreviewDialog(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 36,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860, maxHeight: 850),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.assignment_outlined, color: primaryNavy, size: 22),
                          SizedBox(width: 10),
                          Text(
                            'Application Preview & Review',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryNavy),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        tooltip: 'Close Preview',
                      ),
                    ],
                  ),
                ),
                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: _buildPreviewContent(
                      dialogCtx,
                      controller,
                      isMobile,
                      inDialog: true,
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Back to Form', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Obx(
                        () => ElevatedButton(
                          onPressed: controller.isLoading.value
                              ? null
                              : () async {
                                  Navigator.of(dialogCtx).pop();
                                  await controller.submitApplicationFromStep3();
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: controller.isLoading.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.send_rounded, size: 16),
                                    SizedBox(width: 8),
                                    Text('Submit Form', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPreviewContent(
    BuildContext context,
    ApplicantRegistrationController controller,
    bool isMobile, {
    bool inDialog = false,
  }) {
    void goToStepAndDismiss(int step) {
      if (inDialog) {
        Navigator.of(context).pop();
      }
      controller.goToStep(step);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!inDialog) ...[
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
        ],

        // Step 1: Personal & Contact Information Card
        _buildPreviewCard(
          title: '1. Personal & Contact Information',
          onEdit: () => goToStepAndDismiss(1),
          children: [
            Obx(() {
              final photo = controller.photoUrl.value;
              return Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: photo.isNotEmpty ? NetworkImage(AppConfig.buildImageUrl(photo)) : null,
                    child: photo.isEmpty ? const Icon(Icons.person, size: 28, color: Color(0xFF94A3B8)) : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${controller.selectedTitle.value} ${controller.firstNameController.text} ${controller.middleNameController.text} ${controller.lastNameController.text}'.replaceAll(RegExp(r'\s+'), ' ').trim(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: primaryNavy),
                        ),
                        Text(
                          controller.appliedPositionController.text.isNotEmpty ? controller.appliedPositionController.text : 'Job Applicant',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 10),
            _buildPreviewRow("Father's Name:", controller.fatherNameController.text, isMobile: isMobile),
            _buildPreviewRow('Date of Birth:', controller.dobController.text, isMobile: isMobile),
            _buildPreviewRow('Gender & Marital Status:', '${controller.selectedGender.value} | ${controller.selectedMaritalStatus.value}', isMobile: isMobile),
            _buildPreviewRow('Current City:', controller.currentLocationController.text, isMobile: isMobile),
            if (controller.skypeAddressController.text.isNotEmpty)
              _buildPreviewRow('LinkedIn / Skype:', controller.skypeAddressController.text, isMobile: isMobile),
            _buildPreviewRow('Aadhaar Number *:', controller.aadhaarNumberController.text, isMobile: isMobile),
            _buildPreviewRow('PAN Number (Optional):', controller.panNumberController.text.isNotEmpty ? controller.panNumberController.text : 'Not Provided', isMobile: isMobile),
            _buildPreviewRow('Current Address:', '${controller.addressLine1Controller.text}, ${controller.cityController.text}, ${controller.selectedState.value} - ${controller.pincodeController.text}', isMobile: isMobile),
            _buildPreviewRow('Permanent Address:', '${controller.permanentStreetController.text}, ${controller.permanentCityController.text}, ${controller.permanentStateController.text} - ${controller.permanentZipController.text}', isMobile: isMobile),
            _buildPreviewRow('Mobile Number:', '+91 ${controller.phoneController.text}', isMobile: isMobile),
            _buildPreviewRow('Email Address:', '${controller.createAccountEmailController.text} (Verified)', isMobile: isMobile),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildDocBadge(context, 'Profile Photo *', controller.photoUrl.value.isNotEmpty, docUrl: controller.photoUrl.value),
                _buildDocBadge(context, 'Resume / CV *', controller.resumeUrl.value.isNotEmpty, docUrl: controller.resumeUrl.value),
                _buildDocBadge(context, 'Aadhaar Card (Front) *', controller.proofOfAddressUrl.value.isNotEmpty, docUrl: controller.proofOfAddressUrl.value),
                _buildDocBadge(context, 'Aadhaar Card (Back) *', controller.aadhaarBackUrl.value.isNotEmpty, docUrl: controller.aadhaarBackUrl.value),
                _buildDocBadge(context, 'PAN Card (Optional)', controller.panUrl.value.isNotEmpty, docUrl: controller.panUrl.value),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Step 2: Educational & Professional Qualifications Card
        _buildPreviewCard(
          title: '2. Educational & Professional Qualifications',
          onEdit: () => goToStepAndDismiss(2),
          children: [
            _buildPreviewRow('Highest Qualification:', controller.highestQualification.value, isMobile: isMobile),
            _buildPreviewRow('Major Subject:', controller.majorSubject.value, isMobile: isMobile),
            _buildPreviewRow('Institute / University:', controller.instituteUniversityController.text, isMobile: isMobile),
            _buildPreviewRow('Year of Passing:', controller.yearOfPassing.value, isMobile: isMobile),
            _buildPreviewRow('Percentage / Grade:', controller.percentageGradeController.text, isMobile: isMobile),
            const SizedBox(height: 6),
            _buildDocBadge(context, 'Degree / Marksheet *', controller.highestEducationUrl.value.isNotEmpty, docUrl: controller.highestEducationUrl.value),
            const Divider(height: 20),
            _buildPreviewRow('NISM Certified:', controller.hasNismCert.value ? 'Yes' : 'No (Optional)', isMobile: isMobile),
            if (controller.hasNismCert.value) ...[
              _buildPreviewRow('Certification Course:', controller.selectedProfessionalCert.value, isMobile: isMobile),
              if (controller.certRegistrationNumberController.text.isNotEmpty)
                _buildPreviewRow('Registration / Cert. No:', controller.certRegistrationNumberController.text, isMobile: isMobile),
              const SizedBox(height: 6),
              _buildDocBadge(context, 'NISM Certificate Document', controller.certDocumentUrl.value.isNotEmpty, docUrl: controller.certDocumentUrl.value),
            ],
          ],
        ),
        const SizedBox(height: 16),

        // Step 3: Occupational & KYC Details Card
        _buildPreviewCard(
          title: '3. Occupational & KYC Details',
          onEdit: () => goToStepAndDismiss(3),
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
                _buildDocBadge(context, 'Video KYC *', controller.kycVideoUrl.value.isNotEmpty, docUrl: controller.kycVideoUrl.value),
                if (!controller.isFresher.value)
                  _buildDocBadge(context, 'Relieving Letter *', controller.relievingLetterUrl.value.isNotEmpty, docUrl: controller.relievingLetterUrl.value),
              ],
            ),
            const Divider(height: 20),
            _buildPreviewRow('Emergency Contact:', '${controller.emergencyNameController.text} (${controller.selectedEmergencyRelation.value == 'Other' ? controller.otherRelationController.text : controller.selectedEmergencyRelation.value}) - ${controller.emergencyPhoneController.text}', isMobile: isMobile),
          ],
        ),
      ],
    );
  }

  Widget _buildDocBadge(BuildContext context, String label, bool isUploaded, {String? docUrl}) {
    return InkWell(
      onTap: (isUploaded && docUrl != null && docUrl.isNotEmpty)
          ? () {
              final fullUrl = AppConfig.buildImageUrl(docUrl);
              showDialog(
                context: context,
                builder: (ctx) => FilePreviewDialog(
                  fileName: label,
                  fileUrl: fullUrl,
                ),
              );
            }
          : null,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isUploaded ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isUploaded ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isUploaded ? Icons.check_circle_outline : Icons.pending_outlined, size: 14, color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
            const SizedBox(width: 5),
            Text(
              '$label: ${isUploaded ? "Uploaded" : "Pending"}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isUploaded ? const Color(0xFF16A34A) : const Color(0xFFDC2626)),
            ),
            if (isUploaded && docUrl != null && docUrl.isNotEmpty) ...[
              const SizedBox(width: 6),
              const Icon(Icons.visibility_outlined, size: 13, color: Color(0xFF2563EB)),
              const SizedBox(width: 2),
              const Text(
                'Preview',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF2563EB), decoration: TextDecoration.underline),
              ),
            ],
          ],
        ),
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

  Widget _buildBottomNavButtons(
    BuildContext context,
    ApplicantRegistrationController controller, {
    required bool isLastStep,
    required bool isMobile,
  }) {
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
            const SizedBox(width: 8),
          ],
          if (isLastStep) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showPreviewDialog(context, controller, isMobile),
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: controller.isLoading.value
                  ? null
                  : (isLastStep ? controller.submitApplicationFromStep3 : controller.nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: isLastStep ? const Color(0xFF059669) : primaryNavy,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: controller.isLoading.value
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isLastStep ? 'Submit Form' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
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
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Previous', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
        ],
        if (isLastStep) ...[
          OutlinedButton.icon(
            onPressed: () => _showPreviewDialog(context, controller, isMobile),
            icon: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Preview Application', style: TextStyle(fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 14),
        ],
        ElevatedButton(
          onPressed: controller.isLoading.value
              ? null
              : (isLastStep ? controller.submitApplicationFromStep3 : controller.nextStep),
          style: ElevatedButton.styleFrom(
            backgroundColor: isLastStep ? const Color(0xFF059669) : primaryNavy,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: controller.isLoading.value
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(isLastStep ? 'Submit Form' : 'Next', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildUploadBox({
    required BuildContext context,
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onSpecTap,
              child: Text(
                specText,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), decoration: TextDecoration.underline),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(() {
          final hasFile = uploadedUrlObs.value.isNotEmpty;
          final fileName = hasFile ? uploadedUrlObs.value.split('/').last : '';

          return Container(
            height: 104,
            decoration: BoxDecoration(
              color: hasFile ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
              border: Border.all(
                color: hasFile ? const Color(0xFF86EFAC) : const Color(0xFF94A3B8),
                style: BorderStyle.solid,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: hasFile
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              fileName,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF065F46)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              final fullUrl = AppConfig.buildImageUrl(uploadedUrlObs.value);
                              showDialog(
                                context: context,
                                builder: (ctx) => FilePreviewDialog(
                                  fileName: title,
                                  fileUrl: fullUrl,
                                ),
                              );
                            },
                            icon: const Icon(Icons.visibility_outlined, size: 14),
                            label: const Text('Preview', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1E293B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: onTap,
                            icon: const Icon(Icons.sync_rounded, size: 14),
                            label: const Text('Change', style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryNavy,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_outlined, size: 28, color: Color(0xFF64748B)),
                          SizedBox(height: 6),
                          Text('Click or drag file to upload', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
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
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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

  Widget _buildDocumentsGrid({
    required List<Widget> children,
    double minItemWidth = 280,
    double spacing = 16,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        int crossAxisCount = (availableWidth / (minItemWidth + spacing)).floor();
        if (crossAxisCount < 1) crossAxisCount = 1;

        final itemWidth = crossAxisCount == 1
            ? availableWidth
            : (availableWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
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
