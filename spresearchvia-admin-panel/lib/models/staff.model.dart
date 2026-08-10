class EmergencyContactModel {
  final String name;
  final String relation;
  final String phone;

  EmergencyContactModel({
    required this.name,
    required this.relation,
    required this.phone,
  });

  factory EmergencyContactModel.fromJson(Map<String, dynamic> json) {
    return EmergencyContactModel(
      name: (json['name'] ?? '').toString(),
      relation: (json['relation'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'relation': relation,
      'phone': phone,
    };
  }
}

class StaffModel {
  final String id;
  final String staffId;
  final String name;
  final String mobile;
  final String email;
  final String role;
  final String status;
  final String department;
  final DateTime? joiningDate;
  final String? remark;
  final String? assignedDirector;
  final String? assignedDirectorName;
  final String? mpin;
  final bool isViewOnly;
  final String? panUrl;
  final String? aadhaarUrl;
  final String? nismUrl;
  final String? highestEducationUrl;
  final String? kycVideoUrl;
  final String onboardingStatus;
  final bool isEmailVerified;
  final bool isMobileVerified;
  final String? photoUrl;
  final String? resumeUrl;
  final String stage;
  final String? dob;
  final String? gender;
  final int? experienceYears;
  final String? previousCompany;
  final String? lastCtc;
  final String? localAddress;
  final String? permanentAddress;
  final EmergencyContactModel? emergencyContact;

  StaffModel({
    required this.id,
    required this.staffId,
    required this.name,
    required this.mobile,
    required this.email,
    required this.role,
    required this.status,
    required this.department,
    this.joiningDate,
    this.remark,
    this.assignedDirector,
    this.assignedDirectorName,
    this.mpin,
    this.isViewOnly = false,
    this.panUrl,
    this.aadhaarUrl,
    this.nismUrl,
    this.highestEducationUrl,
    this.kycVideoUrl,
    this.onboardingStatus = 'PENDING',
    this.isEmailVerified = false,
    this.isMobileVerified = false,
    this.photoUrl,
    this.resumeUrl,
    this.stage = 'Applicant',
    this.dob,
    this.gender,
    this.experienceYears,
    this.previousCompany,
    this.lastCtc,
    this.localAddress,
    this.permanentAddress,
    this.emergencyContact,
  });

  String get fullName => name;

  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? value['name'] ?? value['fullName'] ?? value.toString()).toString();
    }
    return value.toString();
  }

  factory StaffModel.fromJson(Map<String, dynamic> json) {
    // Safe extraction of EmergencyContact
    EmergencyContactModel? contact;
    if (json['emergencyContact'] != null && json['emergencyContact'] is Map) {
      try {
        contact = EmergencyContactModel.fromJson(json['emergencyContact'] as Map<String, dynamic>);
      } catch (_) {}
    }

    return StaffModel(
      id: _safeString(json['_id'] ?? json['id']) ?? '',
      staffId: _safeString(json['staffId']) ?? '',
      name: _safeString(json['fullName'] ?? json['name']) ?? '',
      mobile: _safeString(json['mobileNumber'] ?? json['mobile']) ?? '',
      email: _safeString(json['emailAddress'] ?? json['email']) ?? '',
      role: _safeString(json['role'] ?? json['designation'] ?? json['position']) ?? 'Staff',
      status: _safeString(json['status']) ?? 'Active',
      department: _safeString(json['deparment'] ?? json['department'] ?? json['team']) ?? '',
      joiningDate: json['joiningDate'] != null
          ? DateTime.tryParse(json['joiningDate'].toString())
          : null,
      remark: _safeString(json['remark']),
      assignedDirector: _safeString(json['assignedDirector']),
      assignedDirectorName: json['assignedDirectorName'] ?? (json['assignedDirector'] is Map ? _safeString(json['assignedDirector']['fullName'] ?? json['assignedDirector']['name']) : null),
      mpin: _safeString(json['mpin']),
      isViewOnly: json['isViewOnly'] ?? false,
      panUrl: _safeString(json['panUrl']),
      aadhaarUrl: _safeString(json['aadhaarUrl']),
      nismUrl: _safeString(json['nismUrl']),
      highestEducationUrl: _safeString(json['highestEducationUrl']),
      kycVideoUrl: _safeString(json['kycVideoUrl']),
      onboardingStatus: _safeString(json['onboardingStatus']) ?? 'PENDING',
      isEmailVerified: json['isEmailVerified'] ?? false,
      isMobileVerified: json['isMobileVerified'] ?? false,
      photoUrl: _safeString(json['photoUrl']),
      resumeUrl: _safeString(json['resumeUrl']),
      stage: _safeString(json['stage']) ?? 'Applicant',
      dob: _safeString(json['dob']),
      gender: _safeString(json['gender']),
      experienceYears: json['experienceYears'] != null
          ? int.tryParse(json['experienceYears'].toString())
          : null,
      previousCompany: _safeString(json['previousCompany']),
      lastCtc: _safeString(json['lastCtc']),
      localAddress: _safeString(json['localAddress']),
      permanentAddress: _safeString(json['permanentAddress']),
      emergencyContact: contact,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'staffId': staffId,
      'name': name,
      'mobile': mobile,
      'email': email,
      'role': role,
      'status': status,
      'department': department,
      'joiningDate': joiningDate?.toIso8601String(),
      'remark': remark,
      'assignedDirector': assignedDirector,
      'assignedDirectorName': assignedDirectorName,
      'mpin': mpin,
      'isViewOnly': isViewOnly,
      'panUrl': panUrl,
      'aadhaarUrl': aadhaarUrl,
      'nismUrl': nismUrl,
      'highestEducationUrl': highestEducationUrl,
      'kycVideoUrl': kycVideoUrl,
      'onboardingStatus': onboardingStatus,
      'isEmailVerified': isEmailVerified,
      'isMobileVerified': isMobileVerified,
      'photoUrl': photoUrl,
      'resumeUrl': resumeUrl,
      'stage': stage,
      'dob': dob,
      'gender': gender,
      'experienceYears': experienceYears,
      'previousCompany': previousCompany,
      'lastCtc': lastCtc,
      'localAddress': localAddress,
      'permanentAddress': permanentAddress,
      'emergencyContact': emergencyContact?.toJson(),
    };
  }
}
