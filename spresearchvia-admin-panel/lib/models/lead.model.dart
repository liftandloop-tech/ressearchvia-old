class LeadModel {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String? alternateMobile;
  final String? emailAddress;
  final String? assignedRMId;
  final String? assignedRMName;
  final String stage;
  final String? city;
  final String? state;
  final String? education;
  final String? experience;
  final String remarks;
  final List<FollowUpModel> followUps;
  final String? leadPoolId;
  final String? leadPoolName;
  final String? campaignId;
  final String? campaignName;
  final String? leadVendorId;
  final String? leadVendorName;
  final List<String> segmentIds;
  final List<String> segmentNames;
  final DateTime? freeTrialStartDate;
  final DateTime? freeTrialEndDate;
  final String? importBatchId;
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
    this.alternateMobile,
    this.emailAddress,
    this.assignedRMId,
    this.assignedRMName,
    required this.stage,
    this.city,
    this.state,
    this.education,
    this.experience,
    this.remarks = '',
    required this.followUps,
    this.leadPoolId,
    this.leadPoolName,
    this.campaignId,
    this.campaignName,
    this.leadVendorId,
    this.leadVendorName,
    this.segmentIds = const [],
    this.segmentNames = const [],
    this.freeTrialStartDate,
    this.freeTrialEndDate,
    this.importBatchId,
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

  bool get hasActiveFreeTrial {
    if (freeTrialEndDate == null) return false;
    return freeTrialEndDate!.isAfter(DateTime.now());
  }

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

    String? cId;
    String? cName;
    if (json['campaignId'] != null) {
      if (json['campaignId'] is Map) {
        cId = json['campaignId']['_id']?.toString();
        cName = json['campaignId']['name']?.toString();
      } else {
        cId = json['campaignId'].toString();
      }
    }

    String? vId;
    String? vName;
    if (json['leadVendorId'] != null) {
      if (json['leadVendorId'] is Map) {
        vId = json['leadVendorId']['_id']?.toString();
        vName = json['leadVendorId']['name']?.toString();
      } else {
        vId = json['leadVendorId'].toString();
      }
    }

    final rawSegments = json['segmentIds'] as List<dynamic>? ?? [];
    final List<String> segIds = [];
    final List<String> segNames = [];
    for (var s in rawSegments) {
      if (s is Map) {
        if (s['_id'] != null) segIds.add(s['_id'].toString());
        if (s['segmentName'] != null) segNames.add(s['segmentName'].toString());
      } else if (s != null) {
        segIds.add(s.toString());
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

    final freeTrial = json['freeTrial'] as Map<String, dynamic>?;
    DateTime? trialStart;
    DateTime? trialEnd;
    if (freeTrial != null) {
      if (freeTrial['startDate'] != null) {
        trialStart = DateTime.tryParse(freeTrial['startDate'].toString());
      }
      if (freeTrial['endDate'] != null) {
        trialEnd = DateTime.tryParse(freeTrial['endDate'].toString());
      }
    }

    return LeadModel(
      id: json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      alternateMobile: json['alternateMobile']?.toString(),
      emailAddress: json['emailAddress']?.toString(),
      assignedRMId: rmId,
      assignedRMName: rmName,
      stage: json['stage']?.toString() ?? 'New',
      city: personal?['city']?.toString() ?? json['city']?.toString(),
      state: personal?['state']?.toString() ?? json['state']?.toString(),
      education: personal?['education']?.toString(),
      experience: personal?['experience']?.toString(),
      remarks: json['remarks']?.toString() ?? '',
      followUps: fList.map((x) => FollowUpModel.fromJson(x as Map<String, dynamic>)).toList(),
      leadPoolId: poolId,
      leadPoolName: poolName,
      campaignId: cId,
      campaignName: cName,
      leadVendorId: vId,
      leadVendorName: vName,
      segmentIds: segIds,
      segmentNames: segNames,
      freeTrialStartDate: trialStart,
      freeTrialEndDate: trialEnd,
      importBatchId: json['importBatchId']?.toString(),
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
  final String? id;
  final String notes;
  final DateTime followUpDate;
  final String followUpType;
  final String status;
  final DateTime? nextFollowUpDate;
  final DateTime createdAt;

  FollowUpModel({
    this.id,
    required this.notes,
    required this.followUpDate,
    required this.followUpType,
    required this.status,
    this.nextFollowUpDate,
    required this.createdAt,
  });

  bool get isOverdue => followUpDate.isBefore(DateTime.now()) && (status == 'Pending' || status == 'Rescheduled');

  factory FollowUpModel.fromJson(Map<String, dynamic> json) {
    return FollowUpModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
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

class LeadCampaignModel {
  final String id;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? startDate;
  final DateTime? endDate;
  final num budget;

  LeadCampaignModel({
    required this.id,
    required this.name,
    this.description,
    this.isActive = true,
    this.startDate,
    this.endDate,
    this.budget = 0,
  });

  factory LeadCampaignModel.fromJson(Map<String, dynamic> json) {
    return LeadCampaignModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Campaign',
      description: json['description']?.toString(),
      isActive: json['isActive'] != false,
      startDate: json['startDate'] != null ? DateTime.tryParse(json['startDate'].toString()) : null,
      endDate: json['endDate'] != null ? DateTime.tryParse(json['endDate'].toString()) : null,
      budget: (json['budget'] is num) ? json['budget'] as num : 0,
    );
  }
}

class LeadVendorModel {
  final String id;
  final String name;
  final String? code;
  final String? contactPerson;
  final String? mobile;
  final String? email;
  final num costPerLead;
  final bool isActive;

  LeadVendorModel({
    required this.id,
    required this.name,
    this.code,
    this.contactPerson,
    this.mobile,
    this.email,
    this.costPerLead = 0,
    this.isActive = true,
  });

  factory LeadVendorModel.fromJson(Map<String, dynamic> json) {
    return LeadVendorModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Vendor',
      code: json['code']?.toString(),
      contactPerson: json['contactPerson']?.toString(),
      mobile: json['mobile']?.toString(),
      email: json['email']?.toString(),
      costPerLead: (json['costPerLead'] is num) ? json['costPerLead'] as num : 0,
      isActive: json['isActive'] != false,
    );
  }
}

class LeadSegmentModel {
  final String id;
  final String name;
  final String? description;
  final String status;

  LeadSegmentModel({
    required this.id,
    required this.name,
    this.description,
    this.status = 'active',
  });

  factory LeadSegmentModel.fromJson(Map<String, dynamic> json) {
    return LeadSegmentModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['segmentName']?.toString() ?? json['name']?.toString() ?? '',
      description: json['segmentDiscription']?.toString() ?? json['description']?.toString(),
      status: json['segmentStatus']?.toString() ?? json['status']?.toString() ?? 'active',
    );
  }
}

class LeadTimelineModel {
  final String id;
  final String leadId;
  final String eventType;
  final String title;
  final String description;
  final Map<String, dynamic> metadata;
  final String? performedByName;
  final DateTime createdAt;

  LeadTimelineModel({
    required this.id,
    required this.leadId,
    required this.eventType,
    required this.title,
    required this.description,
    this.metadata = const {},
    this.performedByName,
    required this.createdAt,
  });

  factory LeadTimelineModel.fromJson(Map<String, dynamic> json) {
    String? actor;
    if (json['performedBy'] != null) {
      if (json['performedBy'] is Map) {
        actor = json['performedBy']['name']?.toString();
      } else {
        actor = json['performedBy'].toString();
      }
    }

    return LeadTimelineModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? 'ACTIVITY',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      metadata: (json['metadata'] is Map) ? Map<String, dynamic>.from(json['metadata'] as Map) : {},
      performedByName: actor,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class PendingFollowUpModel {
  final String leadId;
  final String fullName;
  final String mobileNumber;
  final String? emailAddress;
  final String stage;
  final String? assignedRMId;
  final String? assignedRMName;
  final String? campaignName;
  final String followUpId;
  final String notes;
  final DateTime followUpDate;
  final String followUpType;
  final String status;
  final DateTime? nextFollowUpDate;
  final bool isOverdue;

  PendingFollowUpModel({
    required this.leadId,
    required this.fullName,
    required this.mobileNumber,
    this.emailAddress,
    required this.stage,
    this.assignedRMId,
    this.assignedRMName,
    this.campaignName,
    required this.followUpId,
    required this.notes,
    required this.followUpDate,
    required this.followUpType,
    required this.status,
    this.nextFollowUpDate,
    required this.isOverdue,
  });

  factory PendingFollowUpModel.fromJson(Map<String, dynamic> json) {
    final fDate = json['followUpDate'] != null
        ? DateTime.tryParse(json['followUpDate'].toString()) ?? DateTime.now()
        : DateTime.now();

    return PendingFollowUpModel(
      leadId: json['leadId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? 'Unnamed Lead',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      emailAddress: json['emailAddress']?.toString(),
      stage: json['stage']?.toString() ?? 'New',
      assignedRMId: json['assignedRM']?.toString(),
      assignedRMName: json['assignedRMName']?.toString() ?? 'Unassigned',
      campaignName: json['campaignName']?.toString(),
      followUpId: json['followUpId']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      followUpDate: fDate,
      followUpType: json['followUpType']?.toString() ?? 'Call',
      status: json['status']?.toString() ?? 'Pending',
      nextFollowUpDate: json['nextFollowUpDate'] != null
          ? DateTime.tryParse(json['nextFollowUpDate'].toString())
          : null,
      isOverdue: json['isOverdue'] == true || fDate.isBefore(DateTime.now()),
    );
  }
}
