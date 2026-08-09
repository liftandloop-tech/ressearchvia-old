import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearchvia/widgets/button.dart';
import 'package:spresearchvia/widgets/state_selector.dart';
import 'package:spresearchvia/widgets/title_field.dart';
import 'package:spresearchvia/controllers/digio.controller.dart';
import 'package:spresearchvia/controllers/user.controller.dart';
import 'package:spresearchvia/core/theme/app_theme.dart';
import '../../services/snackbar.service.dart';

class KycFallbackFormScreen extends StatefulWidget {
  const KycFallbackFormScreen({super.key});

  @override
  State<KycFallbackFormScreen> createState() => _KycFallbackFormScreenState();
}

class _KycFallbackFormScreenState extends State<KycFallbackFormScreen> {

  
  // Controllers
  final firstNameController = TextEditingController();
  final middleNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final fatherNameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final panController = TextEditingController();
  final housePlotController = TextEditingController();
  final streetController = TextEditingController();
  final areaController = TextEditingController();
  final landmarkController = TextEditingController();
  final pincodeController = TextEditingController();
  final dobController = TextEditingController(); // Need a date picker ideally, but text for now based on backend expectation
  
  String? selectedState;

  late final DigioController digioController;
  final UserController userController = Get.find<UserController>();

  @override
  void initState() {
    super.initState();
    digioController = Get.isRegistered<DigioController>()
        ? Get.find<DigioController>()
        : Get.put(DigioController());

    // Initial fill
    _populateUserDetails(userController.currentUser.value);
    
    // Listen for changes
    ever(userController.currentUser, (user) {
      _populateUserDetails(user);
    });
  }

