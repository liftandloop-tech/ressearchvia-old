import 'permission_group.model.dart';

class RoleModel {
  final String id;
  final String name;
  final String? code;
  final int level;
  final String? description;
  final String? departmentId;
  final String? departmentName;
  final List<PermissionGroupModel> permissionGroups;

  RoleModel({
    required this.id,
    required this.name,
    this.code,
    this.level = 1,
    this.description,
    this.departmentId,
    this.departmentName,
    required this.permissionGroups,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    String? deptId;
    String? deptName;
    if (json['departmentId'] is Map<String, dynamic>) {
      deptId = json['departmentId']['_id'] ?? json['departmentId']['id'];
      deptName = json['departmentId']['name'];
    } else if (json['departmentId'] != null) {
      deptId = json['departmentId'].toString();
    }

    return RoleModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      level: json['level'] is int ? json['level'] : int.tryParse(json['level']?.toString() ?? '1') ?? 1,
      description: json['description'],
      departmentId: deptId,
      departmentName: deptName,
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
      if (code != null) 'code': code,
      'level': level,
      'description': description,
      if (departmentId != null) 'departmentId': departmentId,
      'permissionGroups': permissionGroups.map((pg) => pg.id).toList(),
    };
  }
}
