class Segment {
  final String id;
  final String segmentName;
  final String? segmentStatus;

  Segment({
    required this.id,
    required this.segmentName,
    this.segmentStatus,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    return Segment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      segmentName: json['segmentName']?.toString() ?? '',
      segmentStatus: json['segmentStatus']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'segmentName': segmentName,
      'segmentStatus': segmentStatus,
    };
  }
}

class RegistrationPlan {
  final String id;
  final String planName;
  final String segmentId;
  final String segmentName;
  final double price;
  final String duration;
  final String? description;
  final String? planFeatures;
  final double? perDayCharge;

  RegistrationPlan({
    required this.id,
    required this.planName,
    required this.segmentId,
    required this.segmentName,
    required this.price,
    required this.duration,
    this.description,
    this.planFeatures,
    this.perDayCharge,
  });

  factory RegistrationPlan.fromJson(Map<String, dynamic> json) {
    return RegistrationPlan(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      planName: json['planName']?.toString() ?? '',
      segmentId: json['segmentsId']?.toString() ?? '',
      segmentName: json['segmentsName']?.toString() ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration']?.toString() ?? '',
      description: json['discription']?.toString() ?? json['description']?.toString(),
      planFeatures: json['planFeatures']?.toString(),
      perDayCharge: json['perDayCharge'] != null 
          ? (json['perDayCharge'] as num).toDouble() 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'planName': planName,
      'segmentId': segmentId,
      'segmentName': segmentName,
      'price': price,
      'duration': duration,
      'description': description,
      'planFeatures': planFeatures,
      'perDayCharge': perDayCharge,
    };
  }
}
