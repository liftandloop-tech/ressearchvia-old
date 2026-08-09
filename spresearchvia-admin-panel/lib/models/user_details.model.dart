class UserDetailsModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String status;
  final String createdAt;
  final String updatedAt;
  final String? aadhaarNumber;
  final String userType;
  final String? kycStatus;
  final String? mPin;
  final String? kycVideo;
  final KycDocs? kycDocs;
  final UserObject? userObject;

  UserDetailsModel({
    required this.id,
    required this.fullName,
    required this.email, // Required
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.aadhaarNumber,
    required this.userType,
    this.mPin,
    this.userObject,
    this.kycStatus,
    this.kycVideo,
    this.kycDocs,
    this.registrationStatus,
    this.registrationType,
    this.registrationExpiry,
    this.registrationFeePaid,
    this.adminAccessGranted,
    this.profileImage,
    this.digioDocumentId,
    this.kycDocStatus,
    this.kycEsignStatus,
    this.kycVideoStatus,
    this.kycDocRejectionReason,
    this.kycEsignRejectionReason,
    this.kycVideoRejectionReason,
    this.gstin,
    this.firmName,
  });

  factory UserDetailsModel.fromJson(Map<String, dynamic> json) {
    return UserDetailsModel(
      id: json['_id'] ?? '',
      fullName:
          json['fullName'] ??
          json['username'] ??
          (json['userObject'] != null
              ? json['userObject']['APP_NAME']
              : 'Not Found'),
      email:
          json['email'] ??
          (json['userObject'] != null
              ? json['userObject']['APP_EMAIL']
              : 'Not Found'),
      phone:
          json['phone']?.toString() ??
          (json['userObject'] != null
              ? (json['userObject']['APP_MOB_NO']?.toString() ?? 'Not Found')
              : 'Not Found'),
      status: json['userStatus'] ?? json['status'] ?? 'Not Found',
      createdAt: json['createdAt'] ?? '',
      updatedAt: json['updatedAt'] ?? '',
      aadhaarNumber: json['aadhaarNumber']
          ?.toString(), // Handle both String and Number
      userType: json['userType'] ?? 'user',
      mPin: json['mPin']?.toString(),
      kycStatus: json['kycStatus'],
      kycVideo: json['kycVideo'],
      // Add registration fields
      registrationStatus: json['registrationStatus'] ?? 'PENDING',
      registrationType: json['registrationType'] ?? 'N/A',
      registrationExpiry: json['registrationExpiry'],
      registrationFeePaid: json['registrationFeePaid'] ?? false,
      adminAccessGranted: json['adminAccessGranted'] ?? false,

      kycDocs: json['kycDocs'] != null
          ? KycDocs.fromJson(json['kycDocs'])
          : null,
      userObject: json['userObject'] != null
          ? UserObject.fromJson(json['userObject'])
          : null,
      profileImage: json['profileImage'],
      digioDocumentId:
          json['userkycs'] != null && json['userkycs']['digioObject'] != null
          ? json['userkycs']['digioObject']['id']
          : null,
      kycDocStatus: json['kycGates']?['documents']?['status'],
      kycEsignStatus: json['kycGates']?['esign']?['status'],
      kycVideoStatus: json['kycGates']?['video']?['status'],
      kycDocRejectionReason: json['kycGates']?['documents']?['rejectionReason'],
      kycEsignRejectionReason: json['kycGates']?['esign']?['rejectionReason'],
      kycVideoRejectionReason: json['kycGates']?['video']?['rejectionReason'],
      gstin: json['gstin'],
      firmName: json['firmName'],
    );
  }

  final String? digioDocumentId;

  // 3-Gate Fields
  final String? kycDocStatus;
  final String? kycEsignStatus;
  final String? kycVideoStatus;
  final String? kycDocRejectionReason;
  final String? kycEsignRejectionReason;
  final String? kycVideoRejectionReason;

  // Add fields to class definition
  final String? profileImage;

  // Add fields to class definition
  final String? registrationStatus;
  final String? registrationType;
  final String? registrationExpiry;
  final bool? registrationFeePaid;
  final bool? adminAccessGranted;
  final String? gstin;
  final String? firmName;

  String get formattedPhone {
    if (phone == 'Not Found' || phone.isEmpty) return 'Not Found';
    // Format: +91 98765 43210
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length >= 10) {
      // Take last 10 digits
      String last10 = cleanPhone.substring(cleanPhone.length - 10);
      return '+91 ${last10.substring(0, 5)} ${last10.substring(5)}';
    }
    return phone;
  }

  String get gender {
    if (userObject?.appGen == null || userObject!.appGen.isEmpty) {
      return 'Not Found';
    }
    return userObject!.appGen == 'M'
        ? 'Male'
        : userObject!.appGen == 'F'
        ? 'Female'
        : 'Other';
  }

  String get displayName {
    if (fullName != 'Not Found' && fullName.isNotEmpty) {
      return fullName;
    }
    if (userObject?.appName != null && userObject!.appName.isNotEmpty) {
      return userObject!.appName;
    }
    return fullName;
  }

  String get residentialAddress {
    // Check local address fields first if available (not defined in model yet, assuming userObject for now)
    // If we wanted to prioritize local address we would need to add fields to UserDetailsModel
    if (userObject == null) return 'Not Found';
    List<String> addressParts = [
      userObject!.appCorAdd1,
      userObject!.appCorAdd2,
      userObject!.appCorAdd3,
      userObject!.appCorCity,
    ].where((part) => part.isNotEmpty).cast<String>().toList();

    if (addressParts.isEmpty) return 'Not Found';
    return addressParts.join(', ');
  }

  String get effectiveKycStatus {
    final status = kycStatus ?? 'PENDING';
    if (status.toUpperCase() == 'WAITING_FOR_REVIEW') {
      // Check if ANY actual content-heavy doc exists
      bool hasDocs =
          (kycDocs?.panImage != null && kycDocs!.panImage!.isNotEmpty) ||
          (kycDocs?.aadhaarFront != null && kycDocs!.aadhaarFront!.isNotEmpty) ||
          (kycDocs?.aadhaarBack != null && kycDocs!.aadhaarBack!.isNotEmpty) ||
          (kycDocs?.video != null && kycDocs!.video!.isNotEmpty) ||
          (kycVideo != null && kycVideo!.isNotEmpty) ||
          (digioDocumentId != null && digioDocumentId!.isNotEmpty);

      if (!hasDocs) return 'PENDING';
    }
    return status;
  }
}

