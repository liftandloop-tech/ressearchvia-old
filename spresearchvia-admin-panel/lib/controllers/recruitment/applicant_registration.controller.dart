import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/applicant.service.dart';
import '../../models/staff.model.dart';
import '../../ui/widgets/video_kyc_recorder_dialog.widget.dart';

class ApplicantRegistrationController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  // Global States
  var isLoading = false.obs;
  var uploadingDocType = ''.obs;
  var applicantId = ''.obs;
  var currentApplicant = Rxn<StaffModel>();
  var currentStep = 1.obs; // Steps 1 to 3 (Merged 1+2, Merged 3+4, Step 5->3)

  // Account Creation (Step 0) States
  var isAccountCreated = false.obs;
  var isEmailVerified = false.obs;
  var isEmailOtpModalOpen = false.obs;
  var obscurePassword = true.obs;
  var obscureConfirmPassword = true.obs;
  final createAccountEmailController = TextEditingController();
  final confirmEmailController = TextEditingController();
  final createAccountPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final emailOtpInputController = TextEditingController();

  // Dynamic Open Roles from DB
  var openRoles = <Map<String, dynamic>>[].obs;
  var isLoadingRoles = false.obs;
  var selectedRole = Rxn<Map<String, dynamic>>();
  var isCustomRole = false.obs;
  final appliedPositionController = TextEditingController();

  // Step 1: Personal & Contact Information Form Controllers
  final resumeUrl = ''.obs;
  final panUrl = ''.obs;
  final photoUrl = ''.obs;
  var selectedProofOfAddress = 'Aadhaar'.obs;
  final proofOfAddressUrl = ''.obs;
  final aadhaarBackUrl = ''.obs;
  final aadhaarNumberController = TextEditingController();
  final panNumberController = TextEditingController();
  var selectedTitle = 'Mr'.obs;
  final fullNameController = TextEditingController();
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final fatherNameController = TextEditingController();
  final alternateEmailController = TextEditingController();
  final dobController = TextEditingController();
  var selectedGender = 'Male'.obs;
  var selectedMaritalStatus = 'Single'.obs;
  final currentLocationController = TextEditingController();
  final skypeAddressController = TextEditingController();

  // Step 2: Contact Information Form Controllers
  final addressLine1Controller = TextEditingController();
  final addressLine2Controller = TextEditingController();
  final addressLine3Controller = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  var selectedState = 'Madhya Pradesh'.obs;
  var selectedCountry = 'India'.obs;
  final pincodeController = TextEditingController();
  final telephoneResidenceCodeController = TextEditingController(text: '+91');
  final telephoneResidenceNumberController = TextEditingController();
  final phoneController = TextEditingController();
  var isMobileVerified = false.obs;
  var isVerifyingMobile = false.obs;
  var isMobileOtpSent = false.obs;
  var mobileOtpCountdown = 0.obs;
  Timer? _mobileOtpTimer;
  final mobileOtpInputController = TextEditingController();
  var sameAsCurrentAddress = false.obs;
  final permanentStreetController = TextEditingController();
  final permanentCityController = TextEditingController();
  final permanentStateController = TextEditingController();
  final permanentZipController = TextEditingController();

  // Step 3: Educational Details Controllers
  var highestQualification = 'Graduation'.obs;
  var majorSubject = 'Engineering'.obs;
  final instituteUniversityController = TextEditingController();
  var yearOfPassing = '2023'.obs;
  final percentageGradeController = TextEditingController();
  var academicGap = false.obs;
  final academicGapDetailsController = TextEditingController();
  final backlogsCountController = TextEditingController();
  final highestEducationUrl = ''.obs;
  var educationEntries = <EducationEntryModel>[].obs;

  // Step 2: Educational & Professional Details Controllers
  var hasNismCert = false.obs;
  var selectedProfessionalCert = 'None'.obs;
  final certRegistrationNumberController = TextEditingController();
  final certYearController = TextEditingController();
  final certDocumentUrl = ''.obs;
  final licenseMembershipDetailsController = TextEditingController();

  // Step 5: Occupational Details & Emergency Contact Controllers
  var isFresher = true.obs; // Default to Fresher
  final currentCompanyController = TextEditingController();
  final currentDesignationController = TextEditingController();
  final totalExperienceYearsController = TextEditingController();
  final reportingManagerController = TextEditingController();
  final reportingManagerDesignationController = TextEditingController();
  final reporteesCountController = TextEditingController();
  final fixedSalaryController = TextEditingController();
  final bonusIncentiveController = TextEditingController();
  final annualCtcController = TextEditingController();
  final expectedSalaryController = TextEditingController();
  final noticePeriodDaysController = TextEditingController();
  final careerGapController = TextEditingController();
  final relievingLetterUrl = ''.obs;
  final emergencyNameController = TextEditingController();
  final emergencyRelationController = TextEditingController(text: 'Mother');
  var selectedEmergencyRelation = 'Mother'.obs;
  final otherRelationController = TextEditingController();
  final emergencyPhoneController = TextEditingController();
  final kycVideoUrl = ''.obs;

  // Step 6: Preview & Submission State
  var isApplicationSubmitted = false.obs;
  final submittedApplicantId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initDefaultEducationEntries();
    fetchPublicRoles();

    // Restore saved applicant draft ID if present
    SharedPreferences.getInstance().then((prefs) {
      final savedId = prefs.getString('applicant_draft_id');
      if (savedId != null && savedId.isNotEmpty && applicantId.value.isEmpty) {
        applicantId.value = savedId;
      }
    });

    // Check if initialized from Continue Application route arguments
    if (Get.arguments != null && Get.arguments is Map) {
      final args = Get.arguments as Map<String, dynamic>;
      if (args['applicant'] != null) {
        loadExistingApplicant(args['applicant'] as Map<String, dynamic>, args['step'] as int? ?? 1);
      }
    }
  }

  void loadExistingApplicant(Map<String, dynamic> data, int step) {
    applicantId.value = data['_id']?.toString() ?? data['id']?.toString() ?? '';
    if (applicantId.value.isNotEmpty) {
      SharedPreferences.getInstance().then((prefs) => prefs.setString('applicant_draft_id', applicantId.value));
    }
    isAccountCreated.value = true;
    isEmailVerified.value = data['isEmailVerified'] == true || true;
    createAccountEmailController.text = data['emailAddress']?.toString() ?? '';

    // Step 1 data
    selectedTitle.value = data['title']?.toString() ?? 'Mr';
    fullNameController.text = data['fullName']?.toString() ?? '';
    firstNameController.text = data['firstName']?.toString() ?? '';
    middleNameController.text = data['middleName']?.toString() ?? '';
    lastNameController.text = data['lastName']?.toString() ?? '';
    if (fullNameController.text.isNotEmpty && firstNameController.text.isEmpty) {
      final parts = fullNameController.text.split(' ');
      firstNameController.text = parts.first;
      if (parts.length > 1) lastNameController.text = parts.sublist(1).join(' ');
    } else if (fullNameController.text.isEmpty && firstNameController.text.isNotEmpty) {
      fullNameController.text = '${firstNameController.text} ${middleNameController.text} ${lastNameController.text}'.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    fatherNameController.text = data['fatherName']?.toString() ?? '';
    if (data['dob'] != null) {
      dobController.text = data['dob'].toString().split('T').first;
    }
    selectedGender.value = data['gender']?.toString() ?? 'Male';
    selectedMaritalStatus.value = data['maritalStatus']?.toString() ?? 'Single';
    currentLocationController.text = data['currentLocation']?.toString() ?? '';
    skypeAddressController.text = data['skypeOrLinkedIn']?.toString() ?? '';
    alternateEmailController.text = data['alternateEmail']?.toString() ?? '';
    selectedProofOfAddress.value = data['proofOfAddressType']?.toString() ?? 'Aadhaar';
    photoUrl.value = data['photoUrl']?.toString() ?? '';
    proofOfAddressUrl.value = data['proofOfAddressUrl']?.toString() ?? data['aadhaarUrl']?.toString() ?? '';
    aadhaarBackUrl.value = data['aadhaarBackUrl']?.toString() ?? '';
    panUrl.value = data['panUrl']?.toString() ?? '';
    resumeUrl.value = data['resumeUrl']?.toString() ?? '';
    appliedPositionController.text = data['targetRole']?.toString() ?? '';
    panNumberController.text = data['panNumber']?.toString() ?? '';
    aadhaarNumberController.text = data['aadhaarNumber']?.toString() ?? '';

    // Contact data
    if (data['currentAddress'] is Map) {
      final addr = data['currentAddress'] as Map;
      addressLine1Controller.text = addr['street']?.toString() ?? addr['line1']?.toString() ?? '';
      addressLine2Controller.text = addr['line2']?.toString() ?? '';
      addressLine3Controller.text = addr['line3']?.toString() ?? '';
      cityController.text = addr['city']?.toString() ?? '';
      stateController.text = addr['state']?.toString() ?? '';
      selectedState.value = addr['state']?.toString() ?? 'Madhya Pradesh';
      pincodeController.text = addr['zip']?.toString() ?? addr['pincode']?.toString() ?? '';
    }
    if (data['permanentAddress'] is Map) {
      final perm = data['permanentAddress'] as Map;
      permanentStreetController.text = perm['street']?.toString() ?? perm['line1']?.toString() ?? '';
      permanentCityController.text = perm['city']?.toString() ?? '';
      permanentStateController.text = perm['state']?.toString() ?? '';
      permanentZipController.text = perm['zip']?.toString() ?? '';
    }
    if (data['mobileNumber'] != null) {
      phoneController.text = data['mobileNumber'].toString().replaceAll(RegExp(r'^91'), '');
    }
    isMobileVerified.value = data['isMobileVerified'] == true;

    // Step 2 (Educational & Professional) data
    highestQualification.value = data['highestQualification']?.toString() ?? 'Graduation';
    majorSubject.value = data['majorSubject']?.toString() ?? 'Engineering';
    instituteUniversityController.text = data['instituteUniversity']?.toString() ?? '';
    if (data['yearOfPassing'] != null) {
      yearOfPassing.value = data['yearOfPassing'].toString();
    }
    percentageGradeController.text = data['percentageGrade']?.toString() ?? '';
    academicGap.value = data['academicGap'] == true;
    academicGapDetailsController.text = data['academicGapDetails']?.toString() ?? '';
    backlogsCountController.text = data['backlogsCount']?.toString() ?? '';
    highestEducationUrl.value = data['highestEducationUrl']?.toString() ?? '';

    certDocumentUrl.value = data['nismUrl']?.toString() ?? '';
    if (data['professionalQualifications'] is List && (data['professionalQualifications'] as List).isNotEmpty) {
      final cert = (data['professionalQualifications'] as List).first;
      if (cert is Map) {
        selectedProfessionalCert.value = cert['certificationName']?.toString() ?? 'None';
        licenseMembershipDetailsController.text = cert['membershipDetails']?.toString() ?? '';
        if (cert['documentUrl'] != null && cert['documentUrl'].toString().isNotEmpty) {
          certDocumentUrl.value = cert['documentUrl'].toString();
        }
      }
    }
    hasNismCert.value = certDocumentUrl.value.isNotEmpty || (selectedProfessionalCert.value != 'None' && selectedProfessionalCert.value.isNotEmpty);

    // Step 3 (Occupational & KYC) data
    isFresher.value = data['isFresher'] == true || (data['hasWorkExperience'] == false) || (!data.containsKey('isFresher') && !data.containsKey('hasWorkExperience'));
    currentCompanyController.text = data['previousCompany']?.toString() ?? '';
    currentDesignationController.text = data['currentDesignation']?.toString() ?? '';
    reportingManagerController.text = data['reportingManagerName']?.toString() ?? '';
    reportingManagerDesignationController.text = data['reportingManagerDesignation']?.toString() ?? '';
    reporteesCountController.text = data['reporteesCount']?.toString() ?? '';
    totalExperienceYearsController.text = data['experienceYears']?.toString() ?? '';
    fixedSalaryController.text = data['fixedSalary']?.toString() ?? '';
    bonusIncentiveController.text = data['bonusIncentive']?.toString() ?? '';
    annualCtcController.text = data['lastCtc']?.toString() ?? '';
    expectedSalaryController.text = data['expectedSalary']?.toString() ?? '';
    noticePeriodDaysController.text = data['noticePeriod']?.toString() ?? '';
    careerGapController.text = data['careerGapDetails']?.toString() ?? '';
    relievingLetterUrl.value = data['relievingLetterUrl']?.toString() ?? '';
    kycVideoUrl.value = data['kycVideoUrl']?.toString() ?? '';
    if (data['emergencyContact'] is Map) {
      final emg = data['emergencyContact'] as Map;
      emergencyNameController.text = emg['name']?.toString() ?? '';
      final rel = emg['relation']?.toString() ?? 'Mother';
      emergencyRelationController.text = rel;
      if (['Mother', 'Father', 'Friend', 'Sister', 'Brother', 'Other'].contains(rel)) {
        selectedEmergencyRelation.value = rel;
      } else {
        selectedEmergencyRelation.value = 'Other';
        otherRelationController.text = rel;
      }
      emergencyPhoneController.text = emg['phone']?.toString() ?? '';
    }

    int mappedStep = step;
    if (mappedStep <= 2) {
      mappedStep = 1;
    } else if (mappedStep <= 4) {
      mappedStep = 2;
    } else {
      mappedStep = 3;
    }
    currentStep.value = mappedStep.clamp(1, 3);
  }

  void toggleSameAsCurrentAddress(bool value) {
    sameAsCurrentAddress.value = value;
    if (value) {
      permanentStreetController.text = addressLine1Controller.text;
      permanentCityController.text = cityController.text;
      permanentStateController.text = selectedState.value;
      permanentZipController.text = pincodeController.text;
    } else {
      permanentStreetController.clear();
      permanentCityController.clear();
      permanentStateController.clear();
      permanentZipController.clear();
    }
  }

  void togglePasswordVisibility() => obscurePassword.value = !obscurePassword.value;
  void toggleConfirmPasswordVisibility() => obscureConfirmPassword.value = !obscureConfirmPassword.value;

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

  void initDefaultEducationEntries() {
    if (educationEntries.isEmpty) {
      educationEntries.assignAll([
        EducationEntryModel(standard: '10th'),
        EducationEntryModel(standard: '12th'),
        EducationEntryModel(standard: 'Graduation'),
      ]);
    }
  }

  // --- Step 0: Account Creation Methods ---

  Future<void> handleCreateAccount() async {
    final email = createAccountEmailController.text.trim().toLowerCase();
    final confirmEmail = confirmEmailController.text.trim().toLowerCase();
    final password = createAccountPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (email.isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please enter your Email Address',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }
    if (!email.contains('@')) {
      Get.snackbar('Invalid Input', 'Please enter a valid Email Address',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }
    if (email != confirmEmail) {
      Get.snackbar('Validation Error', 'Email Address and Confirm Email Address do not match',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }
    if (password.length < 6) {
      Get.snackbar('Password Too Short', 'Password must be at least 6 characters long',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }
    if (password != confirmPassword) {
      Get.snackbar('Validation Error', 'Password and Confirm Password do not match',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.createAccount(email, password);
      if (res.success && res.applicantId != null) {
        applicantId.value = res.applicantId!;
        SharedPreferences.getInstance().then((prefs) => prefs.setString('applicant_draft_id', applicantId.value));
        isEmailOtpModalOpen.value = true;
        Get.snackbar('Code Dispatched', 'A 4-digit verification code was sent to $email',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade900);
      } else {
        Get.snackbar('Account Creation Failed', res.message ?? 'An error occurred',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleVerifyEmailOtp() async {
    final otp = emailOtpInputController.text.trim();
    if (otp.isEmpty || otp.length < 4) {
      Get.snackbar('Input Error', 'Please enter the 4-digit code sent to your email',
          backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.verifyAccountEmail(applicantId.value, otp);
      if (res.success) {
        if (res.applicant != null) {
          final aid = res.applicant!['_id']?.toString() ?? res.applicant!['id']?.toString();
          if (aid != null && aid.isNotEmpty) {
            applicantId.value = aid;
          }
        }
        SharedPreferences.getInstance().then((prefs) => prefs.setString('applicant_draft_id', applicantId.value));
        isEmailVerified.value = true;
        isAccountCreated.value = true;
        isEmailOtpModalOpen.value = false;
        currentStep.value = 1;
        Get.snackbar('Email Verified', 'Welcome! Please fill in your application details.',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade900);
      } else {
        Get.snackbar('Verification Failed', res.message ?? 'Invalid or expired OTP',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> handleResendEmailOtp() async {
    final email = createAccountEmailController.text.trim();
    isLoading.value = true;
    try {
      final res = await _applicantService.resendEmailOtp(applicantId.value, email);
      if (res.success) {
        Get.snackbar('New Code Dispatched', res.message ?? 'A fresh OTP was sent to your email',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade900);
      } else {
        Get.snackbar('Resend Failed', res.message ?? 'Unable to send OTP',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // --- Step 2: In-Screen Mobile OTP Methods ---

  void startMobileOtpTimer() {
    _mobileOtpTimer?.cancel();
    mobileOtpCountdown.value = 59;
    _mobileOtpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mobileOtpCountdown.value > 0) {
        mobileOtpCountdown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> handleSendMobileOtp() async {
    if (mobileOtpCountdown.value > 0) return;

    final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (phone.length < 10) {
      Get.snackbar('Invalid Mobile Number', 'Please enter a valid 10-digit mobile number',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }

    isVerifyingMobile.value = true;
    try {
      final res = await _applicantService.sendMobileOtp(applicantId.value, phone);
      if (res.success) {
        isMobileOtpSent.value = true;
        startMobileOtpTimer();
        Get.snackbar('SMS Code Dispatched', 'A 4-digit verification code was sent to +91 $phone',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade900);
      } else {
        Get.snackbar('Failed to Send OTP', res.message ?? 'SMS gateway error',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isVerifyingMobile.value = false;
    }
  }

  Future<void> handleVerifyMobileOtp() async {
    final phone = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    final otp = mobileOtpInputController.text.trim();
    if (otp.length < 4) {
      Get.snackbar('Invalid OTP', 'Please enter the 4-digit code sent to your mobile',
          backgroundColor: Colors.orange.withOpacity(0.1));
      return;
    }

    isVerifyingMobile.value = true;
    try {
      final res = await _applicantService.verifyMobileOtp(applicantId.value, phone, otp);
      if (res.success) {
        isMobileVerified.value = true;
        _mobileOtpTimer?.cancel();
        mobileOtpCountdown.value = 0;
        mobileOtpInputController.clear();
        Get.snackbar('Mobile Verified', 'Your mobile number +91 $phone has been verified successfully and locked.',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade900);
      } else {
        Get.snackbar('Verification Failed', res.message ?? 'Invalid or expired mobile OTP',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isVerifyingMobile.value = false;
    }
  }

  // --- Step Navigation & Progress Saving (3-Step Unified Form) ---

  Future<void> nextStep() async {
    final step = currentStep.value;

    // Validate Step 1: Personal & Contact Information
    if (step == 1) {
      if (firstNameController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter First Name',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (lastNameController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter Last Name',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (fatherNameController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', "Please enter Father's Name",
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (dobController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please select Date of Birth',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (photoUrl.value.isEmpty) {
        Get.snackbar('Mandatory Document Missing', 'Please upload your Profile Photo',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (resumeUrl.value.isEmpty) {
        Get.snackbar('Mandatory Document Missing', 'Please upload your Resume / CV',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (proofOfAddressUrl.value.isEmpty) {
        Get.snackbar('Mandatory Document Missing', 'Please upload Aadhaar Card (Front)',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (aadhaarBackUrl.value.isEmpty) {
        Get.snackbar('Mandatory Document Missing', 'Please upload Aadhaar Card (Back)',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      final cleanAadhaar = aadhaarNumberController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (cleanAadhaar.length != 12) {
        Get.snackbar('Mandatory Field Missing', 'Please enter a valid 12-digit Aadhaar Number',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (addressLine1Controller.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter Address Line 1',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (cityController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter City',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      final cleanMobile = phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
      if (cleanMobile.length < 10) {
        Get.snackbar('Mandatory Field Missing', 'Please enter a valid 10-digit Mobile Number',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }

      await _saveStepDraft(1, {
        'title': selectedTitle.value,
        'firstName': firstNameController.text.trim(),
        'middleName': middleNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'fatherName': fatherNameController.text.trim(),
        'fullName': fullNameController.text.trim().isNotEmpty
            ? fullNameController.text.trim()
            : '${firstNameController.text.trim()} ${middleNameController.text.trim()} ${lastNameController.text.trim()}'.replaceAll(RegExp(r'\s+'), ' ').trim(),
        'dob': dobController.text.trim(),
        'gender': selectedGender.value,
        'maritalStatus': selectedMaritalStatus.value,
        'currentLocation': currentLocationController.text.trim(),
        'skypeOrLinkedIn': skypeAddressController.text.trim(),
        'alternateEmail': alternateEmailController.text.trim(),
        'photoUrl': photoUrl.value,
        'resumeUrl': resumeUrl.value,
        'panUrl': panUrl.value,
        'panNumber': panNumberController.text.trim().toUpperCase(),
        'aadhaarNumber': cleanAadhaar,
        'proofOfAddressUrl': proofOfAddressUrl.value,
        'aadhaarUrl': proofOfAddressUrl.value,
        'aadhaarBackUrl': aadhaarBackUrl.value,
        'proofOfAddressType': selectedProofOfAddress.value,
        'targetRole': (selectedRole.value?['name']?.toString() ?? appliedPositionController.text).trim(),
        'appliedRoleId': selectedRole.value?['id'] ?? selectedRole.value?['_id'],
        'mobileNumber': cleanMobile,
        'currentAddress': {
          'line1': addressLine1Controller.text.trim(),
          'line2': addressLine2Controller.text.trim(),
          'line3': addressLine3Controller.text.trim(),
          'street': addressLine1Controller.text.trim(),
          'city': cityController.text.trim(),
          'state': selectedState.value,
          'zip': pincodeController.text.trim(),
          'country': selectedCountry.value,
        },
        'permanentAddress': {
          'line1': permanentStreetController.text.trim().isNotEmpty ? permanentStreetController.text.trim() : addressLine1Controller.text.trim(),
          'street': permanentStreetController.text.trim().isNotEmpty ? permanentStreetController.text.trim() : addressLine1Controller.text.trim(),
          'city': permanentCityController.text.trim().isNotEmpty ? permanentCityController.text.trim() : cityController.text.trim(),
          'state': permanentStateController.text.trim().isNotEmpty ? permanentStateController.text.trim() : selectedState.value,
          'zip': permanentZipController.text.trim().isNotEmpty ? permanentZipController.text.trim() : pincodeController.text.trim(),
        },
        'telephoneResidence': {
          'code': telephoneResidenceCodeController.text.trim(),
          'number': telephoneResidenceNumberController.text.trim(),
        },
      });
      currentStep.value = 2;
      return;
    }

    // Validate Step 2: Educational & Professional Details
    if (step == 2) {
      if (hasNismCert.value) {
        if (selectedProfessionalCert.value == 'None' || selectedProfessionalCert.value.isEmpty) {
          selectedProfessionalCert.value = 'NISM Series XV (Research Analyst)';
        }
      }

      await _saveStepDraft(2, {
        'highestQualification': highestQualification.value,
        'majorSubject': majorSubject.value,
        'instituteUniversity': instituteUniversityController.text.trim(),
        'yearOfPassing': int.tryParse(yearOfPassing.value),
        'percentageGrade': percentageGradeController.text.trim(),
        'highestEducationUrl': highestEducationUrl.value,
        'hasNismCert': hasNismCert.value,
        'professionalQualifications': hasNismCert.value
            ? [
                {
                  'certificationName': selectedProfessionalCert.value,
                  'documentUrl': certDocumentUrl.value,
                  'membershipDetails': licenseMembershipDetailsController.text.trim(),
                }
              ]
            : [],
        'nismUrl': hasNismCert.value ? certDocumentUrl.value : null,
      });
      currentStep.value = 3;
      return;
    }

    // Step 3: Occupational Details (Last Step)
    if (step == 3) {
      await submitApplicationFromStep3();
      return;
    }
  }

  Future<void> submitApplicationFromStep3() async {
    if (!isFresher.value) {
      if (currentCompanyController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter Current / Previous Company Name',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (currentDesignationController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter Current Designation',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (relievingLetterUrl.value.isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please upload your Relieving Letter from previous employer',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
    }
    if (emergencyNameController.text.trim().isEmpty || emergencyPhoneController.text.trim().isEmpty) {
      Get.snackbar('Mandatory Field Missing', 'Please complete Emergency Contact Person Name and Phone Number',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }
    final phoneDigits = emergencyPhoneController.text.trim();
    if (!RegExp(r'^\d+$').hasMatch(phoneDigits)) {
      Get.snackbar('Invalid Emergency Contact', 'Emergency contact number must contain only numeric digits',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }

    final rel = selectedEmergencyRelation.value == 'Other' && otherRelationController.text.trim().isNotEmpty
        ? otherRelationController.text.trim()
        : (selectedEmergencyRelation.value.isNotEmpty ? selectedEmergencyRelation.value : emergencyRelationController.text.trim());

    await _saveStepDraft(3, {
      'isFresher': isFresher.value,
      'hasWorkExperience': !isFresher.value,
      'previousCompany': isFresher.value ? null : currentCompanyController.text.trim(),
      'currentDesignation': isFresher.value ? null : currentDesignationController.text.trim(),
      'reportingManagerName': isFresher.value ? null : reportingManagerController.text.trim(),
      'reportingManagerDesignation': isFresher.value ? null : reportingManagerDesignationController.text.trim(),
      'reporteesCount': isFresher.value ? 0 : (int.tryParse(reporteesCountController.text.trim()) ?? 0),
      'experienceYears': isFresher.value ? 0 : (int.tryParse(totalExperienceYearsController.text.trim()) ?? 0),
      'fixedSalary': isFresher.value ? null : fixedSalaryController.text.trim(),
      'bonusIncentive': isFresher.value ? null : bonusIncentiveController.text.trim(),
      'lastCtc': isFresher.value ? null : annualCtcController.text.trim(),
      'expectedSalary': isFresher.value ? null : expectedSalaryController.text.trim(),
      'noticePeriod': isFresher.value ? null : noticePeriodDaysController.text.trim(),
      'careerGapDetails': isFresher.value ? null : careerGapController.text.trim(),
      'resumeUrl': resumeUrl.value,
      'relievingLetterUrl': isFresher.value ? null : relievingLetterUrl.value,
      'kycVideoUrl': kycVideoUrl.value,
      'emergencyContact': {
        'name': emergencyNameController.text.trim(),
        'relation': rel,
        'phone': phoneDigits,
      },
    });

    await handleFinalSubmission();
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 3) {
      currentStep.value = step;
    }
  }

  Future<void> _saveStepDraft(int step, Map<String, dynamic> data) async {
    if (applicantId.value.isEmpty) return;
    try {
      await _applicantService.saveStep(applicantId.value, step, data);
    } catch (e) {
      debugPrint('Autosave step $step warning: $e');
    }
  }

  // --- Final Submission ---

  Future<void> handleFinalSubmission() async {
    if (applicantId.value.isEmpty) return;

    if (!isEmailVerified.value) {
      Get.snackbar('Verification Incomplete', 'Email must be verified before submission',
          backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      return;
    }

    isLoading.value = true;
    try {
      final res = await _applicantService.finalizeApplication(applicantId.value);
      if (res.success) {
        isApplicationSubmitted.value = true;
        submittedApplicantId.value = res.applicant?['applicantId']?.toString() ?? applicantId.value;
        Get.snackbar('Application Submitted', 'Your application has been received successfully! Our HR team will contact you.',
            backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green.shade900, duration: const Duration(seconds: 5));
      } else {
        Get.snackbar('Submission Failed', res.message ?? 'An error occurred during final submission',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // --- Document Upload Handlers ---

  Future<bool> ensureApplicantDraftExists() async {
    if (applicantId.value.isNotEmpty) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('applicant_draft_id');
      if (savedId != null && savedId.isNotEmpty) {
        applicantId.value = savedId;
        return true;
      }

      // Auto-create draft applicant profile if needed
      final email = createAccountEmailController.text.trim().isNotEmpty
          ? createAccountEmailController.text.trim().toLowerCase()
          : (alternateEmailController.text.trim().isNotEmpty
              ? alternateEmailController.text.trim().toLowerCase()
              : 'applicant_${DateTime.now().millisecondsSinceEpoch}@temp.com');
      final password = createAccountPasswordController.text.isNotEmpty
          ? createAccountPasswordController.text
          : 'DraftPass@123';

      final res = await _applicantService.createAccount(email, password);
      if (res.success && res.applicantId != null) {
        applicantId.value = res.applicantId!;
        await prefs.setString('applicant_draft_id', applicantId.value);
        return true;
      }
    } catch (e) {
      debugPrint('ensureApplicantDraftExists error: $e');
    }
    return applicantId.value.isNotEmpty;
  }

  Future<void> pickAndUploadDoc(String type) async {
    try {
      await ensureApplicantDraftExists();
      FilePickerResult? result;
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        uploadingDocType.value = type;
        final bytes = result.files.single.bytes!;
        final filename = result.files.single.name;

        final res = await _applicantService.uploadApplicantFile(
          applicantId.value,
          type,
          bytes,
          filename,
        );

        uploadingDocType.value = '';
        if (res.success) {
          String docUrl = filename;
          if (res.applicant != null) {
            final app = res.applicant!;
            if (type == 'photo') {
              docUrl = app.photoUrl ?? filename;
            } else if (type == 'aadhaar' || type == 'poa' || type == 'aadhaarFront' || type == 'aadhaar_front') {
              docUrl = app.aadhaarUrl ?? filename;
            } else if (type == 'aadhaarBack' || type == 'aadhaar_back') {
              docUrl = app.aadhaarBackUrl ?? filename;
            } else if (type == 'nism' || type == 'certificate') {
              docUrl = app.nismUrl ?? filename;
            } else if (type == 'resume') {
              docUrl = app.resumeUrl ?? filename;
            } else if (type == 'pan' || type == 'pancard') {
              docUrl = app.panUrl ?? filename;
            } else if (type == 'highestEducation' || type == 'degree' || type == 'education') {
              docUrl = app.highestEducationUrl ?? filename;
            } else if (type == 'relievingLetter' || type == 'relieving' || type == 'relieving_letter') {
              docUrl = app.relievingLetterUrl ?? filename;
            }
          }

          if (type == 'photo') photoUrl.value = docUrl;
          if (type == 'aadhaar' || type == 'poa' || type == 'aadhaarFront' || type == 'aadhaar_front') proofOfAddressUrl.value = docUrl;
          if (type == 'aadhaarBack' || type == 'aadhaar_back') aadhaarBackUrl.value = docUrl;
          if (type == 'nism' || type == 'certificate') certDocumentUrl.value = docUrl;
          if (type == 'resume') resumeUrl.value = docUrl;
          if (type == 'pan' || type == 'pancard') panUrl.value = docUrl;
          if (type == 'highestEducation' || type == 'degree' || type == 'education') highestEducationUrl.value = docUrl;
          if (type == 'relievingLetter' || type == 'relieving' || type == 'relieving_letter') relievingLetterUrl.value = docUrl;

          Get.snackbar('Upload Successful', '${type.toUpperCase()} file uploaded',
              backgroundColor: Colors.green.withOpacity(0.1));
        } else {
          Get.snackbar('Upload Failed', res.message ?? 'File upload error',
              backgroundColor: Colors.red.withOpacity(0.1));
        }
      }
    } catch (e) {
      uploadingDocType.value = '';
      Get.snackbar('Upload Error', e.toString(), backgroundColor: Colors.red.withOpacity(0.1));
    }
  }

  final isUploadingVideo = false.obs;

  Future<void> pickAndUploadVideo() async {
    // For job applicants, Video KYC must be recorded live with camera.
    if (Get.context != null) {
      handleVideoKyc(Get.context!);
    }
  }

  Future<bool> uploadRecordedVideo(Uint8List bytes, String filename) async {
    try {
      isUploadingVideo.value = true;
      uploadingDocType.value = 'kycVideo';
      await ensureApplicantDraftExists();

      final applicantEmail = createAccountEmailController.text.trim().isNotEmpty
          ? createAccountEmailController.text.trim().toLowerCase()
          : (alternateEmailController.text.trim().isNotEmpty
              ? alternateEmailController.text.trim().toLowerCase()
              : null);

      debugPrint('[ApplicantReg] Uploading KYC video. ID: "${applicantId.value}", email: "$applicantEmail", bytes: ${bytes.length}');

      final res = await _applicantService.uploadApplicantVideo(
        applicantId.value,
        bytes,
        filename,
        email: applicantEmail,
      );
      isUploadingVideo.value = false;
      uploadingDocType.value = '';
      if (res.success) {
        if (applicantId.value.isEmpty && res.applicant != null) {
          final resolvedId = res.applicant?.applicantId ?? res.applicant?.id;
          if (resolvedId != null && resolvedId.isNotEmpty) {
            applicantId.value = resolvedId;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('applicant_draft_id', resolvedId);
          }
        }

        final videoPath = res.applicant?.kycVideoUrl ?? filename;
        kycVideoUrl.value = videoPath;
        Get.snackbar(
          'Video KYC Recorded',
          'Your verification video was uploaded successfully',
          backgroundColor: const Color(0xFFECFDF5),
          colorText: const Color(0xFF065F46),
          icon: const Icon(Icons.check_circle, color: Color(0xFF059669)),
        );
        return true;
      } else {
        Get.snackbar(
          'Upload Failed',
          res.message ?? 'Video upload error',
          backgroundColor: const Color(0xFFFEF2F2),
          colorText: const Color(0xFF991B1B),
          icon: const Icon(Icons.error_outline, color: Color(0xFFDC2626)),
        );
        return false;
      }
    } catch (e) {
      isUploadingVideo.value = false;
      uploadingDocType.value = '';
      Get.snackbar('Upload Error', e.toString(), backgroundColor: const Color(0xFFFEF2F2), colorText: const Color(0xFF991B1B));
      return false;
    }
  }

  void handleVideoKyc(BuildContext context) {
    final fullName = '${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : 'Applicant';
    VideoKycRecorderDialog.showRecorder(
      context: context,
      applicantName: displayName,
      onVideoRecorded: (bytes, filename) async {
        return await uploadRecordedVideo(bytes, filename);
      },
    );
  }

  @override
  void onClose() {
    _mobileOtpTimer?.cancel();
    super.onClose();
  }
}
