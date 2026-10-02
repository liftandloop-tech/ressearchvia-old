import 'staff.model.dart';

class ApplicantStageHistory {
  final String stage;
  final String? changedBy;
  final DateTime? changedAt;
  final String? reason;

  ApplicantStageHistory({
    required this.stage,
    this.changedBy,
    this.changedAt,
    this.reason,
  });

  factory ApplicantStageHistory.fromJson(Map<String, dynamic> json) {
    return ApplicantStageHistory(
      stage: (json['stage'] ?? '').toString(),
      changedBy: json['changedBy']?.toString(),
      changedAt: json['changedAt'] != null ? DateTime.tryParse(json['changedAt'].toString()) : null,
      reason: json['reason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stage': stage,
      if (changedBy != null) 'changedBy': changedBy,
      if (changedAt != null) 'changedAt': changedAt!.toIso8601String(),
      if (reason != null) 'reason': reason,
    };
  }
}

class ApplicantModel {
  final String id;
  final String applicantId;
  final String fullName;
  final String emailAddress;
  final String mobileNumber;
  final String role;
  final String? roleId;
  final String department;
  final String stage;
  final List<ApplicantStageHistory> stageHistory;
  final String? rejectionReason;
  final String? convertedToStaffId;
  final DateTime? convertedAt;
  final bool isEmailVerified;
  final bool isMobileVerified;
  final String onboardingStatus;
  final WalkInFormModel? walkInForm;
  final String? panUrl;
  final String? aadhaarUrl;
  final String? nismUrl;
  final String? highestEducationUrl;
  final String? kycVideoUrl;
  final String? photoUrl;
  final String? resumeUrl;
  final String? dob;
  final String? gender;
  final int? experienceYears;
  final String? previousCompany;
  final String? lastCtc;
  final String? localAddress;
  final String? permanentAddress;
  final EmergencyContactModel? emergencyContact;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? rawJson;

  ApplicantModel({
    required this.id,
    required this.applicantId,
    required this.fullName,
    required this.emailAddress,
    required this.mobileNumber,
    required this.role,
    this.roleId,
    required this.department,
    this.stage = 'APPLIED',
    this.stageHistory = const [],
    this.rejectionReason,
    this.convertedToStaffId,
    this.convertedAt,
    this.isEmailVerified = false,
    this.isMobileVerified = false,
    this.onboardingStatus = 'PENDING',
    this.walkInForm,
    this.panUrl,
    this.aadhaarUrl,
    this.nismUrl,
    this.highestEducationUrl,
    this.kycVideoUrl,
    this.photoUrl,
    this.resumeUrl,
    this.dob,
    this.gender,
    this.experienceYears,
    this.previousCompany,
    this.lastCtc,
    this.localAddress,
    this.permanentAddress,
    this.emergencyContact,
    this.createdAt,
    this.updatedAt,
    this.rawJson,
  });

