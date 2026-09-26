class DepartmentModel {
  final String id;
  final String name;
  final String? code;
  final String? description;
  final List<String> assignedPages;
  final bool isGlobal;
  final bool isActive;

  DepartmentModel({
    required this.id,
    required this.name,
    this.code,
    this.description,
    required this.assignedPages,
    this.isGlobal = false,
    this.isActive = true,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      code: json['code'],
      description: json['description'],
      assignedPages: (json['assignedPages'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      isGlobal: json['isGlobal'] == true,
      isActive: json['isActive'] != false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (code != null) 'code': code,
      'description': description,
      'assignedPages': assignedPages,
      'isGlobal': isGlobal,
      'isActive': isActive,
    };
  }
}
