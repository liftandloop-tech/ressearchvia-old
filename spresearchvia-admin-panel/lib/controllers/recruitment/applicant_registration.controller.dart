import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/applicant.service.dart';
import '../../models/staff.model.dart';

class ApplicantRegistrationController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  var isLoading = false.obs;
  var isRegistered = false.obs;
  var isVerified = false.obs;
  var applicantId = ''.obs;
  var currentApplicant = Rxn<StaffModel>();

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

  final permanentStreetController = TextEditingController();
  final permanentCityController = TextEditingController();
  final permanentStateController = TextEditingController();
  final permanentZipController = TextEditingController();

  // Emergency contact
  final emergencyNameController = TextEditingController();
  final emergencyRelationController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  // Declarations & Screening
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

  // Professional & Compensation
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

  // Employment History
  var employmentEntries = <EmploymentEntryModel>[].obs;
  final careerGapController = TextEditingController();

  // OTP field controllers
  final mobileOtpController = TextEditingController();
  final emailOtpController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    initDefaultEducationEntries();
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
      appliedPosition: appliedPositionController.text.trim(),
      applicationDate: DateTime.now().toIso8601String().split('T').first,
      fullName: nameController.text.trim(),
      dob: dobController.text.trim(),
      nativePlace: nativePlaceController.text.trim(),
      gender: selectedGender.value,
      maritalStatus: selectedMaritalStatus.value,
      mobileNumber: phoneController.text.trim(),
      currentLocation: currentLocationController.text.trim().isNotEmpty
          ? currentLocationController.text.trim()
          : currentCityController.text.trim(),
      emailAddress: emailController.text.trim(),
      skypeAddress: skypeAddressController.text.trim(),
      interviewedBefore: interviewedBefore.value,
      interviewedBeforeDetails: interviewedBeforeDetailsController.text.trim(),
      smoke: smoke.value,
      alcohol: alcohol.value,
      differentlyAbled: differentlyAbled.value,
      differentlyAbledDetails: differentlyAbledDetailsController.text.trim(),
      policeRecord: policeRecord.value,
      policeRecordDetails: policeRecordDetailsController.text.trim(),
      majorIllness: majorIllness.value,
      majorIllnessDetails: majorIllnessDetailsController.text.trim(),
      source: selectedSource.value,
      sourceDetails: sourceDetailsController.text.trim(),
      educationList: educationEntries.toList(),
      academicGap: academicGap.value,
      academicGapDetails: academicGapDetailsController.text.trim(),
      backlogsCount: backlogsCountController.text.trim(),
      currentOrganisation: previousCompanyController.text.trim(),
      currentDesignation: currentDesignationController.text.trim(),
      reportingManagerDesignation: reportingManagerDesignationController.text.trim(),
      reportingManagerName: reportingManagerNameController.text.trim(),
      reporteesCount: reporteesCountController.text.trim(),
      totalExperience: experienceYearsController.text.trim(),
      fixedSalary: fixedSalaryController.text.trim(),
      bonusIncentive: bonusIncentiveController.text.trim(),
      totalSalary: lastCtcController.text.trim(),
      expectedSalary: expectedSalaryController.text.trim(),
      noticePeriod: noticePeriodController.text.trim(),
      employmentList: employmentEntries.toList(),
      careerGap: careerGapController.text.trim(),
    );
  }

  Future<void> submitApplication() async {
    if (nameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty) {
      Get.snackbar('Alert', 'Full Name, Phone, and Email are required', backgroundColor: Colors.orange.withOpacity(0.1));
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
        'experienceYears': int.tryParse(experienceYearsController.text.trim()) ?? 0,
        'previousCompany': previousCompanyController.text.trim().isEmpty ? null : previousCompanyController.text.trim(),
        'lastCtc': lastCtcController.text.trim().isEmpty ? null : lastCtcController.text.trim(),
        'walkInForm': walkIn.toJson(),
      };

      final res = await _applicantService.registerApplicant(data);
      if (res.success) {
        applicantId.value = res.applicantId!;
        isRegistered.value = true;
        Get.snackbar('Verification Required', 'OTPs have been sent to your email and phone', backgroundColor: Colors.blue.withOpacity(0.1));
      } else {
        Get.snackbar('Error', res.message ?? 'Submission failed', backgroundColor: Colors.red.withOpacity(0.1));
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

  Future<void> uploadDoc(String type) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: type == 'video' ? ['mp4', 'mov', 'avi'] : ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.single.bytes != null) {
        isLoading.value = true;
        final res = type == 'video'
            ? await _applicantService.uploadApplicantVideo(applicantId.value, result.files.single.bytes!, result.files.single.name)
            : await _applicantService.uploadApplicantFile(applicantId.value, type, result.files.single.bytes!, result.files.single.name);

        isLoading.value = false;
        if (res.success) {
          Get.snackbar('Upload Success', '${type.toUpperCase()} file uploaded', backgroundColor: Colors.green.withOpacity(0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'An error occurred', backgroundColor: Colors.red.withOpacity(0.1));
        }
      }
    } catch (e) {
      isLoading.value = false;
      Get.snackbar('Error', 'Failed to upload document: $e', backgroundColor: Colors.red.withOpacity(0.1));
    }
  }
}
