class SubscriptionPlanModel {
  final String id;
  final String planName;
  final String duration;
  final String day;
  final int price;
  final int perDayCharge;
  final String planStatus;
  final String description;
  final String planFeatures;
  final String? segmentsId;
  final String? segmentsName;
  final bool isHni;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlanModel({
    required this.id,
    required this.planName,
    required this.duration,
    required this.day,
    required this.price,
    required this.perDayCharge,
    required this.planStatus,
    required this.description,
    required this.planFeatures,
    this.segmentsId,
    this.segmentsName,
    this.isHni = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['_id'] ?? '',
      planName: json['planName'] ?? '',
      duration: json['duration'] ?? '',
      day: json['day'] ?? '',
      price: json['price'] ?? 0,
      perDayCharge: json['perDayCharge'] ?? 0,
      planStatus: (json['planStatus']?.toString().toLowerCase() == 'active')
          ? 'Active'
          : 'Inactive',
      description:
          json['discription']?.toString() ??
          json['description']?.toString() ??
          '',
      planFeatures: json['planFeatures'] ?? '',
      segmentsId: json['segmentsId'] ?? '',
      segmentsName: json['segmentsName'] ?? '', // Added segmentsName
      isHni: json['isHni'] == true || json['isHni'] == 1,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'planName': planName,
      'duration': duration,
      'day': day,
      'price': price,
      'perDayCharge': perDayCharge,
      'planStatus': planStatus,
      'discription': description,
      'planFeatures': planFeatures,
      'segmentsId': segmentsId,
      'segmentsName': segmentsName,
      'isHni': isHni,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get formattedPrice => '₹${price.toStringAsFixed(2)}';

  String get formattedDuration => '$duration Days';

  String get formattedPerDayCharge => '₹$perDayCharge/day';
}

class SubscriptionPlanResponse {
  final int status;
  final String message;
  final SubscriptionPlanData data;

  SubscriptionPlanResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SubscriptionPlanResponse.fromJson(dynamic json) {
    // Handle case where json might not be a Map
    if (json is! Map<String, dynamic>) {
      return SubscriptionPlanResponse(
        status: 0,
        message: 'Invalid response format',
        data: SubscriptionPlanData(totalCount: 0, plans: []),
      );
    }

    return SubscriptionPlanResponse(
      status: int.tryParse(json['status']?.toString() ?? '200') ?? 200,
      message: (json['message'] ?? '').toString(),
      data: SubscriptionPlanData.fromJson(json['data'] ?? {}),
    );
  }
}

class SubscriptionPlanData {
  final int totalCount;
  final List<SubscriptionPlanModel> plans;

  SubscriptionPlanData({required this.totalCount, required this.plans});

  factory SubscriptionPlanData.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanData(
      totalCount: json['totalCount'] ?? 0,
      plans:
          (json['data'] as List<dynamic>?)
              ?.map((e) => SubscriptionPlanModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}
