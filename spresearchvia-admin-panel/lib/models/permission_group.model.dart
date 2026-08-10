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
  final List<PermissionItem> permissions;

  PermissionGroupModel({
    required this.id,
    required this.name,
    this.description,
    required this.permissions,
  });

  factory PermissionGroupModel.fromJson(Map<String, dynamic> json) {
    return PermissionGroupModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
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
      'permissions': permissions.map((p) => p.toJson()).toList(),
    };
  }
}
