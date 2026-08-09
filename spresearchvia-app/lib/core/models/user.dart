import 'research_report.dart';
import 'subscription_history.dart';

enum KycStatus { verified, waitingForReview, inProgress, rejected, notStarted }

enum PlanType { basic, premium, enterprise }

class User {
  final String id;
  final String? fullName;
  final String? email;
  final String? phone;
  final String? profileImage;
  final String? userType;
  final PersonalInformation? personalInformation;
  final AddressDetails? addressDetails;
  final ContactDetails? contactDetails;
  final KycStatus? kycStatus;
  final String? kycRejectionReason; // Add this
  final PlanType? currentPlan;
  final String? planName;
  final double? planAmount;
  final String? planValidity;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionExpiryDate;
  final int? daysRemaining;
  final String? paymentMethod;
  final String? cardNumber;
  final String? cardType;
  final List<String>? premiumBenefits;
  final List<SubscriptionHistory>? subscriptionHistory;
  final List<ResearchReport>? researchReports;
  final String? portfolioValue;
  final String? todayReturn;
  final String? totalInvestment;
  final String? panNumber;
  final String? aadharNumber;
  final String? registrationStatus;
  final String? registrationType;
  final String? registrationSource;
  final String? planSource;
  final String? userStatus;
  final String? suspensionReason;
  final bool? registrationFeePaid;
  final bool? adminAccessGranted;
  final DateTime? registrationExpiry;
  final Map<String, dynamic>? userObject; // Added getter
  final String? dateOfBirth; // Added DOB
  final String? kycErrorCode; // Added to store KRA errors without crashing
  final String? kycErrorMessage; // Added to store KRA errors without crashing
  final String? gstin;
  final String? firmName;

  User({
    required this.id,
    this.fullName,
    this.email,
    this.phone,
    this.profileImage,
    this.userType,
    this.personalInformation,
    this.addressDetails,
    this.contactDetails,
    this.kycStatus,
    this.kycRejectionReason,
    this.currentPlan,
    this.planName,
    this.planAmount,
    this.planValidity,
    this.subscriptionStartDate,
    this.subscriptionExpiryDate,
    this.daysRemaining,
    this.paymentMethod,
    this.cardNumber,
    this.cardType,
    this.premiumBenefits,
    this.subscriptionHistory,
    this.researchReports,
    this.portfolioValue,
    this.todayReturn,
    this.totalInvestment,
    this.panNumber,
    this.aadharNumber,
    this.registrationStatus,
    this.registrationType,
    this.registrationSource,
    this.planSource,
    this.userStatus,
    this.suspensionReason,
    this.registrationFeePaid,
    this.adminAccessGranted,
    this.registrationExpiry,
    this.userObject, 
    this.dateOfBirth, // Added to constructor
    this.kycErrorCode,
    this.kycErrorMessage,
    this.gstin,
    this.firmName,
  });

  String get name => fullName ?? personalInformation?.fullName ?? 'User';