  String get name => fullName;
  String get email => emailAddress;
  String get mobile => mobileNumber;
  bool get isConverted => convertedToStaffId != null || stage == 'OFFER_ACCEPTED' || stage == 'Employee';

  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return (value['_id'] ?? value['id'] ?? value['name'] ?? value['fullName'] ?? value.toString()).toString();
    }
    return value.toString();
  }

  factory ApplicantModel.fromJson(Map<String, dynamic> json) {
    EmergencyContactModel? contact;
    if (json['emergencyContact'] != null && json['emergencyContact'] is Map) {
      try {
        contact = EmergencyContactModel.fromJson(Map<String, dynamic>.from(json['emergencyContact'] as Map));
      } catch (_) {}
    }

    WalkInFormModel? walkIn;
    if (json['walkInForm'] != null && json['walkInForm'] is Map) {
      try {
        walkIn = WalkInFormModel.fromJson(Map<String, dynamic>.from(json['walkInForm'] as Map));
      } catch (_) {}
    }

    String? roleId;
    String? roleName;
    if (json['roleId'] is Map) {
      roleId = _safeString(json['roleId']['_id'] ?? json['roleId']['id']);
      roleName = _safeString(json['roleId']['name']);
    } else if (json['roleId'] != null) {
      roleId = _safeString(json['roleId']);
    }

    final resolvedRole = roleName ?? _safeString(json['role'] ?? json['appliedPosition'] ?? json['designation'] ?? json['position']) ?? 'Applicant';

    var historyList = <ApplicantStageHistory>[];
    if (json['stageHistory'] != null && json['stageHistory'] is List) {
      try {
        historyList = (json['stageHistory'] as List)
            .whereType<Map>()
            .map((h) => ApplicantStageHistory.fromJson(Map<String, dynamic>.from(h)))
            .toList();
      } catch (_) {}
    }

    return ApplicantModel(
      id: _safeString(json['_id'] ?? json['id']) ?? '',
      applicantId: _safeString(json['applicantId'] ?? json['staffId']) ?? '',
      fullName: _safeString(json['fullName'] ?? json['name']) ?? '',
      emailAddress: _safeString(json['emailAddress'] ?? json['email']) ?? '',
      mobileNumber: _safeString(json['mobileNumber'] ?? json['mobile']) ?? '',
      role: resolvedRole,
      roleId: roleId,
      department: _safeString(json['deparment'] ?? json['department']) ?? '',
      stage: _safeString(json['stage']) ?? 'APPLIED',
      stageHistory: historyList,
      rejectionReason: _safeString(json['rejectionReason']),
      convertedToStaffId: _safeString(json['convertedToStaffId']),
      convertedAt: json['convertedAt'] != null ? DateTime.tryParse(json['convertedAt'].toString()) : null,
      isEmailVerified: json['isEmailVerified'] == true || json['isEmailVerified'] == 'true',
      isMobileVerified: json['isMobileVerified'] == true || json['isMobileVerified'] == 'true',
      onboardingStatus: _safeString(json['onboardingStatus']) ?? 'PENDING',
      walkInForm: walkIn,
      panUrl: _safeString(json['panUrl']),
      aadhaarUrl: _safeString(json['aadhaarUrl']),
      nismUrl: _safeString(json['nismUrl']),
      highestEducationUrl: _safeString(json['highestEducationUrl']),
      kycVideoUrl: _safeString(json['kycVideoUrl']),
      photoUrl: _safeString(json['photoUrl'] ?? json['walkInForm']?['passportPhoto']),
      resumeUrl: _safeString(json['resumeUrl']),
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
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'].toString()) : null,
      rawJson: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicantId': applicantId,
      'fullName': fullName,
      'emailAddress': emailAddress,
      'mobileNumber': mobileNumber,
      'role': role,
      if (roleId != null) 'roleId': roleId,
      'department': department,
      'stage': stage,
      'stageHistory': stageHistory.map((h) => h.toJson()).toList(),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (convertedToStaffId != null) 'convertedToStaffId': convertedToStaffId,
      if (convertedAt != null) 'convertedAt': convertedAt!.toIso8601String(),
      'isEmailVerified': isEmailVerified,
      'isMobileVerified': isMobileVerified,
      'onboardingStatus': onboardingStatus,
      'photoUrl': photoUrl,
      'resumeUrl': resumeUrl,
      'panUrl': panUrl,
      'aadhaarUrl': aadhaarUrl,
      'nismUrl': nismUrl,
      'highestEducationUrl': highestEducationUrl,
      'kycVideoUrl': kycVideoUrl,
      'dob': dob,
      'gender': gender,
      'experienceYears': experienceYears,
      'previousCompany': previousCompany,
      'lastCtc': lastCtc,
      'localAddress': localAddress,
      'permanentAddress': permanentAddress,
      'emergencyContact': emergencyContact?.toJson(),
      if (walkInForm != null) 'walkInForm': walkInForm!.toJson(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
