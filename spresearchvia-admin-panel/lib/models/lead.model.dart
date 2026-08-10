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