  String get displayRegistrationType {
    if (registrationType == null) return 'Silver';
    final type = registrationType!.toUpperCase();
    if (type == 'LIFETIME') return 'Gold';
    if (type == 'ANNUAL') return 'Silver';
    return registrationType!;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final userObject = json['userObject'] as Map<String, dynamic>?;

    // NOTE: We don't throw exception here anymore to prevent login soft-lock.
    // Instead, we just store the error in the user object for the UI to handle.
    final kycErrorCode = userObject?['APP_ERROR_CODE']?.toString();
    final kycErrorMessage = userObject?['APP_ERROR_DESC']?.toString();

    return User(
      id: json['_id'] ?? json['id'] ?? '',
      fullName:
          json['fullName'] as String? ?? userObject?['APP_NAME'] as String?,
      email: json['email'] as String? ?? userObject?['APP_EMAIL'] as String?,
      phone: json['phone']?.toString() ?? userObject?['APP_MOB_NO']?.toString(),
      profileImage: json['profileImage'] as String?,
      userType: json['userType'] as String?,
      personalInformation: json['personalInformation'] != null
          ? PersonalInformation.fromJson(json['personalInformation'])
          : null,
      addressDetails: json['addressDetails'] != null
          ? AddressDetails.fromJson(json['addressDetails'])
          : null,
      contactDetails: json['contactDetails'] != null
          ? ContactDetails.fromJson(json['contactDetails'])
          : null,
      kycStatus: _parseKycStatus(json['kycStatus'] ?? 'notStarted'),
      kycRejectionReason: json['kycRejectionReason'] as String?,
      currentPlan: _parsePlanType(json['currentPlan']),
      panNumber:
          json['panNumber']?.toString() ??
          userObject?['APP_PAN_NO']?.toString() ??
          userObject?['pan']?.toString(),
      aadharNumber:
          json['aadhaarNumber']?.toString() ??
          userObject?['aadhaarNumber']?.toString(),
      registrationStatus: json['registrationStatus'] as String?,
      registrationType: json['registrationType'] as String?,
      registrationSource: json['registrationSource'] as String?,
      planSource: json['planSource'] as String?,
      userStatus: json['userStatus'] as String?,
      suspensionReason: json['suspensionReason'] as String?,
      registrationFeePaid: json['registrationFeePaid'] as bool?,
      adminAccessGranted: json['adminAccessGranted'] as bool?,
      registrationExpiry: json['registrationExpiry'] != null ? DateTime.tryParse(json['registrationExpiry'].toString()) : null,
      userObject: userObject, 
      dateOfBirth: json['dateOfBirth']?.toString(), // Added mapping
      kycErrorCode: kycErrorCode,
      kycErrorMessage: kycErrorMessage,
      gstin: json['gstin']?.toString(),
      firmName: json['firmName']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'profileImage': profileImage,
      'userType': userType,
      'personalInformation': personalInformation?.toJson(),
      'addressDetails': addressDetails?.toJson(),
      'contactDetails': contactDetails?.toJson(),
      'userObject': userObject,
      'dateOfBirth': dateOfBirth,
      'gstin': gstin,
      'firmName': firmName,
    };
  }

  static KycStatus? _parseKycStatus(dynamic status) {
    if (status == null) return KycStatus.notStarted;
    final statusStr = status.toString().toLowerCase();
    
    // Exact Matches First (Priority)
    if (statusStr == 'in_progress') return KycStatus.inProgress;
    if (statusStr == 'waiting_for_review') return KycStatus.waitingForReview;
    
    // Fuzzy Matches (Legacy Compatibility)
    if (statusStr.contains('verified') || statusStr.contains('approved')) return KycStatus.verified;
    if (statusStr.contains('pending')) return KycStatus.waitingForReview; // Map PENDING to Waiting
    if (statusStr.contains('rejected')) return KycStatus.rejected;
    
    return KycStatus.notStarted;
  }

  static PlanType? _parsePlanType(dynamic plan) {
    if (plan == null) return null;
    final planStr = plan.toString().toLowerCase();
    if (planStr.contains('premium')) return PlanType.premium;
    if (planStr.contains('enterprise')) return PlanType.enterprise;
    return PlanType.basic;
  }

