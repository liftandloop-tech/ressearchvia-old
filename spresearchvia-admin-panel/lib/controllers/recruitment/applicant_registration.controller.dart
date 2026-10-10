import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/applicant.service.dart';
import '../../models/staff.model.dart';

class ApplicantRegistrationController extends GetxController {
  final ApplicantService _applicantService = Get.put(ApplicantService());

  // Global States
  var isLoading = false.obs;
  var uploadingDocType = ''.obs;
  var applicantId = ''.obs;
  var currentApplicant = Rxn<StaffModel>();
  var currentStep = 1.obs; // Steps 1 to 6

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

  // Step 1: Personal Information Form Controllers
  final photoUrl = ''.obs;
  final panUrl = ''.obs;
  final panNumberController = TextEditingController();
  final confirmPanNumberController = TextEditingController();
  final passportNumberController = TextEditingController();
  var selectedProofOfAddress = 'Aadhaar'.obs;
  final proofOfAddressUrl = ''.obs;
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

  // Step 4: Professional Qualifications Controllers
  var selectedProfessionalCert = 'None'.obs;
  final certRegistrationNumberController = TextEditingController();
  final certYearController = TextEditingController();
  final certDocumentUrl = ''.obs;
  final licenseMembershipDetailsController = TextEditingController();

  // Step 5: Occupational Details & Emergency Contact Controllers
  var isFresher = false.obs;
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
  final resumeUrl = ''.obs;
  final emergencyNameController = TextEditingController();
  final emergencyRelationController = TextEditingController();
  final emergencyPhoneController = TextEditingController();

  // Step 6: Preview & Submission State
  var isApplicationSubmitted = false.obs;
  final submittedApplicantId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initDefaultEducationEntries();
    fetchPublicRoles();

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
    panNumberController.text = data['panNumber']?.toString() ?? '';
    confirmPanNumberController.text = data['confirmPanNumber']?.toString() ?? data['panNumber']?.toString() ?? '';
    passportNumberController.text = data['passportNumber']?.toString() ?? '';
    selectedProofOfAddress.value = data['proofOfAddressType']?.toString() ?? 'Aadhaar';
    photoUrl.value = data['photoUrl']?.toString() ?? '';
    panUrl.value = data['panUrl']?.toString() ?? '';
    proofOfAddressUrl.value = data['proofOfAddressUrl']?.toString() ?? '';
    appliedPositionController.text = data['targetRole']?.toString() ?? '';

    // Step 2 data
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

    // Step 3 data
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

    // Step 4 data
    certDocumentUrl.value = data['nismUrl']?.toString() ?? '';

    // Step 5 data
    isFresher.value = data['isFresher'] == true || data['hasWorkExperience'] == false;
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
    resumeUrl.value = data['resumeUrl']?.toString() ?? '';
    if (data['emergencyContact'] is Map) {
      final emg = data['emergencyContact'] as Map;
      emergencyNameController.text = emg['name']?.toString() ?? '';
      emergencyRelationController.text = emg['relation']?.toString() ?? '';
      emergencyPhoneController.text = emg['phone']?.toString() ?? '';
    }

    currentStep.value = step.clamp(1, 6);
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

