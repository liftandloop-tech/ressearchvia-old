import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/applicant.service.dart';
import '../../models/staff.model.dart';

class ApplicantRegistrationController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  var isLoading = false.obs;
  var uploadingDocType = ''.obs;
  var isRegistered = false.obs;
  var isVerified = false.obs;
  var applicantId = ''.obs;
  var currentApplicant = Rxn<StaffModel>();

  // Dynamic Open Roles from DB
  var openRoles = <Map<String, dynamic>>[].obs;
  var isLoadingRoles = false.obs;
  var selectedRole = Rxn<Map<String, dynamic>>();
  var isCustomRole = false.obs;

  // Text Form fields - Personal
  final appliedPositionController = TextEditingController();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  var selectedGender = ''.obs;
  var selectedMaritalStatus = ''.obs;
  final nativePlaceController = TextEditingController();
  final currentLocationController = TextEditingController();
  final skypeAddressController = TextEditingController();

  // Address
  final currentStreetController = TextEditingController();
  final currentCityController = TextEditingController();
  final currentStateController = TextEditingController();
  final currentZipController = TextEditingController();

  var sameAsCurrentAddress = false.obs;

  final permanentStreetController = TextEditingController();
  final permanentCityController = TextEditingController();
  final permanentStateController = TextEditingController();
  final permanentZipController = TextEditingController();

  // Emergency contact
  final emergencyNameController = TextEditingController();
  final emergencyRelationController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  // Declarations & Screening (Legacy)
  var interviewedBefore = false.obs;
  final interviewedBeforeDetailsController = TextEditingController();
  var smoke = false.obs;
  var alcohol = false.obs;
  var differentlyAbled = false.obs;
  final differentlyAbledDetailsController = TextEditingController();
  var policeRecord = false.obs;
  final policeRecordDetailsController = TextEditingController();
  var majorIllness = false.obs;
  final majorIllnessDetailsController = TextEditingController();
  var selectedSource = ''.obs;
  final sourceDetailsController = TextEditingController();

  // Education
  var educationEntries = <EducationEntryModel>[].obs;
  var academicGap = false.obs;
  final academicGapDetailsController = TextEditingController();
  final backlogsCountController = TextEditingController();

  // Work Experience Toggle & Fields
  var hasWorkExperience = false.obs;
  final experienceYearsController = TextEditingController();
  final previousCompanyController = TextEditingController();
  final currentDesignationController = TextEditingController();
  final reportingManagerDesignationController = TextEditingController();
  final reportingManagerNameController = TextEditingController();
  final reporteesCountController = TextEditingController();
  final fixedSalaryController = TextEditingController();
  final bonusIncentiveController = TextEditingController();
  final lastCtcController = TextEditingController();
  final expectedSalaryController = TextEditingController();
  final noticePeriodController = TextEditingController();

  // Employment History Toggle & Fields
  var hasPreviousEmploymentHistory = false.obs;
  var employmentEntries = <EmploymentEntryModel>[].obs;
  final careerGapController = TextEditingController();

  // OTP field controllers
  final mobileOtpController = TextEditingController();
  final emailOtpController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    initDefaultEducationEntries();
    fetchPublicRoles();

    // Auto sync permanent address whenever current address fields change if checked
    currentStreetController.addListener(syncPermanentAddress);
    currentCityController.addListener(syncPermanentAddress);
    currentStateController.addListener(syncPermanentAddress);
    currentZipController.addListener(syncPermanentAddress);
  }

  void toggleSameAsCurrentAddress(bool val) {
    sameAsCurrentAddress.value = val;
    if (val) {
      syncPermanentAddress();
    }
  }

  void syncPermanentAddress() {
    if (sameAsCurrentAddress.value) {
      permanentStreetController.text = currentStreetController.text;
      permanentCityController.text = currentCityController.text;
      permanentStateController.text = currentStateController.text;
      permanentZipController.text = currentZipController.text;
    }
  }

  Future<void> fetchPublicRoles() async {
    isLoadingRoles.value = true;
    try {
      final roles = await _applicantService.getPublicRoles();
      openRoles.assignAll(roles);
    } catch (e) {
      debugPrint('Error fetching open roles: $e');
    } finally {
      isLoadingRoles.value = false;
    }
  }

  void selectRole(Map<String, dynamic>? role) {
    selectedRole.value = role;
    if (role != null) {
      appliedPositionController.text = role['name']?.toString() ?? '';
      isCustomRole.value = false;
    }
  }

  void setCustomRoleMode(bool isCustom) {
    isCustomRole.value = isCustom;
    if (isCustom) {
      selectedRole.value = null;
      appliedPositionController.clear();
    }
  }

  void initDefaultEducationEntries() {
    if (educationEntries.isEmpty) {
      educationEntries.assignAll([
        EducationEntryModel(standard: '10th'),
        EducationEntryModel(standard: '12th'),
        EducationEntryModel(standard: 'Graduation'),
        EducationEntryModel(standard: 'Post graduation'),
      ]);
    }
  }

  void addEducationEntry() {
    educationEntries.add(EducationEntryModel(standard: ''));
  }

  void removeEducationEntry(int index) {
    if (index >= 0 && index < educationEntries.length) {
      educationEntries.removeAt(index);
    }
  }

  void addEmploymentEntry() {
    employmentEntries.add(EmploymentEntryModel());
  }

  void removeEmploymentEntry(int index) {
    if (index >= 0 && index < employmentEntries.length) {
      employmentEntries.removeAt(index);
    }
  }

  WalkInFormModel buildWalkInFormModel() {
    return WalkInFormModel(
      appliedPosition: (selectedRole.value?['name']?.toString() ?? appliedPositionController.text).trim(),
      applicationDate: DateTime.now().toIso8601String().split('T').first,
      fullName: nameController.text.trim(),
      dob: dobController.text.trim(),
      nativePlace: '',
      gender: selectedGender.value,
      maritalStatus: selectedMaritalStatus.value,
      mobileNumber: phoneController.text.trim(),
      currentLocation: currentLocationController.text.trim().isNotEmpty
          ? currentLocationController.text.trim()
          : currentCityController.text.trim(),
      emailAddress: emailController.text.trim(),
      skypeAddress: skypeAddressController.text.trim(),
      interviewedBefore: false,
      interviewedBeforeDetails: '',
      smoke: false,
      alcohol: false,
      differentlyAbled: false,
      differentlyAbledDetails: '',
      policeRecord: false,
      policeRecordDetails: '',
      majorIllness: false,
      majorIllnessDetails: '',
      source: '',
      sourceDetails: '',
      educationList: educationEntries.toList(),
      academicGap: academicGap.value,
      academicGapDetails: academicGapDetailsController.text.trim(),
      backlogsCount: backlogsCountController.text.trim(),
      currentOrganisation: hasWorkExperience.value ? previousCompanyController.text.trim() : '',
      currentDesignation: hasWorkExperience.value ? currentDesignationController.text.trim() : '',
      reportingManagerDesignation: hasWorkExperience.value ? reportingManagerDesignationController.text.trim() : '',
      reportingManagerName: hasWorkExperience.value ? reportingManagerNameController.text.trim() : '',
      reporteesCount: hasWorkExperience.value ? reporteesCountController.text.trim() : '0',
      totalExperience: hasWorkExperience.value ? experienceYearsController.text.trim() : '0',
      fixedSalary: hasWorkExperience.value ? fixedSalaryController.text.trim() : '',
      bonusIncentive: hasWorkExperience.value ? bonusIncentiveController.text.trim() : '',
      totalSalary: hasWorkExperience.value ? lastCtcController.text.trim() : '',
      expectedSalary: hasWorkExperience.value ? expectedSalaryController.text.trim() : '',
      noticePeriod: hasWorkExperience.value ? noticePeriodController.text.trim() : '',
      employmentList: hasPreviousEmploymentHistory.value ? employmentEntries.toList() : [],
      careerGap: hasPreviousEmploymentHistory.value ? careerGapController.text.trim() : '',
    );
  }

  Future<void> submitApplication() async {
    // 1. Role validation
    final roleName = (selectedRole.value?['name']?.toString() ?? appliedPositionController.text).trim();
    if (roleName.isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please select or enter the Applied Position',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    // 2. Personal Information validation
    if (nameController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your Full Name',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (phoneController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your Mobile Number',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    final digits = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) {
      Get.snackbar('Invalid Input', 'Please enter a valid 10-digit mobile number',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (emailController.text.trim().isEmpty || !emailController.text.trim().contains('@')) {
      Get.snackbar('Mandatory Field Missing', 'Please enter a valid Email Address',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (dobController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please select your Date of Birth',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (selectedGender.value.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please select your Gender',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (selectedMaritalStatus.value.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please select your Marital Status',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    if (currentLocationController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your Current Location / City',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    // 3. Current Address
    if (currentStreetController.text.trim().isEmpty ||
        currentCityController.text.trim().isEmpty ||
        currentStateController.text.trim().isEmpty ||
        currentZipController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please complete all Current Address fields (Street, City, State, ZIP)',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    // Sync permanent address if checkbox is checked
    if (sameAsCurrentAddress.value) {
      syncPermanentAddress();
    }

    // 4. Permanent Address
    if (permanentStreetController.text.trim().isEmpty ||
        permanentCityController.text.trim().isEmpty ||
        permanentStateController.text.trim().isEmpty ||
        permanentZipController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please complete Permanent Address or check "same as Current Address"',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    // 5. Work Experience (if applicant indicated having experience)
    if (hasWorkExperience.value) {
      if (previousCompanyController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter your Current / Last Organisation',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
        return;
      }
      if (currentDesignationController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter your Current Designation',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
        return;
      }
      if (experienceYearsController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter your Total Experience in Years',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
        return;
      }
      if (lastCtcController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter your Total Current CTC',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
        return;
      }
      if (expectedSalaryController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter your Expected CTC',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
        return;
      }
      if (noticePeriodController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter your Notice Period (Days)',
            backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
        return;
      }
    }

    // 6. Emergency Contact
    if (emergencyNameController.text.trim().isEmpty ||
        emergencyRelationController.text.trim().isEmpty ||
        emergencyPhoneController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please complete all Emergency Contact fields',
          backgroundColor: Colors.red.withValues(alpha: 0.1), colorText: Colors.red.shade900);
      return;
    }

    isLoading.value = true;
    try {
      final walkIn = buildWalkInFormModel();
      final data = {
        'fullName': nameController.text.trim(),
        'mobileNumber': phoneController.text.trim(),
        'emailAddress': emailController.text.trim(),
        'dob': dobController.text.trim().isEmpty ? null : dobController.text.trim(),
        'gender': selectedGender.value.isEmpty ? null : selectedGender.value,
        'currentAddress': {
          'street': currentStreetController.text.trim(),
          'city': currentCityController.text.trim(),
          'state': currentStateController.text.trim(),
          'zip': currentZipController.text.trim(),
        },
        'permanentAddress': {
          'street': permanentStreetController.text.trim(),
          'city': permanentCityController.text.trim(),
          'state': permanentStateController.text.trim(),
          'zip': permanentZipController.text.trim(),
        },
        'emergencyContact': {
          'name': emergencyNameController.text.trim(),
          'relation': emergencyRelationController.text.trim(),
          'phone': emergencyPhoneController.text.trim(),
        },
        'experienceYears': hasWorkExperience.value ? (int.tryParse(experienceYearsController.text.trim()) ?? 0) : 0,
        'previousCompany': hasWorkExperience.value && previousCompanyController.text.trim().isNotEmpty ? previousCompanyController.text.trim() : null,
        'lastCtc': hasWorkExperience.value && lastCtcController.text.trim().isNotEmpty ? lastCtcController.text.trim() : null,
        'appliedRoleId': selectedRole.value?['id'] ?? selectedRole.value?['_id'],
        'walkInForm': walkIn.toJson(),
      };

      final res = await _applicantService.registerApplicant(data);
      if (res.success) {
        applicantId.value = res.applicantId!;
        isRegistered.value = true;
        Get.snackbar('Verification Required', 'OTPs have been sent to your email and phone',
            backgroundColor: Colors.blue.withValues(alpha: 0.1));
      } else {
        Get.snackbar('Error', res.message ?? 'Submission failed',
            backgroundColor: Colors.red.withValues(alpha: 0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyOtps() async {
    if (mobileOtpController.text.trim().isEmpty || emailOtpController.text.trim().isEmpty) {
      Get.snackbar('Alert', 'Please enter both OTPs', backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.verifyOtp(
        applicantId.value,
        mobileOtpController.text.trim(),
        emailOtpController.text.trim(),
      );

      if (res.success) {
        isVerified.value = true;
        currentApplicant.value = res.applicant;
        Get.offNamed('/apply/continue/${applicantId.value}');
        Get.snackbar('Success', 'Contact verified successfully. Welcome to your onboarding page.', backgroundColor: Colors.green.withOpacity(0.1));
      } else {
        Get.snackbar('Verification Failed', res.message ?? 'OTPs are incorrect', backgroundColor: Colors.red.withOpacity(0.1));
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> uploadDoc(String type, {bool fromCamera = false}) async {
    try {
      FilePickerResult? result;
      if (type == 'video') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.video,
          withData: true,
        );
      } else if (fromCamera || type == 'photo') {
        result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          withData: true,
        );
      } else {
        result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'webp'],
          withData: true,
        );
      }

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        final bytes = pickedFile.bytes;

        if (bytes == null || bytes.isEmpty) {
          Get.snackbar('Upload Failed', 'Could not read file data. Please try again.', backgroundColor: Colors.red.withValues(alpha: 0.1));
          return;
        }

        // Sanitize filename to avoid 'blob' or missing extension camera issues
        String fileName = pickedFile.name.trim();
        final isVideo = type == 'video';
        final hasExt = fileName.contains('.') && fileName.split('.').last.trim().isNotEmpty;
        if (!hasExt || fileName.toLowerCase() == 'blob' || fileName.toLowerCase() == 'image') {
          final defaultExt = isVideo ? 'mp4' : 'jpg';
          fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.$defaultExt';
        }

        uploadingDocType.value = type;
        final res = isVideo
            ? await _applicantService.uploadApplicantVideo(applicantId.value, bytes, fileName)
            : await _applicantService.uploadApplicantFile(applicantId.value, type, bytes, fileName);

        uploadingDocType.value = '';
        if (res.success) {
          if (res.applicant != null) {
            currentApplicant.value = res.applicant;
          } else {
            final detailRes = await _applicantService.getApplicantDetails(applicantId.value);
            if (detailRes.applicant != null) {
              currentApplicant.value = detailRes.applicant;
            }
          }
          currentApplicant.refresh();
          Get.snackbar('Upload Success', '${type.toUpperCase()} file uploaded', backgroundColor: Colors.green.withValues(alpha: 0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred during upload', backgroundColor: Colors.red.withValues(alpha: 0.1));
        }
      }
    } catch (e) {
      uploadingDocType.value = '';
      Get.snackbar('Error', 'Failed to upload document: $e', backgroundColor: Colors.red.withValues(alpha: 0.1));
    }
  }

  void promptUploadChoice(BuildContext context, String type) {
    final title = switch (type) {
      'photo' => 'Profile Photo',
      'video' => 'KYC Video Verification',
      'pan' => 'PAN Card',
      'aadhaar' => 'Aadhaar Card',
      'nism' => 'NISM Certificate',
      'education' => 'Highest Education Certificate',
      'resume' => 'Resume / CV',
      _ => type.toUpperCase(),
    };

    if (type == 'video') {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 6),
                const Text('Choose how you would like to submit your verification video:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Record Video with Camera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Use direct camera to record video', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    uploadDoc(type, fromCamera: true);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.file_upload_outlined, color: Color(0xFF475569)),
                  ),
                  title: const Text('Choose Video File from Device', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Upload MP4, MOV, or AVI video', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    uploadDoc(type, fromCamera: false);
                  },
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    if (type == 'photo') {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                const SizedBox(height: 6),
                const Text('Take a live selfie or upload an existing photo:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Take Photo with Camera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Capture direct photo with camera', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    uploadDoc(type, fromCamera: true);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF475569)),
                  ),
                  title: const Text('Select from Gallery / Files', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Upload JPG or PNG image', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    uploadDoc(type, fromCamera: false);
                  },
                ),
              ],
            ),
          ),
        ),
      );
      return;
    }

    // Documents (PAN, Aadhaar, NISM, Education, Resume)
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Upload $title', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
              const SizedBox(height: 6),
              const Text('Take a photo of the document or select a file:', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF2563EB)),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Direct camera capture of document', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.of(ctx).pop();
                  uploadDoc(type, fromCamera: true);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.file_present_outlined, color: Color(0xFF475569)),
                ),
                title: const Text('Choose PDF or Image File', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Browse device for PDF, JPG, or PNG', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                onTap: () {
                  Navigator.of(ctx).pop();
                  uploadDoc(type, fromCamera: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