  User copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? profileImage,
    String? userType,
    PersonalInformation? personalInformation,
    AddressDetails? addressDetails,
    ContactDetails? contactDetails,
    KycStatus? kycStatus,
    String? kycRejectionReason,
    PlanType? currentPlan,
    String? planName,
    double? planAmount,
    String? planValidity,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionExpiryDate,
    int? daysRemaining,
    String? paymentMethod,
    String? cardNumber,
    String? cardType,
    List<String>? premiumBenefits,
    List<SubscriptionHistory>? subscriptionHistory,
    List<ResearchReport>? researchReports,
    String? portfolioValue,
    String? todayReturn,
    String? totalInvestment,
    String? panNumber,
    String? aadharNumber,
    String? registrationStatus,
    String? registrationType,
    String? registrationSource,
    String? planSource,
    String? userStatus,
    String? suspensionReason,
    bool? registrationFeePaid,
    bool? adminAccessGranted,
    DateTime? registrationExpiry,
    Map<String, dynamic>? userObject,
    String? dateOfBirth,
    String? kycErrorCode,
    String? kycErrorMessage,
    String? gstin,
    String? firmName,
  }) {
    return User(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      userType: userType ?? this.userType,
      personalInformation: personalInformation ?? this.personalInformation,
      addressDetails: addressDetails ?? this.addressDetails,
      contactDetails: contactDetails ?? this.contactDetails,
      kycStatus: kycStatus ?? this.kycStatus,
      kycRejectionReason: kycRejectionReason ?? this.kycRejectionReason,
      currentPlan: currentPlan ?? this.currentPlan,
      planName: planName ?? this.planName,
      planAmount: planAmount ?? this.planAmount,
      planValidity: planValidity ?? this.planValidity,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionExpiryDate: subscriptionExpiryDate ?? this.subscriptionExpiryDate,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      cardNumber: cardNumber ?? this.cardNumber,
      cardType: cardType ?? this.cardType,
      premiumBenefits: premiumBenefits ?? this.premiumBenefits,
      subscriptionHistory: subscriptionHistory ?? this.subscriptionHistory,
      researchReports: researchReports ?? this.researchReports,
      portfolioValue: portfolioValue ?? this.portfolioValue,
      todayReturn: todayReturn ?? this.todayReturn,
      totalInvestment: totalInvestment ?? this.totalInvestment,
      panNumber: panNumber ?? this.panNumber,
      aadharNumber: aadharNumber ?? this.aadharNumber,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      registrationType: registrationType ?? this.registrationType,
      registrationSource: registrationSource ?? this.registrationSource,
      planSource: planSource ?? this.planSource,
      userStatus: userStatus ?? this.userStatus,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      registrationFeePaid: registrationFeePaid ?? this.registrationFeePaid,
      adminAccessGranted: adminAccessGranted ?? this.adminAccessGranted,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      userObject: userObject ?? this.userObject,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      kycErrorCode: kycErrorCode ?? this.kycErrorCode,
      kycErrorMessage: kycErrorMessage ?? this.kycErrorMessage,
      gstin: gstin ?? this.gstin,
      firmName: firmName ?? this.firmName,
    );
  }
}

class PersonalInformation {
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? fatherName;

  PersonalInformation({
    this.firstName,
    this.middleName,
    this.lastName,
    this.fatherName,
  });

  String get fullName {
    final parts = [
      firstName,
      middleName,
      lastName,
    ].where((e) => e != null && e.isNotEmpty);
    return parts.join(' ');
  }

  factory PersonalInformation.fromJson(Map<String, dynamic> json) {
    return PersonalInformation(
      firstName: json['firstName'] as String?,
      middleName:
          json['middiletName'] as String? ?? json['middleName'] as String?,
      lastName: json['lastName'] as String?,
      fatherName: json['fatherName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'middiletName': middleName,
      'lastName': lastName,
      'fatherName': fatherName,
    };
  }
}

class AddressDetails {
  final String? houseNo;
  final String? streetAddress;
  final String? area;
  final String? landmark;
  final dynamic pincode;
  final String? state;

  AddressDetails({
    this.houseNo,
    this.streetAddress,
    this.area,
    this.landmark,
    this.pincode,
    this.state,
  });

  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails(
      houseNo: json['houseNo'] as String?,
      streetAddress:
          json['streetAdress'] as String? ?? json['streetAddress'] as String?,
      area: json['area'] as String?,
      landmark: json['landMark'] as String? ?? json['landmark'] as String?,
      pincode: json['pincode'],
      state: json['state'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'houseNo': houseNo,
      'streetAdress': streetAddress,
      'area': area,
      'landMark': landmark,
      'pincode': pincode,
      'state': state,
    };
  }
}

class ContactDetails {
  final String? email;
  final dynamic phone;

  ContactDetails({this.email, this.phone});

  factory ContactDetails.fromJson(Map<String, dynamic> json) {
    return ContactDetails(
      email: json['email'] as String?,
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'email': email, 'phone': phone};
  }
}
