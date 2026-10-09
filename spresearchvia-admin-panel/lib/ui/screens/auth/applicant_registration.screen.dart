import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/recruitment/applicant_registration.controller.dart';
import 'package:spresearch_web/ui/widgets/button.widget.dart';
import 'package:spresearch_web/ui/widgets/file_preview_dialog.widget.dart';

class ApplicantRegistrationScreen extends StatelessWidget {
  const ApplicantRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ApplicantRegistrationController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                vertical: isMobile ? 16 : 48,
                horizontal: isMobile ? 10 : 16,
              ),
              child: Container(
                width: 860,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 24,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 16 : 40,
                  vertical: isMobile ? 24 : 36,
                ),
                child: Obx(() {
                  if (controller.isVerified.value) {
                    return _buildOnboardingUploads(context, controller, isMobile);
                  }
                  if (controller.isRegistered.value) {
                    return _buildVerificationScreen(context, controller, isMobile);
                  }
                  return _buildApplicationForm(context, controller, isMobile);
                }),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResponsiveRow(bool isMobile, List<Widget> children, {double spacing = 14}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            children[i],
          ],
        ],
      );
    }
    return Row(
      children: [
        for (int i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          Expanded(child: children[i]),
        ],
      ],
    );
  }

  Widget _buildApplicationForm(BuildContext context, ApplicantRegistrationController controller, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Brand Header
        Center(
          child: Text(
            'WALK IN INTERVIEW APPLICATION FORM',
            style: TextStyle(
              fontSize: isMobile ? 18 : 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Please complete all sections carefully. All information will be kept strictly confidential.',
          style: TextStyle(fontSize: isMobile ? 12 : 13, color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            border: Border.all(color: const Color(0xFFBBF7D0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isMobile
              ? Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, size: 15, color: Color(0xFF16A34A)),
                        SizedBox(width: 6),
                        Text(
                          'Already submitted application?',
                          style: TextStyle(fontSize: 12.5, color: Color(0xFF166534), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => Get.toNamed('/continue-application'),
                      child: const Text(
                        'Click here to Continue Application',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF15803D),
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
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
        _buildRoleSelectorField(context, controller, isMobile),
        const SizedBox(height: 14),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.nameController, label: 'Full Name *', hint: 'Enter your full name'),
            _buildTextField(controller: controller.phoneController, label: 'Mobile Number *', hint: '10-digit number'),
          ],
        ),
        const SizedBox(height: 14),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.emailController, label: 'Email Address *', hint: 'name@example.com'),
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
                  label: 'Date of Birth (YYYY-MM-DD) *',
                  hint: 'Select your birth date',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildResponsiveRow(
          isMobile,
          [
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedGender.value.isEmpty ? null : controller.selectedGender.value,
                decoration: const InputDecoration(labelText: 'Gender *', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                items: ['Male', 'Female', 'Other'].map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => controller.selectedGender.value = val ?? '',
              ),
            ),
            Obx(
              () => DropdownButtonFormField<String>(
                value: controller.selectedMaritalStatus.value.isEmpty ? null : controller.selectedMaritalStatus.value,
                decoration: const InputDecoration(labelText: 'Marital Status *', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                items: ['Single', 'Married', 'Divorced', 'Widowed'].map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) => controller.selectedMaritalStatus.value = val ?? '',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(
              controller: controller.currentLocationController,
              label: 'Current Location / City *',
              hint: 'e.g. Indore, MP',
            ),
            _buildTextField(
              controller: controller.skypeAddressController,
              label: 'Skype ID / LinkedIn Handle',
              hint: 'e.g. skype.id or linkedin.com/in/...',
            ),
          ],
        ),

        const SizedBox(height: 32),
        // 2. Addresses
        _buildSectionTitle('2. Residential Addresses'),
        const SizedBox(height: 14),
        const Text('Current Address *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        _buildTextField(controller: controller.currentStreetController, label: 'Street Address *', hint: 'Street, flat, building name'),
        const SizedBox(height: 10),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.currentCityController, label: 'City *', hint: 'City'),
            _buildTextField(controller: controller.currentStateController, label: 'State *', hint: 'State'),
            _buildTextField(controller: controller.currentZipController, label: 'ZIP Code *', hint: 'ZIP code'),
          ],
          spacing: 10,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Permanent Address *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF334155))),
            Obx(
              () => InkWell(
                onTap: () => controller.toggleSameAsCurrentAddress(!controller.sameAsCurrentAddress.value),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: controller.sameAsCurrentAddress.value,
                        onChanged: (val) => controller.toggleSameAsCurrentAddress(val ?? false),
                        activeColor: const Color(0xFF10B981),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Permanent Address same as Current Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => _buildTextField(
            controller: controller.permanentStreetController,
            label: 'Street Address *',
            hint: 'Street, flat, building name',
            readOnly: controller.sameAsCurrentAddress.value,
          ),
        ),
        const SizedBox(height: 10),
        Obx(
          () => _buildResponsiveRow(
            isMobile,
            [
              _buildTextField(
                controller: controller.permanentCityController,
                label: 'City *',
                hint: 'City',
                readOnly: controller.sameAsCurrentAddress.value,
              ),
              _buildTextField(
                controller: controller.permanentStateController,
                label: 'State *',
                hint: 'State',
                readOnly: controller.sameAsCurrentAddress.value,
              ),
              _buildTextField(
                controller: controller.permanentZipController,
                label: 'ZIP Code *',
                hint: 'ZIP code',
                readOnly: controller.sameAsCurrentAddress.value,
              ),
            ],
            spacing: 10,
          ),
        ),

        const SizedBox(height: 32),
        // 3. Educational Qualifications
        _buildSectionTitle('3. Educational Qualifications'),
        const SizedBox(height: 8),
        Text('Details of qualifications from 10th standard onwards:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 10),
        if (isMobile)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.swipe, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Swipe horizontally to view & edit all qualification columns',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
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
        // 4. Work Experience & Compensation
        _buildSectionTitle('4. Current / Last Work Experience & CTC'),
        const SizedBox(height: 12),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: controller.hasWorkExperience.value ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: controller.hasWorkExperience.value ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1)),
            ),
            child: InkWell(
              onTap: () => controller.hasWorkExperience.toggle(),
              child: Row(
                children: [
                  Checkbox(
                    value: controller.hasWorkExperience.value,
                    onChanged: (val) => controller.hasWorkExperience.value = val ?? false,
                    activeColor: const Color(0xFF2563EB),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'I have Current / Prior Work Experience (Uncheck if you are a Fresher)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(() {
          if (!controller.hasWorkExperience.value) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.previousCompanyController, label: 'Current / Last Organisation', hint: 'Company name'),
                  _buildTextField(controller: controller.currentDesignationController, label: 'Current Designation', hint: 'Role / Designation'),
                ],
              ),
              const SizedBox(height: 14),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.reportingManagerNameController, label: 'Reporting Manager Name', hint: 'Manager full name'),
                  _buildTextField(controller: controller.reportingManagerDesignationController, label: 'Reporting Manager Designation', hint: 'Manager designation'),
                ],
              ),
              const SizedBox(height: 14),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.reporteesCountController, label: 'Number of Direct Reportees', hint: '0 if none'),
                  _buildTextField(controller: controller.experienceYearsController, label: 'Total Experience (Years)', hint: 'e.g. 3'),
                ],
              ),
              const SizedBox(height: 14),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.fixedSalaryController, label: 'Fixed Salary (Annual INR)', hint: 'e.g. 5,00,000'),
                  _buildTextField(controller: controller.bonusIncentiveController, label: 'Bonus / Variable (Annual INR)', hint: 'e.g. 1,00,000'),
                ],
              ),
              const SizedBox(height: 14),
              _buildResponsiveRow(
                isMobile,
                [
                  _buildTextField(controller: controller.lastCtcController, label: 'Total Current CTC (Annual INR)', hint: 'e.g. 6,00,000'),
                  _buildTextField(controller: controller.expectedSalaryController, label: 'Expected CTC (Annual INR)', hint: 'e.g. 7,50,000'),
                ],
              ),
              const SizedBox(height: 14),
              _buildTextField(controller: controller.noticePeriodController, label: 'Notice Period (Days)', hint: 'e.g. 15 Days, Immediate'),
            ],
          );
        }),

        const SizedBox(height: 32),
        // 5. Employment History
        _buildSectionTitle('5. Previous Employment History'),
        const SizedBox(height: 12),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: controller.hasPreviousEmploymentHistory.value ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: controller.hasPreviousEmploymentHistory.value ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1)),
            ),
            child: InkWell(
              onTap: () => controller.hasPreviousEmploymentHistory.toggle(),
              child: Row(
                children: [
                  Checkbox(
                    value: controller.hasPreviousEmploymentHistory.value,
                    onChanged: (val) => controller.hasPreviousEmploymentHistory.value = val ?? false,
                    activeColor: const Color(0xFF2563EB),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'I have previous employment history with other employers',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(() {
          if (!controller.hasPreviousEmploymentHistory.value) {
            return const SizedBox.shrink();
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text('Details of past employers:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 10),
              if (isMobile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.swipe, size: 14, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Text(
                        'Swipe horizontally to view & edit all employment columns',
                        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade600, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              Container(
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
                    rows: controller.employmentEntries.asMap().entries.map((entry) {
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
              ),
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
            ],
          );
        }),

        const SizedBox(height: 32),
        // 6. Emergency Contact
        _buildSectionTitle('6. Emergency Contact Information'),
        const SizedBox(height: 14),
        _buildResponsiveRow(
          isMobile,
          [
            _buildTextField(controller: controller.emergencyNameController, label: 'Contact Person Name *', hint: 'Full name'),
            _buildTextField(controller: controller.emergencyRelationController, label: 'Relationship *', hint: 'e.g. Spouse, Parent'),
            _buildTextField(controller: controller.emergencyPhoneController, label: 'Contact Number *', hint: 'Phone number'),
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
        const SizedBox(width: 8),
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

  Widget _buildVerificationScreen(BuildContext context, ApplicantRegistrationController controller, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Contact Verification',
          style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Verification codes have been sent to your phone and email. You can edit your contact details below if needed.',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: isMobile ? 12 : 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Editable Phone & Email Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Verify & Edit Contact Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 12),
              _buildResponsiveRow(
                isMobile,
                [
                  TextField(
                    controller: controller.phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Number *',
                      prefixIcon: Icon(Icons.phone_outlined, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  TextField(
                    controller: controller.emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address *',
                      prefixIcon: Icon(Icons.email_outlined, size: 18),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Obx(
                  () => OutlinedButton.icon(
                    onPressed: controller.isResendingOtp.value ? null : () => controller.updateContactAndResendOtp(),
                    icon: controller.isResendingOtp.value
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(
                      controller.isResendingOtp.value ? 'Sending New Codes...' : 'Update & Resend OTPs',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2563EB),
                      side: const BorderSide(color: Color(0xFF93C5FD)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        const Text(
          'Enter Verification Codes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 12),
        _buildResponsiveRow(
          isMobile,
          [
            TextField(
              controller: controller.mobileOtpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Mobile OTP *',
                prefixIcon: Icon(Icons.sms_outlined, size: 18),
                border: OutlineInputBorder(),
                hintText: 'Enter 4-digit code',
              ),
            ),
            TextField(
              controller: controller.emailOtpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Email OTP *',
                prefixIcon: Icon(Icons.mark_email_read_outlined, size: 18),
                border: OutlineInputBorder(),
                hintText: 'Enter 4-digit code',
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Button(
                    title: 'Verify Codes',
                    buttonType: ButtonType.green,
                    onTap: () => controller.verifyOtps(),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => controller.isRegistered.value = false,
                    child: const Text('Back to Form'),
                  ),
                ],
              )
            : Row(
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

  Widget _buildOnboardingUploads(BuildContext context, ApplicantRegistrationController controller, bool isMobile) {
    return Obx(() {
      final applicant = controller.currentApplicant.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Document Uploads',
            style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A5F)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload required files to complete your onboarding application.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: isMobile ? 12 : 13),
            textAlign: TextAlign.center,
          ),
          const Divider(height: 36),
          _buildUploadRow(context, 'Profile Photo', 'photo', applicant?.photoUrl, controller, isMobile: isMobile),
          const SizedBox(height: 12),
          _buildUploadRow(context, 'Resume / CV', 'resume', applicant?.resumeUrl, controller, isMobile: isMobile),
          const SizedBox(height: 12),
          _buildUploadRow(context, 'PAN Card', 'pan', applicant?.panUrl, controller, isMobile: isMobile),
          const SizedBox(height: 12),
          _buildUploadRow(context, 'Aadhaar Card', 'aadhaar', applicant?.aadhaarUrl, controller, isMobile: isMobile),
          const SizedBox(height: 12),
          _buildUploadRow(context, 'NISM Certificate', 'nism', applicant?.nismUrl, controller, isMobile: isMobile),
          const SizedBox(height: 12),
          _buildUploadRow(context, 'Highest Education Certificate', 'education', applicant?.highestEducationUrl, controller, isMobile: isMobile),
          const SizedBox(height: 12),
          _buildUploadRow(context, 'KYC Verification Video', 'video', applicant?.kycVideoUrl, controller, isMobile: isMobile),
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
    });
  }

  Widget _buildUploadRow(
    BuildContext context,
    String title,
    String type,
    String? fileUrl,
    ApplicantRegistrationController controller, {
    bool isMobile = false,
  }) {
    final hasFile = fileUrl != null && fileUrl.isNotEmpty;
    final isVideo = type == 'video';
    final isUploading = controller.uploadingDocType.value == type;
    final cleanFileName = hasFile ? fileUrl.split('/').last : '';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasFile ? const Color(0xFFF8FAFC) : Colors.white,
        border: Border.all(color: hasFile ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: hasFile ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
                      ),
                      child: Icon(
                        isVideo ? Icons.videocam_outlined : Icons.description_outlined,
                        color: hasFile ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: hasFile ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: hasFile ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (hasFile) ...[
                                      const Icon(Icons.check_circle, size: 11, color: Color(0xFF059669)),
                                      const SizedBox(width: 3),
                                    ],
                                    Text(
                                      hasFile ? 'Uploaded' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: hasFile ? const Color(0xFF059669) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            hasFile ? cleanFileName : (isVideo ? 'Supports MP4, MOV' : 'Supports PDF, JPG, PNG'),
                            style: TextStyle(fontSize: 11, color: hasFile ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (hasFile) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          final fullUrl = AppConfig.buildImageUrl(fileUrl);
                          final ext = isVideo ? '.mp4' : (fileUrl.toLowerCase().endsWith('.pdf') ? '.pdf' : '.png');
                          showDialog(
                            context: context,
                            builder: (ctx) => FilePreviewDialog(
                              fileName: '$title$ext',
                              fileUrl: fullUrl,
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: const Text('Preview', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: isUploading ? null : () => (isVideo ? controller.handleVideoKyc(context) : controller.uploadDoc(type)),
                      icon: isUploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                            )
                          : Icon(isVideo ? (hasFile ? Icons.videocam : Icons.videocam_outlined) : (hasFile ? Icons.swap_horiz : Icons.file_upload_outlined), size: 14),
                      label: Text(isUploading ? 'Uploading...' : (isVideo ? (hasFile ? 'Re-record / Replace' : 'Record / Upload') : (hasFile ? 'Replace' : 'Upload')), style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasFile ? const Color(0xFFF1F5F9) : const Color(0xFF1E3A5F),
                        foregroundColor: hasFile ? const Color(0xFF334155) : Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: hasFile ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: hasFile ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    isVideo ? Icons.videocam_outlined : Icons.description_outlined,
                    color: hasFile ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: hasFile ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: hasFile ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (hasFile) ...[
                                  const Icon(Icons.check_circle, size: 11, color: Color(0xFF059669)),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  hasFile ? 'Uploaded' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: hasFile ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        hasFile ? cleanFileName : (isVideo ? 'Supports MP4, MOV, AVI' : 'Supports PDF, JPG, PNG'),
                        style: TextStyle(fontSize: 11.5, color: hasFile ? const Color(0xFF059669) : const Color(0xFF94A3B8)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (hasFile) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      final fullUrl = AppConfig.buildImageUrl(fileUrl);
                      final ext = isVideo ? '.mp4' : (fileUrl.toLowerCase().endsWith('.pdf') ? '.pdf' : '.png');
                      showDialog(
                        context: context,
                        builder: (ctx) => FilePreviewDialog(
                          fileName: '$title$ext',
                          fileUrl: fullUrl,
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 14),
                    label: const Text('Preview', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                ElevatedButton.icon(
                  onPressed: isUploading ? null : () => (isVideo ? controller.handleVideoKyc(context) : controller.uploadDoc(type)),
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                        )
                      : Icon(isVideo ? (hasFile ? Icons.videocam : Icons.videocam_outlined) : (hasFile ? Icons.swap_horiz : Icons.file_upload_outlined), size: 14),
                  label: Text(isUploading ? 'Uploading...' : (isVideo ? (hasFile ? 'Re-record / Replace' : 'Record / Upload') : (hasFile ? 'Replace' : 'Upload')), style: const TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasFile ? const Color(0xFFF1F5F9) : const Color(0xFF1E3A5F),
                    foregroundColor: hasFile ? const Color(0xFF334155) : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
        filled: readOnly,
        fillColor: readOnly ? const Color(0xFFF8FAFC) : null,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
  }

  Widget _buildRoleSelectorField(BuildContext context, ApplicantRegistrationController controller, bool isMobile) {
    return Obx(() {
      final isCustom = controller.isCustomRole.value;
      final selectedRole = controller.selectedRole.value;
      final isLoading = controller.isLoadingRoles.value;

      if (isCustom) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            isMobile
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: controller.appliedPositionController,
                        label: 'Position Applied For *',
                        hint: 'e.g. Senior Equity Research Analyst',
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => controller.setCustomRoleMode(false),
                          icon: const Icon(Icons.list_alt, size: 16),
                          label: const Text('Choose from openings', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  )
                : Row(
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
                    ? (isMobile
                        ? Column(
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
                              if (selectedRole['departmentName'] != null &&
                                  selectedRole['departmentName'].toString().isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE0E7FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.business_rounded, size: 11, color: Color(0xFF3730A3)),
                                      const SizedBox(width: 4),
                                      Text(
                                        selectedRole['departmentName'].toString(),
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF3730A3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          )
                        : Row(
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
                          ))
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
        final screenWidth = MediaQuery.of(dialogCtx).size.width;
        final isMobileDialog = screenWidth < 550;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobileDialog ? 12 : 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Container(
            width: isMobileDialog ? (screenWidth - 24) : 540,
            constraints: const BoxConstraints(maxHeight: 580),
            padding: EdgeInsets.all(isMobileDialog ? 16 : 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.work_outline_rounded, color: Color(0xFF2563EB), size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Select Open Role',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Filter by role title or department',
                                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(dialogCtx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: searchCtrl,
                  onChanged: (val) => searchQuery.value = val.trim().toLowerCase(),
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: isMobileDialog ? 'Search roles...' : 'Search roles (e.g. Sales, Research, Analyst)...',
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                          title: isMobileDialog
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      role['name']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    if (deptName.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFE2E8F0)),
                                        ),
                                        child: Text(
                                          deptName,
                                          style: const TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF475569),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Row(
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
                                      const SizedBox(width: 8),
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
                                    maxLines: 2,
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
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
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
