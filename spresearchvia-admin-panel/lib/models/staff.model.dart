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

class EducationEntryModel {
  String standard; // "10th", "12th", "Graduation", "Post graduation", "Any other"
  String degree;
  String schoolCollege;
  String boardUniversity;
  String courseType; // "Regular" or "Part time"
  String passingYear;
  String attempts;
  String percentage;

  EducationEntryModel({
    this.standard = '',
    this.degree = '',
    this.schoolCollege = '',
    this.boardUniversity = '',
    this.courseType = 'Regular',
    this.passingYear = '',
    this.attempts = '1',
    this.percentage = '',
  });

  factory EducationEntryModel.fromJson(Map<String, dynamic> json) {
    return EducationEntryModel(
      standard: (json['standard'] ?? '').toString(),
      degree: (json['degree'] ?? '').toString(),
      schoolCollege: (json['schoolCollege'] ?? '').toString(),
      boardUniversity: (json['boardUniversity'] ?? '').toString(),
      courseType: (json['courseType'] ?? 'Regular').toString(),
      passingYear: (json['passingYear'] ?? '').toString(),
      attempts: (json['attempts'] ?? '1').toString(),
      percentage: (json['percentage'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'standard': standard,
      'degree': degree,
      'schoolCollege': schoolCollege,
      'boardUniversity': boardUniversity,
      'courseType': courseType,
      'passingYear': passingYear,
      'attempts': attempts,
      'percentage': percentage,
    };
  }
}

class EmploymentEntryModel {
  String fromPeriod;
  String toPeriod;
  String organisation;
  String designation;
  String reasonForLeaving;

  EmploymentEntryModel({
    this.fromPeriod = '',
    this.toPeriod = '',
    this.organisation = '',
    this.designation = '',
    this.reasonForLeaving = '',
  });

  factory EmploymentEntryModel.fromJson(Map<String, dynamic> json) {
    return EmploymentEntryModel(
      fromPeriod: (json['fromPeriod'] ?? '').toString(),
      toPeriod: (json['toPeriod'] ?? '').toString(),
      organisation: (json['organisation'] ?? '').toString(),
      designation: (json['designation'] ?? '').toString(),
      reasonForLeaving: (json['reasonForLeaving'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromPeriod': fromPeriod,
      'toPeriod': toPeriod,
      'organisation': organisation,
      'designation': designation,
      'reasonForLeaving': reasonForLeaving,
    };
  }
}

class WalkInFormModel {
  // Header / Basic
  String appliedPosition;
  String applicationDate;
  String? passportPhoto;

  // Personal
  String fullName;
  String dob;
  String nativePlace;
  String gender;
  String maritalStatus;
  String mobileNumber;
  String currentLocation;
  String emailAddress;
  String skypeAddress;

  // Declarations
  bool interviewedBefore;
  String interviewedBeforeDetails;
  bool smoke;
  bool alcohol;
  bool differentlyAbled;
  String differentlyAbledDetails;
  bool policeRecord;
  String policeRecordDetails;
  bool majorIllness;
  String majorIllnessDetails;
  String source;
  String sourceDetails;

  // Education
  List<EducationEntryModel> educationList;
  bool academicGap;
  String academicGapDetails;
  String backlogsCount;

  // Work Experience & Compensation
  String currentOrganisation;
  String currentDesignation;
  String reportingManagerDesignation;
  String reportingManagerName;
  String reporteesCount;
  String totalExperience;
  String fixedSalary;
  String bonusIncentive;
  String totalSalary;
  String expectedSalary;
  String noticePeriod;

  // Employment History
  List<EmploymentEntryModel> employmentList;
  String careerGap;

  // Remarks
  String? recruiterRemarks;
  String? interviewerRemarks;

  WalkInFormModel({
    this.appliedPosition = '',
    this.applicationDate = '',
    this.passportPhoto,
    this.fullName = '',
    this.dob = '',
    this.nativePlace = '',
    this.gender = '',
    this.maritalStatus = '',
    this.mobileNumber = '',
    this.currentLocation = '',
    this.emailAddress = '',
    this.skypeAddress = '',
    this.interviewedBefore = false,
    this.interviewedBeforeDetails = '',
    this.smoke = false,
    this.alcohol = false,
    this.differentlyAbled = false,
    this.differentlyAbledDetails = '',
    this.policeRecord = false,
    this.policeRecordDetails = '',
    this.majorIllness = false,
    this.majorIllnessDetails = '',
    this.source = '',
    this.sourceDetails = '',
    List<EducationEntryModel>? educationList,
    this.academicGap = false,
    this.academicGapDetails = '',
    this.backlogsCount = '',
    this.currentOrganisation = '',
    this.currentDesignation = '',
    this.reportingManagerDesignation = '',
    this.reportingManagerName = '',
    this.reporteesCount = '',
    this.totalExperience = '',
    this.fixedSalary = '',
    this.bonusIncentive = '',
    this.totalSalary = '',
    this.expectedSalary = '',
    this.noticePeriod = '',
    List<EmploymentEntryModel>? employmentList,
    this.careerGap = '',
    this.recruiterRemarks,
    this.interviewerRemarks,
  })  : educationList = educationList ?? [],
        employmentList = employmentList ?? [];

  factory WalkInFormModel.fromJson(Map<String, dynamic> json) {
    var eduList = <EducationEntryModel>[];
    if (json['educationList'] != null && json['educationList'] is List) {
      eduList = (json['educationList'] as List)
          .whereType<Map>()
          .map((e) => EducationEntryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    var empList = <EmploymentEntryModel>[];
    if (json['employmentList'] != null && json['employmentList'] is List) {
      empList = (json['employmentList'] as List)
          .whereType<Map>()
          .map((e) => EmploymentEntryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return WalkInFormModel(
      appliedPosition: (json['appliedPosition'] ?? '').toString(),
      applicationDate: (json['applicationDate'] ?? '').toString(),
      passportPhoto: json['passportPhoto']?.toString(),
      fullName: (json['fullName'] ?? '').toString(),
      dob: (json['dob'] ?? '').toString(),
      nativePlace: (json['nativePlace'] ?? '').toString(),
      gender: (json['gender'] ?? '').toString(),
      maritalStatus: (json['maritalStatus'] ?? '').toString(),
      mobileNumber: (json['mobileNumber'] ?? '').toString(),
      currentLocation: (json['currentLocation'] ?? '').toString(),
      emailAddress: (json['emailAddress'] ?? '').toString(),
      skypeAddress: (json['skypeAddress'] ?? '').toString(),
      interviewedBefore: json['interviewedBefore'] == true || json['interviewedBefore'] == 'true',
      interviewedBeforeDetails: (json['interviewedBeforeDetails'] ?? '').toString(),
      smoke: json['smoke'] == true || json['smoke'] == 'true',
      alcohol: json['alcohol'] == true || json['alcohol'] == 'true',
      differentlyAbled: json['differentlyAbled'] == true || json['differentlyAbled'] == 'true',
      differentlyAbledDetails: (json['differentlyAbledDetails'] ?? '').toString(),
      policeRecord: json['policeRecord'] == true || json['policeRecord'] == 'true',
      policeRecordDetails: (json['policeRecordDetails'] ?? '').toString(),
      majorIllness: json['majorIllness'] == true || json['majorIllness'] == 'true',
      majorIllnessDetails: (json['majorIllnessDetails'] ?? '').toString(),
      source: (json['source'] ?? '').toString(),
      sourceDetails: (json['sourceDetails'] ?? '').toString(),
      educationList: eduList,
      academicGap: json['academicGap'] == true || json['academicGap'] == 'true',
      academicGapDetails: (json['academicGapDetails'] ?? '').toString(),
      backlogsCount: (json['backlogsCount'] ?? '').toString(),
      currentOrganisation: (json['currentOrganisation'] ?? '').toString(),
      currentDesignation: (json['currentDesignation'] ?? '').toString(),
      reportingManagerDesignation: (json['reportingManagerDesignation'] ?? '').toString(),
      reportingManagerName: (json['reportingManagerName'] ?? '').toString(),
      reporteesCount: (json['reporteesCount'] ?? '').toString(),
      totalExperience: (json['totalExperience'] ?? '').toString(),
      fixedSalary: (json['fixedSalary'] ?? '').toString(),
      bonusIncentive: (json['bonusIncentive'] ?? '').toString(),
      totalSalary: (json['totalSalary'] ?? '').toString(),
      expectedSalary: (json['expectedSalary'] ?? '').toString(),
      noticePeriod: (json['noticePeriod'] ?? '').toString(),
      employmentList: empList,
      careerGap: (json['careerGap'] ?? '').toString(),
      recruiterRemarks: json['recruiterRemarks']?.toString(),
      interviewerRemarks: json['interviewerRemarks']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appliedPosition': appliedPosition,
      'applicationDate': applicationDate,
      if (passportPhoto != null) 'passportPhoto': passportPhoto,
      'fullName': fullName,
      'dob': dob,
      'nativePlace': nativePlace,
      'gender': gender,
      'maritalStatus': maritalStatus,
      'mobileNumber': mobileNumber,
      'currentLocation': currentLocation,
      'emailAddress': emailAddress,
      'skypeAddress': skypeAddress,
      'interviewedBefore': interviewedBefore,
      'interviewedBeforeDetails': interviewedBeforeDetails,
      'smoke': smoke,
      'alcohol': alcohol,
      'differentlyAbled': differentlyAbled,
      'differentlyAbledDetails': differentlyAbledDetails,
      'policeRecord': policeRecord,
      'policeRecordDetails': policeRecordDetails,
      'majorIllness': majorIllness,
      'majorIllnessDetails': majorIllnessDetails,
      'source': source,
      'sourceDetails': sourceDetails,
      'educationList': educationList.map((e) => e.toJson()).toList(),
      'academicGap': academicGap,
      'academicGapDetails': academicGapDetails,
      'backlogsCount': backlogsCount,
      'currentOrganisation': currentOrganisation,
      'currentDesignation': currentDesignation,
      'reportingManagerDesignation': reportingManagerDesignation,
      'reportingManagerName': reportingManagerName,
      'reporteesCount': reporteesCount,
      'totalExperience': totalExperience,
      'fixedSalary': fixedSalary,
      'bonusIncentive': bonusIncentive,
      'totalSalary': totalSalary,
      'expectedSalary': expectedSalary,
      'noticePeriod': noticePeriod,
      'employmentList': employmentList.map((e) => e.toJson()).toList(),
      'careerGap': careerGap,
      if (recruiterRemarks != null) 'recruiterRemarks': recruiterRemarks,
      if (interviewerRemarks != null) 'interviewerRemarks': interviewerRemarks,
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
  final String? roleId;
  final String status;
  final String department;
  final String? departmentId;
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
  final WalkInFormModel? walkInForm;
  final Map<String, dynamic>? rawJson;

  StaffModel({
    required this.id,
    required this.staffId,
    required this.name,
    required this.mobile,
    required this.email,
    required this.role,
    this.roleId,
    required this.status,
    required this.department,
    this.departmentId,
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
    this.walkInForm,
    this.rawJson,
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

    String? deptName;
    if (json['departmentId'] is Map) {
      deptName = _safeString(json['departmentId']['name']);
    }

    final resolvedRole = roleName ?? _safeString(json['role'] ?? json['designation'] ?? json['position'] ?? json['deparment'] ?? json['department']) ?? 'Staff';

    return StaffModel(
      id: _safeString(json['_id'] ?? json['id']) ?? '',
      staffId: _safeString(json['staffId']) ?? '',
      name: _safeString(json['fullName'] ?? json['name']) ?? '',
      mobile: _safeString(json['mobileNumber'] ?? json['mobile']) ?? '',
      email: _safeString(json['emailAddress'] ?? json['email']) ?? '',
      role: resolvedRole,
      roleId: roleId,
      status: _safeString(json['status']) ?? 'Active',
      department: deptName ?? _safeString(json['deparment'] ?? json['department'] ?? json['team']) ?? '',
      departmentId: json['departmentId'] is Map
          ? _safeString(json['departmentId']['_id'])
          : _safeString(json['departmentId']),
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
      walkInForm: walkIn,
      rawJson: json,
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
      if (roleId != null) 'roleId': roleId,
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
      if (walkInForm != null) 'walkInForm': walkInForm!.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
