class LeadPoolModel {
  final String id;
  final String name;
  final String? description;
  final int pullSize;
  final int maxPerStaff;
  final bool isActive;
  final int totalLeads;
  final int availableLeads;
  final int assignedLeads;
  final int myLeads;
  final int remainingCapacity;
  final bool isDefaultFresh;
  final bool isGlobal;
  final String? createdBy;
  final String? createdByName;
  final String? creatorRole;
  final bool isOwner;
  final bool canEdit;
  final bool canDelete;
  final DateTime? createdAt;

  LeadPoolModel({
    required this.id,
    required this.name,
    this.description,
    this.pullSize = 20,
    this.maxPerStaff = 100,
    this.isActive = true,
    this.totalLeads = 0,
    this.availableLeads = 0,
    this.assignedLeads = 0,
    this.myLeads = 0,
    this.remainingCapacity = 0,
    this.isDefaultFresh = false,
    this.isGlobal = true,
    this.createdBy,
    this.createdByName,
    this.creatorRole,
    this.isOwner = false,
    this.canEdit = false,
    this.canDelete = false,
    this.createdAt,
  });

  factory LeadPoolModel.fromJson(Map<String, dynamic> json) {
    final poolId = json['_id']?.toString() ?? json['poolId']?.toString() ?? json['id']?.toString() ?? '';
    final name = json['name']?.toString() ?? json['poolName']?.toString() ?? 'Unnamed Pool';
    final pullSize = (json['pullSize'] is num) ? (json['pullSize'] as num).toInt() : (int.tryParse(json['pullSize']?.toString() ?? '20') ?? 20);
    final maxPerStaff = (json['maxPerStaff'] is num) ? (json['maxPerStaff'] as num).toInt() : (int.tryParse(json['maxPerStaff']?.toString() ?? '100') ?? 100);
    final totalLeads = (json['totalLeads'] is num) ? (json['totalLeads'] as num).toInt() : (int.tryParse(json['totalLeads']?.toString() ?? '0') ?? 0);
    final availableLeads = (json['availableLeads'] is num) ? (json['availableLeads'] as num).toInt() : (int.tryParse(json['availableLeads']?.toString() ?? '0') ?? 0);
    final assignedLeads = (json['assignedLeads'] is num) ? (json['assignedLeads'] as num).toInt() : (int.tryParse(json['assignedLeads']?.toString() ?? '0') ?? 0);
    final myLeads = (json['myLeads'] is num) ? (json['myLeads'] as num).toInt() : (int.tryParse(json['myLeads']?.toString() ?? '0') ?? 0);
    final remainingCapacity = (json['remainingCapacity'] is num) ? (json['remainingCapacity'] as num).toInt() : (int.tryParse(json['remainingCapacity']?.toString() ?? '0') ?? (maxPerStaff - myLeads).clamp(0, maxPerStaff));

    final isDefaultFresh = name.toLowerCase() == 'fresh leads' || json['isDefaultFresh'] == true;
    final isGlobal = isDefaultFresh || json['isGlobal'] != false;
    final isOwner = json['isOwner'] == true;
    final canEdit = json['canEdit'] == true || isOwner;
    final canDelete = (json['canDelete'] == true || isOwner) && !isDefaultFresh;

    return LeadPoolModel(
      id: poolId,
      name: name,
      description: json['description']?.toString(),
      pullSize: pullSize > 0 ? pullSize : 20,
      maxPerStaff: maxPerStaff > 0 ? maxPerStaff : 100,
      isActive: json['isActive'] != false,
      totalLeads: totalLeads,
      availableLeads: availableLeads,
      assignedLeads: assignedLeads,
      myLeads: myLeads,
      remainingCapacity: remainingCapacity,
      isDefaultFresh: isDefaultFresh,
      isGlobal: isGlobal,
      createdBy: json['createdBy']?.toString(),
      createdByName: json['createdByName']?.toString() ?? (isDefaultFresh ? 'System Admin' : null),
      creatorRole: json['creatorRole']?.toString() ?? (isDefaultFresh ? 'Admin' : null),
      isOwner: isOwner,
      canEdit: canEdit,
      canDelete: canDelete,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pullSize': pullSize,
      'maxPerStaff': maxPerStaff,
      'isActive': isActive,
      'isGlobal': isGlobal,
      'createdBy': createdBy,
      'createdByName': createdByName,
      'creatorRole': creatorRole,
    };
  }
}
