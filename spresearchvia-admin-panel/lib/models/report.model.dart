import 'package:intl/intl.dart';

class ReportModel {
  final String id;
  final String title;
  final String category; // This will store the name
  final String segmentId; // This will store the ID
  final String status;
  final String createdDate;
  final String lastUpdated;
  final String month;
  final String uploadDate;
  final String uploadedBy;
  final String reportType;
  final String description;
  final String? reportOriginalName;
  final String? reportName;
  final String? reportId;
  final List<String> planArray;
  final List<String> segmentIds;
  final List<String> segmentNames;
  final List<Map<String, String>> updates;
  final String? youtubeUrl;

  ReportModel({
    required this.id,
    this.reportId,
    required this.title,
    required this.category,
    required this.segmentId,
    this.segmentIds = const [],
    this.segmentNames = const [],
    this.updates = const [],
    required this.status,
    required this.createdDate,
    required this.lastUpdated,
    required this.month,
    required this.uploadDate,
    required this.uploadedBy,
    required this.reportType,
    required this.description,
    required this.planArray,
    this.reportOriginalName,
    this.reportName,
    this.youtubeUrl,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    String extractTs(dynamic field) {
      if (field == null) return '';
      if (field is String) return field;
      if (field is Map &&
          (field.containsKey('\$date') || field.containsKey('Date'))) {
        return (field['\$date'] ?? field['Date']).toString();
      }
      return field.toString();
    }

    String formatDate(dynamic dateRaw) {
      String dateStr = extractTs(dateRaw);
      if (dateStr.isEmpty) return '';
      try {
        final date = DateTime.parse(dateStr).toLocal();
        return DateFormat('MMM dd, yyyy hh:mm a').format(date);
      } catch (e) {
        return dateStr;
      }
    }

    String status = 'Unpublished';
    if (json['publishedStatus'] == 'published') {
      status = 'Published';
    } else if (json['publishedStatus'] == 'draft') {
      status = 'Draft';
    }

    List<String> plans = [];
    if (json['planArray'] != null) {
      if (json['planArray'] is List) {
        plans = (json['planArray'] as List).map((e) => e.toString()).toList();
      } else if (json['planArray'] is String) {
        plans = [json['planArray']];
      }
    }

    List<String> segNames = [];
    if (json['segmentName'] != null) {
      if (json['segmentName'] is List) {
        segNames = (json['segmentName'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['segmentName'] is String) {
        segNames = [json['segmentName']];
      }
    }

    List<String> segIds = [];
    if (json['segment'] != null) {
      if (json['segment'] is List) {
        segIds = (json['segment'] as List)
            .map((dynamic item) {
              if (item is String) return item;
              if (item is Map) return (item['\$oid'] ?? item['_id']).toString();
              return item.toString();
            })
            .where((s) => s.isNotEmpty)
            .cast<String>()
            .toList();
      } else if (json['segment'] is String) {
        segIds = [json['segment']];
      } else if (json['segment'] is Map) {
        segIds = [
          (json['segment']['\$oid'] ?? json['segment']['_id']).toString(),
        ];
      }
    }

    List<Map<String, String>> parsedUpdates = [];
    if (json['updates'] != null && json['updates'] is List) {
      for (var update in json['updates']) {
        if (update is Map) {
          String rawTs = extractTs(update['timestamp']);
          parsedUpdates.add({
            'text': update['text']?.toString() ?? '',
            'timestamp': formatDate(rawTs),
            'rawTimestamp': rawTs,
          });
        }
      }
      // Sort updates by newest first
      parsedUpdates.sort((a, b) {
        if (a['rawTimestamp']!.isEmpty) return 1;
        if (b['rawTimestamp']!.isEmpty) return -1;
        try {
          return DateTime.parse(
            b['rawTimestamp']!,
          ).compareTo(DateTime.parse(a['rawTimestamp']!));
        } catch (_) {
          return 0;
        }
      });
    }

    return ReportModel(
      id: (json['_id'] is Map && json['_id'].containsKey('\$oid'))
          ? json['_id']['\$oid'].toString()
          : (json['_id'] ?? (json['id'] ?? '')).toString(),
      title: json['title'] ?? '',
      category: segNames.join(', '),
      segmentId: segIds.join(','),
      segmentIds: segIds,
      segmentNames: segNames,
      status: status,
      createdDate: formatDate(json['createdAt']),
      lastUpdated: formatDate(json['updatedAt']),
      month: formatDate(json['createdAt']).split(' ').first,
      uploadDate: formatDate(json['createdAt']),
      uploadedBy: 'Admin',
      reportType: json['reportType'] ?? 'Trading calls',
      description: json['description'] ?? '',
      updates: parsedUpdates,
      planArray: plans,
      reportOriginalName: json['reportOriginalName'],
      reportName: json['reportName'],
      reportId: json['reportId'],
      youtubeUrl: json['youtubeUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reportId': reportId,
      'title': title,
      'category': category,
      'segmentId': segmentId,
      'status': status,
      'createdDate': createdDate,
      'lastUpdated': lastUpdated,
      'month': month,
      'uploadDate': uploadDate,
      'uploadedBy': uploadedBy,
      'reportType': reportType,
      'description': description,
      'planArray': planArray,
      'youtubeUrl': youtubeUrl,
    };
  }
}
