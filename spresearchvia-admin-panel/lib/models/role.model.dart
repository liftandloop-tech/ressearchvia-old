import 'permission_group.model.dart';

class RoleModel {
  final String id;
  final String name;
  final String? description;
  final List<PermissionGroupModel> permissionGroups;

  RoleModel({
    required this.id,
    required this.name,
    this.description,
    required this.permissionGroups,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      permissionGroups: (json['permissionGroups'] as List? ?? [])
          .map((pg) {
            if (pg is Map<String, dynamic>) {
              return PermissionGroupModel.fromJson(pg);
            }
            return PermissionGroupModel(id: pg.toString(), name: '', permissions: []);
          })
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'permissionGroups': permissionGroups.map((pg) => pg.id).toList(),
    };
  }
}
