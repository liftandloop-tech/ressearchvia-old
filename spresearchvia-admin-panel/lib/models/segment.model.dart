class SegmentModel {
  final String id;
  final String segmentName;
  final String segmentDescription;
  final String segmentStatus;

  final DateTime createdAt;

  SegmentModel({
    required this.id,
    required this.segmentName,
    required this.segmentDescription,
    required this.segmentStatus,
    required this.createdAt,
  });

  factory SegmentModel.fromJson(Map<String, dynamic> json) {
    return SegmentModel(
      id: json['_id'] ?? '',
      segmentName: json['segmentName'] ?? '',
      segmentDescription: json['segmentDiscription'] ?? '',
      segmentStatus: json['segmentStatus'] ?? 'inactive',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  String get formattedStatus {
    if (segmentStatus.toLowerCase() == 'active') return 'Active';
    return 'Inactive';
  }
}

class SegmentResponse {
  final int status;
  final String message;
  final SegmentData data;

  SegmentResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory SegmentResponse.fromJson(dynamic json) {
    // Handle case where json might not be a Map
    if (json is! Map<String, dynamic>) {
      return SegmentResponse(
        status: 0,
        message: 'Invalid response format',
        data: SegmentData(segmentsData: []),
      );
    }

    return SegmentResponse(
      status: int.tryParse(json['status']?.toString() ?? '0') ?? 0,
      message: (json['message'] ?? '').toString(),
      data: SegmentData.fromJson(json['data'] ?? {}),
    );
  }
}

class SegmentData {
  final List<SegmentModel> segmentsData;

  SegmentData({required this.segmentsData});

  factory SegmentData.fromJson(Map<String, dynamic> json) {
    var list = json['segmentsData'] as List? ?? [];
    List<SegmentModel> segmentsList = list
        .map((i) => SegmentModel.fromJson(i))
        .toList();
    return SegmentData(segmentsData: segmentsList);
  }
}
