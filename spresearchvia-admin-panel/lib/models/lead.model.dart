class LeadModel {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String? emailAddress;
  final String? assignedRMId;
  final String? assignedRMName;
  final String stage;
  final String? city;
  final String? state;
  final String? education;
  final String? experience;
  final List<FollowUpModel> followUps;
  final String? leadPoolId;
  final String? leadPoolName;
  final String leadSource;
  final bool isAppUser;
  final String? appUserId;
  final DateTime? appOnboardedAt;
  final String? previousRMStaffId;
  final String? previousRMStaffName;
  final DateTime? previousRMTransferredAt;
  final String? previousRMTransferReason;
  final DateTime createdAt;

  LeadModel({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.emailAddress,
    this.assignedRMId,
    this.assignedRMName,
    required this.stage,
    this.city,
    this.state,
    this.education,
    this.experience,
    required this.followUps,
    this.leadPoolId,
    this.leadPoolName,
    this.leadSource = 'IMPORTED_POOL',
    this.isAppUser = false,
    this.appUserId,
    this.appOnboardedAt,
    this.previousRMStaffId,
    this.previousRMStaffName,
    this.previousRMTransferredAt,
    this.previousRMTransferReason,
    required this.createdAt,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    String? rmId;
    String? rmName;
    if (json['assignedRM'] != null) {
      if (json['assignedRM'] is Map) {
        rmId = json['assignedRM']['_id']?.toString();
        rmName = json['assignedRM']['fullName']?.toString();
      } else {
        rmId = json['assignedRM'].toString();
      }
    }

    String? poolId;
    String? poolName;
    if (json['leadPoolId'] != null) {
      if (json['leadPoolId'] is Map) {
        poolId = json['leadPoolId']['_id']?.toString();
        poolName = json['leadPoolId']['name']?.toString();
      } else {
        poolId = json['leadPoolId'].toString();
      }
    }

    final prevRM = json['previousRM'] as Map<String, dynamic>?;
    String? prevStaffId;
    String? prevStaffName;
    if (prevRM != null) {
      if (prevRM['staffId'] is Map) {
        prevStaffId = prevRM['staffId']['_id']?.toString();
        prevStaffName = prevRM['staffId']['fullName']?.toString() ?? prevRM['staffName']?.toString();
      } else {
        prevStaffId = prevRM['staffId']?.toString();
        prevStaffName = prevRM['staffName']?.toString();
      }
    }

    final personal = json['personalDetails'] as Map<String, dynamic>?;
    final fList = json['followUps'] as List<dynamic>? ?? [];

    return LeadModel(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      emailAddress: json['emailAddress']?.toString(),
      assignedRMId: rmId,
      assignedRMName: rmName,
      stage: json['stage']?.toString() ?? 'New',
      city: personal?['city']?.toString(),
      state: personal?['state']?.toString(),
      education: personal?['education']?.toString(),
      experience: personal?['experience']?.toString(),
      followUps: fList.map((x) => FollowUpModel.fromJson(x as Map<String, dynamic>)).toList(),
      leadPoolId: poolId,
      leadPoolName: poolName,
      leadSource: json['leadSource']?.toString() ?? 'IMPORTED_POOL',
      isAppUser: json['isAppUser'] == true,
      appUserId: json['appUserId']?.toString(),
      appOnboardedAt: json['appOnboardedAt'] != null
          ? DateTime.tryParse(json['appOnboardedAt'].toString())
          : null,
      previousRMStaffId: prevStaffId,
      previousRMStaffName: prevStaffName,
      previousRMTransferredAt: prevRM?['transferredAt'] != null
          ? DateTime.tryParse(prevRM!['transferredAt'].toString())
          : null,
      previousRMTransferReason: prevRM?['transferReason']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class FollowUpModel {
  final String notes;
  final DateTime followUpDate;
  final String followUpType;
  final String status;
  final DateTime? nextFollowUpDate;
  final DateTime createdAt;

  FollowUpModel({
    required this.notes,
    required this.followUpDate,
    required this.followUpType,
    required this.status,
    this.nextFollowUpDate,
    required this.createdAt,
  });

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    return FollowUpModel(
      notes: json['notes']?.toString() ?? '',
      followUpDate: json['followUpDate'] != null
          ? DateTime.tryParse(json['followUpDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      followUpType: json['followUpType']?.toString() ?? 'Call',
      status: json['status']?.toString() ?? 'Pending',
      nextFollowUpDate: json['nextFollowUpDate'] != null
          ? DateTime.tryParse(json['nextFollowUpDate'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
