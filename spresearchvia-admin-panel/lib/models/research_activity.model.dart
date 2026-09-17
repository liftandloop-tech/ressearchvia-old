class ResearchActivityModel {
  final String id;
  final String reportId;
  final String title;
  final String reportType;
  final String segmentName;
  final String description;
  final String publishedStatus;
  final String? latestUpdate;
  final int updatesCount;
  final int timestamp;
  final bool isAutomated;
  final String createdAt;
  final String updatedAt;

  ResearchActivityModel({
    required this.id,
    required this.reportId,
    required this.title,
    required this.reportType,
    required this.segmentName,
    required this.description,
    required this.publishedStatus,
    this.latestUpdate,
    this.updatesCount = 0,
    required this.timestamp,
    this.isAutomated = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ResearchActivityModel.fromJson(Map<String, dynamic> json) {
    return ResearchActivityModel(
      id: json['id']?.toString() ?? '',
      reportId: json['reportId']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Research Activity',
      reportType: json['reportType']?.toString() ?? 'Trading calls',
      segmentName: json['segmentName']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      publishedStatus: json['publishedStatus']?.toString() ?? 'published',
      latestUpdate: json['latestUpdate']?.toString(),
      updatesCount: json['updatesCount'] is int ? json['updatesCount'] as int : int.tryParse(json['updatesCount']?.toString() ?? '0') ?? 0,
      timestamp: json['timestamp'] is int ? json['timestamp'] as int : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      isAutomated: json['isAutomated'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  String get displaySubtitle {
    if (latestUpdate != null && latestUpdate!.isNotEmpty) {
      return 'Update: $latestUpdate';
    }
    if (description.isNotEmpty) {
      return description;
    }
    return '$segmentName • $reportType';
  }
}