class UserObject {
  final String appName;
  final String appFName;
  final String appDobDt;
  final String appGen;
  final String appPanNo;
  final String appMobNo;
  final String appEmail;
  final String appCorAdd1;
  final String appCorAdd2;
  final String appCorAdd3;
  final String appCorCity;
  final String appCorPincd;
  final String appCorState;
  final String appPerAdd1;
  final String appPerAdd2;
  final String appPerAdd3;
  final String appPerCity;
  final String appPerPincd;
  final String appPerState;

  UserObject({
    required this.appName,
    required this.appFName,
    required this.appDobDt,
    required this.appGen,
    required this.appPanNo,
    required this.appMobNo,
    required this.appEmail,
    required this.appCorAdd1,
    required this.appCorAdd2,
    required this.appCorAdd3,
    required this.appCorCity,
    required this.appCorPincd,
    required this.appCorState,
    required this.appPerAdd1,
    required this.appPerAdd2,
    required this.appPerAdd3,
    required this.appPerCity,
    required this.appPerPincd,
    required this.appPerState,
  });

  factory UserObject.fromJson(Map<String, dynamic> json) {
    return UserObject(
      appName: json['APP_NAME'] ?? '',
      appFName: json['APP_F_NAME'] ?? '',
      appDobDt: json['APP_DOB_DT'] ?? '',
      appGen: json['APP_GEN'] ?? '',
      appPanNo: json['APP_PAN_NO'] ?? '',
      appMobNo: json['APP_MOB_NO'] ?? '',
      appEmail: json['APP_EMAIL'] ?? '',
      appCorAdd1: json['APP_COR_ADD1'] ?? '',
      appCorAdd2: json['APP_COR_ADD2'] ?? '',
      appCorAdd3: json['APP_COR_ADD3'] ?? '',
      appCorCity: json['APP_COR_CITY'] ?? '',
      appCorPincd: json['APP_COR_PINCD'] ?? '',
      appCorState: json['APP_COR_STATE'] ?? '',
      appPerAdd1: json['APP_PER_ADD1'] ?? '',
      appPerAdd2: json['APP_PER_ADD2'] ?? '',
      appPerAdd3: json['APP_PER_ADD3'] ?? '',
      appPerCity: json['APP_PER_CITY'] ?? '',
      appPerPincd: json['APP_PER_PINCD'] ?? '',
      appPerState: json['APP_PER_STATE'] ?? '',
    );
  }
}

class KycDocs {
  final String? panImage;
  final String? aadhaarFront;
  final String? aadhaarBack;
  final String? video;

  KycDocs({this.panImage, this.aadhaarFront, this.aadhaarBack, this.video});

  factory KycDocs.fromJson(Map<String, dynamic> json) {
    return KycDocs(
      panImage: json['panImage'],
      aadhaarFront: json['aadhaarFront'],
      aadhaarBack: json['aadhaarBack'],
      video: json['video'],
    );
  }
}
