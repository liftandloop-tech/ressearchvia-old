class LeadPoolModel {
  final String id;
  final String name;
  final String? description;
  final int pullSize;
  final int initialPullSize;
  final int subsequentPullSize;
  final int maxPerStaff;
  final bool isActive;
  final int totalLeads;
  final int availableLeads;
  final int assignedLeads;
  final int myLeads;
  final int totalHeld;
  final int remainingCapacity;
  final int currentStage;
  final bool isDefaultFresh;
  final bool isGlobal;
  final String? createdBy;
  final String? createdByName;
  final String? creatorRole;
  final bool isOwner;
  final bool canEdit;
  final bool canDelete;
  final bool canDelegate;
  final bool canAssign;
  final int assignedStaffCount;
  final List<String> assignedStaffIds;
  final DateTime? createdAt;

  LeadPoolModel({
    required this.id,
    required this.name,
    this.description,
    this.pullSize = 20,
    this.initialPullSize = 20,
    this.subsequentPullSize = 30,
    this.maxPerStaff = 50,
    this.isActive = true,
    this.totalLeads = 0,
    this.availableLeads = 0,
    this.assignedLeads = 0,
    this.myLeads = 0,
    this.totalHeld = 0,
    this.remainingCapacity = 0,
    this.currentStage = 1,
    this.isDefaultFresh = false,
    this.isGlobal = true,
    this.createdBy,
    this.createdByName,
    this.creatorRole,
    this.isOwner = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canDelegate = false,
    this.canAssign = false,
    this.assignedStaffCount = 0,
    this.assignedStaffIds = const [],
    this.createdAt,
  });

  factory LeadPoolModel.fromJson(Map<String, dynamic> json) {
    final poolId = json['_id']?.toString() ?? json['poolId']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? json['poolName']?.toString() ?? 'Unnamed Pool';
    final initialPullSize = (json['initialPullSize'] is num) 
        ? (json['initialPullSize'] as num).toInt() 
        : (int.tryParse(json['initialPullSize']?.toString() ?? '') ?? 
          ((json['pullSize'] is num) ? (json['pullSize'] as num).toInt() : (int.tryParse(json['pullSize']?.toString() ?? '20') ?? 20)));
    final subsequentPullSize = (json['subsequentPullSize'] is num) 
        ? (json['subsequentPullSize'] as num).toInt() 
        : (int.tryParse(json['subsequentPullSize']?.toString() ?? '30') ?? 30);
    final pullSize = initialPullSize;
    final maxPerStaff = (json['maxPerStaff'] is num) ? (json['maxPerStaff'] as num).toInt() : (int.tryParse(json['maxPerStaff']?.toString() ?? '50') ?? 50);
    final totalLeads = (json['totalLeads'] is num) ? (json['totalLeads'] as num).toInt() : (int.tryParse(json['totalLeads']?.toString() ?? '0') ?? 0);
    final availableLeads = (json['availableLeads'] is num) ? (json['availableLeads'] as num).toInt() : (int.tryParse(json['availableLeads']?.toString() ?? '0') ?? 0);
    final assignedLeads = (json['assignedLeads'] is num) ? (json['assignedLeads'] as num).toInt() : (int.tryParse(json['assignedLeads']?.toString() ?? '0') ?? 0);
    final myLeads = (json['myLeads'] is num) ? (json['myLeads'] as num).toInt() : (int.tryParse(json['myLeads']?.toString() ?? '0') ?? 0);
    final totalHeld = (json['totalHeld'] is num) ? (json['totalHeld'] as num).toInt() : (int.tryParse(json['totalHeld']?.toString() ?? '0') ?? myLeads);
    final currentStage = (json['currentStage'] is num) ? (json['currentStage'] as num).toInt() : (totalHeld == 0 ? 1 : 2);
    final remainingCapacity = (json['remainingCapacity'] is num) ? (json['remainingCapacity'] as num).toInt() : (int.tryParse(json['remainingCapacity']?.toString() ?? '0') ?? (maxPerStaff - totalHeld).clamp(0, maxPerStaff));

    final isDefaultFresh = name.toLowerCase() == 'fresh leads' || json['isDefaultFresh'] == true;
    final isGlobal = isDefaultFresh || json['isGlobal'] != false;
    final isOwner = json['isOwner'] == true;
    final canEdit = json['canEdit'] != false;
    final canDelete = (json['canDelete'] == true || isOwner) && !isDefaultFresh;
    final canDelegate = json['canDelegate'] == true || json['canAssign'] == true || isOwner;
    final canAssign = json['canAssign'] == true || canDelegate;

    final rawAssignedIds = json['assignedStaffIds'];
    final List<String> assignedStaffIds = (rawAssignedIds is List) 
        ? rawAssignedIds.map((e) => e.toString()).toList() 
        : [];
    final assignedStaffCount = (json['assignedStaffCount'] is num) 
        ? (json['assignedStaffCount'] as num).toInt() 
        : assignedStaffIds.length;

    return LeadPoolModel(
      id: poolId,
      name: name,
      description: json['description']?.toString(),
      pullSize: pullSize > 0 ? pullSize : 20,
      initialPullSize: initialPullSize > 0 ? initialPullSize : 20,
      subsequentPullSize: subsequentPullSize > 0 ? subsequentPullSize : 30,
      maxPerStaff: maxPerStaff > 0 ? maxPerStaff : 50,
      isActive: json['isActive'] != false,
      totalLeads: totalLeads,
      availableLeads: availableLeads,
      assignedLeads: assignedLeads,
      myLeads: myLeads,
      totalHeld: totalHeld,
      remainingCapacity: remainingCapacity,
      currentStage: currentStage,
      isDefaultFresh: isDefaultFresh,
      isGlobal: isGlobal,
      createdBy: json['createdBy']?.toString(),
      createdByName: json['createdByName']?.toString() ?? (isDefaultFresh ? 'System Admin' : null),
      creatorRole: json['creatorRole']?.toString() ?? (isDefaultFresh ? 'Admin' : null),
      isOwner: isOwner,
      canEdit: canEdit,
      canDelete: canDelete,
      canDelegate: canDelegate,
      canAssign: canAssign,
      assignedStaffCount: assignedStaffCount,
      assignedStaffIds: assignedStaffIds,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pullSize': pullSize,
      'initialPullSize': initialPullSize,
      'subsequentPullSize': subsequentPullSize,
      'maxPerStaff': maxPerStaff,
      'isActive': isActive,
      'isGlobal': isGlobal,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'creatorRole': creatorRole,
      'assignedStaffIds': assignedStaffIds,
    };
  }
}
