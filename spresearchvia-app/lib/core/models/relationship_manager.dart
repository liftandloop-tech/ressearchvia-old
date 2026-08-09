class RelationshipManager {
  final String id;
  final String fullName;
  final String mobileNumber;
  final String? emailAddress;
  final String? department;
  final String? staffId;

  RelationshipManager({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.emailAddress,
    this.department,
    this.staffId,
  });

  factory RelationshipManager.fromJson(Map<String, dynamic> json) {
    return RelationshipManager(
      id: json['id'] ?? json['_id'] ?? '',
      fullName: json['fullName'] ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      emailAddress: json['emailAddress'] as String?,
      department: json['department'] as String?,
      staffId: json['staffId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'emailAddress': emailAddress,
      'department': department,
      'staffId': staffId,
    };
  }
}
