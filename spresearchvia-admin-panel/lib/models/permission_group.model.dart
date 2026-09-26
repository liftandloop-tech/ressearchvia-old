class PermissionItem {
  final String feature;
  final List<String> actions;

  PermissionItem({required this.feature, required this.actions});

  factory PermissionItem.fromJson(Map<String, dynamic> json) {
    return PermissionItem(
      feature: json['feature'] ?? '',
      actions: List<String>.from(json['actions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feature': feature,
      'actions': actions,
    };
  }
}

class PermissionGroupModel {
  final String id;
  final String name;
  final String? description;
  final String? departmentId;
  final String? departmentName;
  final List<PermissionItem> permissions;

  PermissionGroupModel({
    required this.id,
    required this.name,
    this.description,
    this.departmentId,
    this.departmentName,
    required this.permissions,
  });

  factory PermissionGroupModel.fromJson(Map<String, dynamic> json) {
    String? deptId;
    String? deptName;
    if (json['departmentId'] is Map<String, dynamic>) {
      deptId = json['departmentId']['_id'] ?? json['departmentId']['id'];
      deptName = json['departmentId']['name'];
    } else if (json['departmentId'] != null) {
      deptId = json['departmentId'].toString();
    }

    return PermissionGroupModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      departmentId: deptId,
      departmentName: deptName,
      permissions: (json['permissions'] as List? ?? [])
          .map((p) => PermissionItem.fromJson(p))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (departmentId != null) 'departmentId': departmentId,
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }
}
