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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
          child: Container(
            width: 860,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 36),
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
        // Brand Header
        const Center(
          child: Text(
            'WALK IN INTERVIEW APPLICATION FORM',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please complete all sections carefully. All information will be kept strictly confidential.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 16, color: Color(0xFF16A34A)),
              const SizedBox(width: 8),
              const Text(
                'Already submitted initial application? ',
                style: TextStyle(fontSize: 13, color: Color(0xFF166534)),
              ),
              InkWell(
                onTap: () => Get.toNamed('/continue-application'),
                child: const Text(
                  'Click here to Continue Application',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 36, color: Color(0xFFF1F5F9)),

        // 1. Applied Position & Personal Details
        _buildSectionTitle('1. Position & Personal Information'),
        const SizedBox(height: 14),
        _buildRoleSelectorField(context, controller),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.nameController, label: 'Full Name *', hint: 'Enter your full name'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTextField(controller: controller.phoneController, label: 'Mobile Number *', hint: '10-digit number'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildTextField(controller: controller.emailController, label: 'Email Address *', hint: 'name@example.com'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: InkWell(
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
                    label: 'Date of Birth (YYYY-MM-DD) *',
                    hint: 'Select your birth date',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedGender.value.isEmpty ? null : controller.selectedGender.value,
                  decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => controller.selectedGender.value = val ?? '',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedMaritalStatus.value.isEmpty ? null : controller.selectedMaritalStatus.value,
                  decoration: const InputDecoration(labelText: 'Marital Status', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                  items: ['Single', 'Married', 'Divorced', 'Widowed'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => controller.selectedMaritalStatus.value = val ?? '',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: controller.nativePlaceController,
                label: 'Native Place (Hometown / State)',
                hint: 'e.g. Bhopal, MP',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTextField(
                controller: controller.currentLocationController,
                label: 'Current Location / City',
                hint: 'e.g. Indore',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(
          controller: controller.skypeAddressController,
          label: 'Skype ID / LinkedIn Handle',
          hint: 'e.g. skype.id or linkedin.com/in/...',
        ),

        const SizedBox(height: 32),
        // 2. Addresses
        _buildSectionTitle('2. Residential Addresses'),
        const SizedBox(height: 14),
        const Text('Current Address', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        _buildTextField(controller: controller.currentStreetController, label: 'Street Address', hint: 'Street, flat, building name'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.currentCityController, label: 'City', hint: 'City')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(controller: controller.currentStateController, label: 'State', hint: 'State')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(controller: controller.currentZipController, label: 'ZIP Code', hint: 'ZIP')),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Permanent Address (If different from current)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        _buildTextField(controller: controller.permanentStreetController, label: 'Street Address', hint: 'Street, flat, building name'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.permanentCityController, label: 'City', hint: 'City')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(controller: controller.permanentStateController, label: 'State', hint: 'State')),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField(controller: controller.permanentZipController, label: 'ZIP Code', hint: 'ZIP')),
          ],
        ),

        const SizedBox(height: 32),
        // 3. Screening & Declarations
        _buildSectionTitle('3. Background & Lifestyle Declarations'),
        const SizedBox(height: 14),
        _buildToggleQuestion(
          'Have you been interviewed by us in the last six months?',
          controller.interviewedBefore,
          detailsController: controller.interviewedBeforeDetailsController,
          detailsHint: 'If yes, mention date & position',
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildSimpleToggle('Do you smoke?', controller.smoke),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildSimpleToggle('Do you consume alcohol?', controller.alcohol),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildToggleQuestion(
          'Are you differently abled?',
          controller.differentlyAbled,
          detailsController: controller.differentlyAbledDetailsController,
          detailsHint: 'If yes, specify details',
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildToggleQuestion(
          'Do you have any past police record or pending legal cases?',
          controller.policeRecord,
          detailsController: controller.policeRecordDetailsController,
          detailsHint: 'If yes, specify nature of case',
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        _buildToggleQuestion(
          'Do you have a history of any major illness or ongoing treatment?',
          controller.majorIllness,
          detailsController: controller.majorIllnessDetailsController,
          detailsHint: 'If yes, specify medical conditions',
        ),
        const Divider(height: 20, color: Color(0xFFF1F5F9)),
        Row(
          children: [
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  value: controller.selectedSource.value.isEmpty ? null : controller.selectedSource.value,
                  decoration: const InputDecoration(
                    labelText: 'How did you learn about the opening?',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  items: [
                    'Newspaper advertisement',
                    'Company website',
                    'Friend or relative',
                    'Job portal',
                    'Social media',
                    'Walk-in',
                    'Other'
                  ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                  onChanged: (val) => controller.selectedSource.value = val ?? '',
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTextField(
                controller: controller.sourceDetailsController,
                label: 'Source Reference Details',
                hint: 'Referrer name, portal name, etc.',
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),
        // 4. Educational Qualifications
        _buildSectionTitle('4. Educational Qualifications'),
        const SizedBox(height: 8),
        Text('Details of qualifications from 10th standard onwards:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        Obx(() {
          final entries = controller.educationEntries;
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                columnSpacing: 14,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('Class / Level')),
                  DataColumn(label: Text('Degree / Stream')),
                  DataColumn(label: Text('School / College')),
                  DataColumn(label: Text('Board / Univ')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Year')),
                  DataColumn(label: Text('Attempts')),
                  DataColumn(label: Text('% / CGPA')),
                  DataColumn(label: Text('Action')),
                ],
                rows: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(SizedBox(width: 100, child: TextFormField(initialValue: item.standard, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Class'), onChanged: (v) => item.standard = v))),
                      DataCell(SizedBox(width: 110, child: TextFormField(initialValue: item.degree, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Degree'), onChanged: (v) => item.degree = v))),
                      DataCell(SizedBox(width: 130, child: TextFormField(initialValue: item.schoolCollege, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'School/College'), onChanged: (v) => item.schoolCollege = v))),
                      DataCell(SizedBox(width: 120, child: TextFormField(initialValue: item.boardUniversity, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Board/Univ'), onChanged: (v) => item.boardUniversity = v))),
                      DataCell(
                        DropdownButton<String>(
                          value: ['Regular', 'Part time'].contains(item.courseType) ? item.courseType : 'Regular',
                          isDense: true,
                          underline: const SizedBox.shrink(),
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                          items: const [
                            DropdownMenuItem(value: 'Regular', child: Text('Regular')),
                            DropdownMenuItem(value: 'Part time', child: Text('Part time')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              item.courseType = v;
                              controller.educationEntries.refresh();
                            }
                          },
                        ),
                      ),
                      DataCell(SizedBox(width: 75, child: TextFormField(initialValue: item.passingYear, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'YYYY'), onChanged: (v) => item.passingYear = v))),
                      DataCell(SizedBox(width: 55, child: TextFormField(initialValue: item.attempts, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '1'), onChanged: (v) => item.attempts = v))),
                      DataCell(SizedBox(width: 65, child: TextFormField(initialValue: item.percentage, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: '%'), onChanged: (v) => item.percentage = v))),
                      DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)), onPressed: () => controller.removeEducationEntry(index))),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.addEducationEntry,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Qualification Row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        _buildToggleQuestion(
          'Was there any academic gap during your education?',
          controller.academicGap,
          detailsController: controller.academicGapDetailsController,
          detailsHint: 'Duration and reason for academic gap',
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.backlogsCountController,
          label: 'Number of Backlogs / ATKTs (if any)',
          hint: 'e.g. Nil, or 1 backlog in sem 2',
        ),

        const SizedBox(height: 32),
        // 5. Work Experience & Compensation
        _buildSectionTitle('5. Current / Last Work Experience & CTC'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.previousCompanyController, label: 'Current / Last Organisation', hint: 'Company name')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(controller: controller.currentDesignationController, label: 'Current Designation', hint: 'Role / Designation')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.reportingManagerNameController, label: 'Reporting Manager Name', hint: 'Manager full name')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(controller: controller.reportingManagerDesignationController, label: 'Reporting Manager Designation', hint: 'Manager designation')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.reporteesCountController, label: 'Number of Direct Reportees', hint: '0 if none')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(controller: controller.experienceYearsController, label: 'Total Experience (Years)', hint: 'e.g. 3')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.fixedSalaryController, label: 'Fixed Salary (Annual INR)', hint: 'e.g. 5,00,000')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(controller: controller.bonusIncentiveController, label: 'Bonus / Variable (Annual INR)', hint: 'e.g. 1,00,000')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.lastCtcController, label: 'Total Current CTC (Annual INR)', hint: 'e.g. 6,00,000')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(controller: controller.expectedSalaryController, label: 'Expected CTC (Annual INR)', hint: 'e.g. 7,50,000')),
          ],
        ),
        const SizedBox(height: 14),
        _buildTextField(controller: controller.noticePeriodController, label: 'Notice Period (Days)', hint: 'e.g. 15 Days, Immediate'),

        const SizedBox(height: 32),
        // 6. Employment History
        _buildSectionTitle('6. Previous Employment History'),
        const SizedBox(height: 8),
        Text('Details of past employers (if applicable):', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        Obx(() {
          final entries = controller.employmentEntries;
          if (entries.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text('No previous employers added yet. (Click below if you have previous experience)', style: TextStyle(fontSize: 12, color: AppTheme.gray500)),
              ),
            );
          }
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFCBD5E1)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                dataTextStyle: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                columnSpacing: 14,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('From (Month, Year)')),
                  DataColumn(label: Text('To (Month, Year)')),
                  DataColumn(label: Text('Organisation')),
                  DataColumn(label: Text('Designation')),
                  DataColumn(label: Text('Reason for Leaving')),
                  DataColumn(label: Text('Action')),
                ],
                rows: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return DataRow(
                    cells: [
                      DataCell(SizedBox(width: 120, child: TextFormField(initialValue: item.fromPeriod, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Jan 2021'), onChanged: (v) => item.fromPeriod = v))),
                      DataCell(SizedBox(width: 120, child: TextFormField(initialValue: item.toPeriod, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Mar 2023'), onChanged: (v) => item.toPeriod = v))),
                      DataCell(SizedBox(width: 160, child: TextFormField(initialValue: item.organisation, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Company'), onChanged: (v) => item.organisation = v))),
                      DataCell(SizedBox(width: 140, child: TextFormField(initialValue: item.designation, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Designation'), onChanged: (v) => item.designation = v))),
                      DataCell(SizedBox(width: 180, child: TextFormField(initialValue: item.reasonForLeaving, style: const TextStyle(fontSize: 12), decoration: const InputDecoration(isDense: true, border: InputBorder.none, hintText: 'Reason for leaving'), onChanged: (v) => item.reasonForLeaving = v))),
                      DataCell(IconButton(icon: const Icon(Icons.delete_outline, size: 16, color: Color(0xFFEF4444)), onPressed: () => controller.removeEmploymentEntry(index))),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: controller.addEmploymentEntry,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Previous Employer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField(
          controller: controller.careerGapController,
          label: 'Career Gap Details (if any)',
          hint: 'Specify duration and reasons for any career gaps',
        ),

        const SizedBox(height: 32),
        // 7. Emergency Contact
        _buildSectionTitle('7. Emergency Contact Information'),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _buildTextField(controller: controller.emergencyNameController, label: 'Contact Person Name', hint: 'Full name')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(controller: controller.emergencyRelationController, label: 'Relationship', hint: 'e.g. Spouse, Parent')),
            const SizedBox(width: 14),
            Expanded(child: _buildTextField(controller: controller.emergencyPhoneController, label: 'Contact Number', hint: 'Phone number')),
          ],
        ),

        const SizedBox(height: 40),
        Obx(
          () => Button(
            title: controller.isLoading.value ? 'Submitting Application...' : 'Submit Application & Verify Contact',
            buttonType: ButtonType.green,
            onTap: controller.isLoading.value ? null : () => controller.submitApplication(),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleToggle(String question, RxBool valueObs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            question,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
          ),
        ),
        Obx(
          () => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildChoiceChip('No', !valueObs.value, () => valueObs.value = false),
              const SizedBox(width: 8),
              _buildChoiceChip('Yes', valueObs.value, () => valueObs.value = true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleQuestion(
    String question,
    RxBool valueObs, {
    required TextEditingController detailsController,
    required String detailsHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSimpleToggle(question, valueObs),
        Obx(() {
          if (!valueObs.value) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildTextField(
              controller: detailsController,
              label: 'Additional Information',
              hint: detailsHint,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildChoiceChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildVerificationScreen(BuildContext context, ApplicantRegistrationController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Contact Verification',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
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
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Upload required files to complete your onboarding application.',
          style: TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Divider(height: 36),
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
        const SizedBox(height: 36),
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => controller.uploadDoc(type),
            icon: const Icon(Icons.upload, size: 14),
            label: const Text('Upload File', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(elevation: 0),
          )
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
  }

  Widget _buildRoleSelectorField(BuildContext context, ApplicantRegistrationController controller) {
    return Obx(() {
      final isCustom = controller.isCustomRole.value;
      final selectedRole = controller.selectedRole.value;
      final isLoading = controller.isLoadingRoles.value;

      if (isCustom) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: controller.appliedPositionController,
                    label: 'Position Applied For *',
                    hint: 'e.g. Senior Equity Research Analyst',
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => controller.setCustomRoleMode(false),
                  icon: const Icon(Icons.list_alt, size: 16),
                  label: const Text('Choose from openings', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        );
      }

      return InkWell(
        onTap: () => _showRoleSelectionDialog(context, controller),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selectedRole != null ? const Color(0xFF1E3A5F) : const Color(0xFFCBD5E1),
              width: selectedRole != null ? 1.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(8),
            color: selectedRole != null ? const Color(0xFFF8FAFC) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                Icons.work_outline_rounded,
                size: 20,
                color: selectedRole != null ? const Color(0xFF1E3A5F) : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: selectedRole != null
                    ? Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Position Applied For *',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedRole['name']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selectedRole['departmentName'] != null &&
                              selectedRole['departmentName'].toString().isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0E7FF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.business_rounded, size: 12, color: Color(0xFF3730A3)),
                                  const SizedBox(width: 4),
                                  Text(
                                    selectedRole['departmentName'].toString(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF3730A3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Position Applied For *',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isLoading ? 'Loading open roles from database...' : 'Select or search open position...',
                            style: TextStyle(
                              fontSize: 13,
                              color: isLoading ? Colors.grey : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_drop_down_rounded,
                  color: selectedRole != null ? const Color(0xFF1E3A5F) : const Color(0xFF64748B),
                ),
            ],
          ),
        ),
      );
    });
  }

  void _showRoleSelectionDialog(BuildContext context, ApplicantRegistrationController controller) {
    final searchCtrl = TextEditingController();
    final searchQuery = ''.obs;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            width: 540,
            constraints: const BoxConstraints(maxHeight: 580),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.work_outline_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Open Role',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Filter by role title or department',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: searchCtrl,
                  onChanged: (val) => searchQuery.value = val.trim().toLowerCase(),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Search roles (e.g. Sales, Research, Analyst)...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF64748B)),
                    suffixIcon: Obx(() => searchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              searchCtrl.clear();
                              searchQuery.value = '';
                            },
                          )
                        : const SizedBox.shrink()),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoadingRoles.value) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final query = searchQuery.value;
                    final filtered = controller.openRoles.where((r) {
                      if (query.isEmpty) return true;
                      final name = (r['name'] ?? '').toString().toLowerCase();
                      final dept = (r['departmentName'] ?? '').toString().toLowerCase();
                      final code = (r['code'] ?? '').toString().toLowerCase();
                      final desc = (r['description'] ?? '').toString().toLowerCase();
                      return name.contains(query) || dept.contains(query) || code.contains(query) || desc.contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 8),
                              Text(
                                query.isEmpty ? 'No open roles available currently' : 'No roles matching "$query"',
                                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: () {
                                  Navigator.of(dialogCtx).pop();
                                  controller.setCustomRoleMode(true);
                                  if (query.isNotEmpty) {
                                    controller.appliedPositionController.text = searchCtrl.text.trim();
                                  }
                                },
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Enter Custom Role Title'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, idx) {
                        final role = filtered[idx];
                        final isSelected = controller.selectedRole.value?['id'] == role['id'] ||
                            controller.selectedRole.value?['_id'] == role['_id'] ||
                            controller.appliedPositionController.text.trim() == role['name'];

                        final deptName = role['departmentName']?.toString() ?? '';
                        final desc = role['description']?.toString() ?? '';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  role['name']?.toString() ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              if (deptName.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                  ),
                                  child: Text(
                                    deptName,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: desc.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    desc,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 20)
                              : null,
                          onTap: () {
                            controller.selectRole(role);
                            Navigator.of(dialogCtx).pop();
                          },
                        );
                      },
                    );
                  }),
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(dialogCtx).pop();
                        controller.setCustomRoleMode(true);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 15),
                      label: const Text('Not listed? Enter custom position', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                      child: const Text('Cancel', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
