class BranchModel {
  final String id;
  final String name;
  final String? code;
  final String? city;
  final String? state;
  final String? address;
  final String? pincode;
  final bool isActive;
  final int staffCount;
  final int totalStaffCount;
  final int applicantCount;

  BranchModel({
    required this.id,
    required this.name,
    this.code,
    this.city,
    this.state,
    this.address,
    this.pincode,
    this.isActive = true,
    this.staffCount = 0,
    this.totalStaffCount = 0,
    this.applicantCount = 0,
  });

  factory BranchModel.fromJson(Map<String, dynamic> json) {
    return BranchModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      address: json['address']?.toString(),
      pincode: json['pincode']?.toString(),
      isActive: json['isActive'] != false,
      staffCount: (json['staffCount'] as num?)?.toInt() ?? (json['activeStaffCount'] as num?)?.toInt() ?? 0,
      totalStaffCount: (json['totalStaffCount'] as num?)?.toInt() ?? 0,
      applicantCount: (json['applicantCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (code != null) 'code': code,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (address != null) 'address': address,
      if (pincode != null) 'pincode': pincode,
      'isActive': isActive,
    };
  }
}