  Future<void> handleSendMobileOtp() async {
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

  // --- Step Navigation & Progress Saving ---

  Future<void> nextStep() async {
    final step = currentStep.value;

    // Validate Step 1
    if (step == 1) {
      if (panNumberController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter PAN Number',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (confirmPanNumberController.text.trim().toUpperCase() != panNumberController.text.trim().toUpperCase()) {
        Get.snackbar('Validation Error', 'PAN Number and Confirm PAN Number do not match',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
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
        'panNumber': panNumberController.text.trim().toUpperCase(),
        'confirmPanNumber': confirmPanNumberController.text.trim().toUpperCase(),
        'passportNumber': passportNumberController.text.trim(),
        'proofOfAddressType': selectedProofOfAddress.value,
        'photoUrl': photoUrl.value,
        'panUrl': panUrl.value,
        'proofOfAddressUrl': proofOfAddressUrl.value,
        'targetRole': (selectedRole.value?['name']?.toString() ?? appliedPositionController.text).trim(),
        'appliedRoleId': selectedRole.value?['id'] ?? selectedRole.value?['_id'],
      });
      currentStep.value = 2;
      return;
    }

    // Validate Step 2
    if (step == 2) {
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
      if (pincodeController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter Pincode',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (!isMobileVerified.value) {
        Get.snackbar('Mobile Verification Required', 'Please verify your Mobile Number before proceeding to the next step',
            backgroundColor: Colors.orange.withOpacity(0.1), colorText: Colors.deepOrange.shade900);
        return;
      }

      await _saveStepDraft(2, {
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
      currentStep.value = 3;
      return;
    }

    // Validate Step 3
    if (step == 3) {
      if (instituteUniversityController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter Institute / University Name',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }
      if (percentageGradeController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please enter Percentage / Grade',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }

      await _saveStepDraft(3, {
        'highestQualification': highestQualification.value,
        'majorSubject': majorSubject.value,
        'instituteUniversity': instituteUniversityController.text.trim(),
        'yearOfPassing': int.tryParse(yearOfPassing.value) ?? 2023,
        'percentageGrade': percentageGradeController.text.trim(),
        'academicGap': academicGap.value,
        'academicGapDetails': academicGapDetailsController.text.trim(),
        'backlogsCount': backlogsCountController.text.trim(),
        'highestEducationUrl': highestEducationUrl.value,
      });
      currentStep.value = 4;
      return;
    }

    // Validate Step 4
    if (step == 4) {
      await _saveStepDraft(4, {
        'professionalQualifications': [
          {
            'certificationName': selectedProfessionalCert.value,
            'registrationNumber': certRegistrationNumberController.text.trim(),
            'year': certYearController.text.trim(),
            'documentUrl': certDocumentUrl.value,
            'membershipDetails': licenseMembershipDetailsController.text.trim(),
          }
        ],
        'nismUrl': certDocumentUrl.value,
      });
      currentStep.value = 5;
      return;
    }

    // Validate Step 5
    if (step == 5) {
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
      }
      if (emergencyNameController.text.trim().isEmpty || emergencyPhoneController.text.trim().isEmpty) {
        Get.snackbar('Mandatory Field Missing', 'Please complete Emergency Contact Person Name and Phone Number',
            backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red.shade900);
        return;
      }

      await _saveStepDraft(5, {
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
        'emergencyContact': {
          'name': emergencyNameController.text.trim(),
          'relation': emergencyRelationController.text.trim(),
          'phone': emergencyPhoneController.text.trim(),
        },
      });
      currentStep.value = 6; // Move to Preview
      return;
    }
  }

  void previousStep() {
    if (currentStep.value > 1) {
      currentStep.value--;
    }
  }

  void goToStep(int step) {
    if (step >= 1 && step <= 6) {
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

  // --- Step 6: Final Submission ---

  Future<void> handleFinalSubmission() async {
    if (applicantId.value.isEmpty) return;

    if (!isEmailVerified.value || !isMobileVerified.value) {
      Get.snackbar('Verification Incomplete', 'Both Email and Mobile Number must be verified before submission',
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

  Future<void> pickAndUploadDoc(String type) async {
    try {
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
            } else if (type == 'pan' || type == 'pancard') {
              docUrl = app.panUrl ?? filename;
            } else if (type == 'aadhaar' || type == 'poa') {
              docUrl = app.aadhaarUrl ?? filename;
            } else if (type == 'nism' || type == 'certificate') {
              docUrl = app.nismUrl ?? filename;
            } else if (type == 'resume') {
              docUrl = app.resumeUrl ?? filename;
            } else if (type == 'highestEducation' || type == 'degree' || type == 'education') {
              docUrl = app.highestEducationUrl ?? filename;
            }
          }

          if (type == 'photo') photoUrl.value = docUrl;
          if (type == 'pan' || type == 'pancard') panUrl.value = docUrl;
          if (type == 'aadhaar' || type == 'poa') proofOfAddressUrl.value = docUrl;
          if (type == 'nism' || type == 'certificate') certDocumentUrl.value = docUrl;
          if (type == 'resume') resumeUrl.value = docUrl;
          if (type == 'highestEducation' || type == 'degree' || type == 'education') highestEducationUrl.value = docUrl;

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

  @override
  void onClose() {
    createAccountEmailController.dispose();
    confirmEmailController.dispose();
    createAccountPasswordController.dispose();
    confirmPasswordController.dispose();
    emailOtpInputController.dispose();

    panNumberController.dispose();
    confirmPanNumberController.dispose();
    passportNumberController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    fatherNameController.dispose();
    alternateEmailController.dispose();
    dobController.dispose();
    appliedPositionController.dispose();

    addressLine1Controller.dispose();
    addressLine2Controller.dispose();
    addressLine3Controller.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    telephoneResidenceCodeController.dispose();
    telephoneResidenceNumberController.dispose();
    phoneController.dispose();
    mobileOtpInputController.dispose();
    permanentStreetController.dispose();
    permanentCityController.dispose();
    permanentStateController.dispose();
    permanentZipController.dispose();

    instituteUniversityController.dispose();
    percentageGradeController.dispose();

    certRegistrationNumberController.dispose();
    certYearController.dispose();
    licenseMembershipDetailsController.dispose();

    currentCompanyController.dispose();
    currentDesignationController.dispose();
    totalExperienceYearsController.dispose();
    annualCtcController.dispose();
    noticePeriodDaysController.dispose();
    reportingManagerController.dispose();
    emergencyNameController.dispose();
    emergencyRelationController.dispose();
    emergencyPhoneController.dispose();

    super.onClose();
  }
}