  void _populateUserDetails(user) {
    if (user != null) {
      if (emailController.text.isEmpty) emailController.text = user.email ?? '';
      if (mobileController.text.isEmpty) mobileController.text = user.phone ?? '';
      if (panController.text.isEmpty) panController.text = user.panNumber ?? '';
      
      // Populate Names
      if (user.personalInformation != null) {
         if (firstNameController.text.isEmpty) firstNameController.text = user.personalInformation!.firstName ?? '';
         if (middleNameController.text.isEmpty) middleNameController.text = user.personalInformation!.middleName ?? '';
         if (lastNameController.text.isEmpty) lastNameController.text = user.personalInformation!.lastName ?? '';
         if (fatherNameController.text.isEmpty) fatherNameController.text = user.personalInformation!.fatherName ?? '';
      } else if (user.fullName != null) {
         // Fallback split if personal info is missing
         final parts = user.fullName!.split(' ');
         if (firstNameController.text.isEmpty && parts.isNotEmpty) firstNameController.text = parts[0];
         if (lastNameController.text.isEmpty && parts.length > 1) lastNameController.text = parts.last;
      }
      
      // Populate Address if available
      if (user.addressDetails != null) {
          if (housePlotController.text.isEmpty) housePlotController.text = user.addressDetails!.houseNo ?? '';
          if (streetController.text.isEmpty) streetController.text = user.addressDetails!.streetAddress ?? '';
          if (areaController.text.isEmpty) areaController.text = user.addressDetails!.area ?? '';
          if (landmarkController.text.isEmpty) landmarkController.text = user.addressDetails!.landmark ?? '';
          if (pincodeController.text.isEmpty) pincodeController.text = user.addressDetails!.pincode?.toString() ?? '';
          if (selectedState == null) setState(() { selectedState = user.addressDetails!.state; });
      }

      // Prefill DOB
      if (dobController.text.isEmpty) {
        String? rawDob = user.dateOfBirth;
        if (rawDob == null && user.userObject != null) {
            rawDob = user.userObject!['APP_DOB_DT']?.toString();
        }
        
        if (rawDob != null && rawDob.isNotEmpty) {
            try {
               DateTime? dt = DateTime.tryParse(rawDob);
               if (dt != null) {
                   final day = dt.day.toString().padLeft(2, '0');
                   final month = dt.month.toString().padLeft(2, '0');
                   final year = dt.year;
                   dobController.text = "$day-$month-$year";
               } else if (rawDob.contains('-') && rawDob.split('-')[0].length == 2) {
                   dobController.text = rawDob;
               } else {
                   dobController.text = rawDob;
               }
            } catch (e) {
               debugPrint("Error parsing DOB: $e");
               dobController.text = rawDob;
            }
        }
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    fatherNameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    panController.dispose();
    housePlotController.dispose();
    streetController.dispose();
    areaController.dispose();
    landmarkController.dispose();
    pincodeController.dispose();
    dobController.dispose();
    super.dispose();
  }
  
  Future<void> _submit() async {
    // Basic validation
    if (firstNameController.text.isEmpty ||
        lastNameController.text.isEmpty ||
        fatherNameController.text.isEmpty ||
        emailController.text.isEmpty ||
        mobileController.text.isEmpty ||
        panController.text.isEmpty ||
        housePlotController.text.isEmpty ||
        streetController.text.isEmpty ||
        areaController.text.isEmpty ||
        landmarkController.text.isEmpty ||
        pincodeController.text.isEmpty ||
        selectedState == null ||
        dobController.text.isEmpty) { 
      SnackbarService.showWarning('Please fill all required fields');
      return;
    }

    final formData = {
      'firstName': firstNameController.text,
      'middleName': middleNameController.text,
      'lastName': lastNameController.text,
      'fatherName': fatherNameController.text,
      'dob': dobController.text, // Ensure format matches what backend expects
      'email': emailController.text,
      'pan': panController.text,
      'housePvNo': housePlotController.text,
      'street': streetController.text,
      'area': areaController.text,
      'landmark': landmarkController.text,
      'city': areaController.text, // Mapping area to city if needed, or ask user? Backend uses 'city' fallback
      'pincode': pincodeController.text,
      'state': selectedState,
    };

    final userId = await userController.userId;
    if (userId != null) {
        await digioController.connectDigioWithFallback(
          userId: userId,
          formData: formData,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Personal Details',
           style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.primaryBlue),
          onPressed: () => Get.back(),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               const Text(
                'Please provide your details as the verification service could not fetch them automatically.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              
              Obx(() {
                final user = userController.currentUser.value;
                final isNameReadOnly = user?.fullName != null && user!.fullName!.isNotEmpty;
                // Or robust check: checks if backend actually has the data
                
                return Column(
                  children: [
                    TitleField(
                      title: 'FIRST NAME *',
                      hint: 'Enter your first name',
                      controller: firstNameController,
                    ),
                    const SizedBox(height: 16),
                    TitleField(
                      title: 'MIDDLE NAME',
                      hint: 'Enter your middle name (optional)',
                      controller: middleNameController,
                    ),
                    const SizedBox(height: 16),
                    TitleField(
                      title: 'LAST NAME *',
                      hint: 'Enter your last name',
                      controller: lastNameController,
                    ),
                    const SizedBox(height: 16),
                    TitleField(
                      title: "FATHER'S NAME *",
                      hint: "Enter your father's name",
                      controller: fatherNameController,
                    ),
                    const SizedBox(height: 16),
                    
                    TitleField(
                      title: "DATE OF BIRTH (DD-MM-YYYY) *",
                      hint: "DD-MM-YYYY",
                      controller: dobController,
                      // Editable if missing
                      readOnly: dobController.text.isNotEmpty, 
                    ),
                    const SizedBox(height: 16),
                    
                    TitleField(
                      title: 'EMAIL ADDRESS *',
                      hint: 'Enter your email address',
                      controller: emailController,
                      readOnly: emailController.text.isNotEmpty,
                    ),
                    const SizedBox(height: 16),
                    TitleField(
                      title: 'MOBILE NUMBER *',
                      hint: 'Enter your 10-digit mobile number',
                      controller: mobileController,
                      readOnly: mobileController.text.isNotEmpty,
                    ),
                     const SizedBox(height: 16),
                    TitleField(
                      title: 'PAN CARD NUMBER *',
                      hint: 'Enter your PAN card number',
                      controller: panController,
                      // Readonly if prefilled
                      readOnly: panController.text.isNotEmpty,
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),
              TitleField(
                title: 'HOUSE/PLOT NUMBER *',
                hint: 'Enter house/plot number',
                controller: housePlotController,
              ),
              const SizedBox(height: 16),
              TitleField(
                title: 'STREET ADDRESS *',
                hint: 'Enter street address',
                controller: streetController,
              ),
              const SizedBox(height: 16),
              TitleField(
                title: 'AREA/LOCALITY *',
                hint: 'Enter area or locality',
                controller: areaController,
              ),
              const SizedBox(height: 16),
              TitleField(
                title: 'LANDMARK *',
                hint: 'Enter nearby landmark',
                controller: landmarkController,
              ),
               const SizedBox(height: 16),
              TitleField(
                title: 'PINCODE *',
                hint: 'Enter 6-digit pincode',
                controller: pincodeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              const SizedBox(height: 16),
              StateSelector(
                label: 'STATE *',
                hint: 'Enter your state',
                value: selectedState,
                onChanged: (val) {
                  setState(() {
                    selectedState = val;
                  });
                },
              ),
              const SizedBox(height: 30),
              Obx(() => Button(
                title: 'Submit & Proceed',
                onTap: digioController.connecting.value ? null : _submit,
                showLoading: digioController.connecting.value,
                buttonType: ButtonType.blue,
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
