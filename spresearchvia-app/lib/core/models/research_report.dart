import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class ResearchReport {
  final String id;
  final String title;
  final String category;
  final String description;
  final String reportPath;
  final String reportOriginalName;
  final String reportName;
  final String publishedStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  bool isDownloaded;
  final String? youtubeUrl;
  final List<ReportUpdate> updates;

  final String? publishedDate;
  final String? executiveSummary;
  final List<String>? keyHighlights;
  
  // Access metadata for blur overlay
  final bool isLocked;
  final DateTime? planStartDate;
  final DateTime? reportPublishedDate;

  ResearchReport({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.reportPath,
    required this.reportOriginalName,
    required this.reportName,
    required this.publishedStatus,
    this.createdAt,
    this.updatedAt,
    this.isDownloaded = false,
    this.publishedDate,
    this.executiveSummary,
    this.keyHighlights,
    this.isLocked = false,
    this.planStartDate,
    this.reportPublishedDate,
    this.youtubeUrl,
    this.updates = const [],
  });

  bool get isPublished => publishedStatus == 'published';
  String get date => createdAt?.toString().split(' ')[0] ?? '';
  String get formattedDateTime => createdAt != null 
      ? DateFormat('dd/MM/yyyy hh:mm a').format(createdAt!) 
      : 'N/A';

  factory ResearchReport.fromJson(Map<String, dynamic> json) {
    return ResearchReport(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: (json['segmentName'] is List) ? (json['segmentName'] as List).join(', ') : (json['segmentName']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      reportPath: json['reportPath']?.toString() ?? '',
      reportOriginalName: json['reportOriginalName']?.toString() ?? '',
      reportName: json['reportName']?.toString() ?? '',
      publishedStatus: json['publishedStatus']?.toString() ?? 'draft',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])?.toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])?.toLocal()
          : null,
      publishedDate: json['createdAt'] != null 
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(json['createdAt']).toLocal()) 
          : null,
      executiveSummary: json['description']?.toString(),
      keyHighlights: ['Key insights from ${json['title'] ?? 'report'}'],
      isLocked: json['accessMetadata']?['isLocked'] ?? false,
      planStartDate: json['accessMetadata']?['planStartDate'] != null
          ? DateTime.tryParse(json['accessMetadata']['planStartDate'])
          : null,
      reportPublishedDate: json['accessMetadata']?['reportPublishedDate'] != null
          ? DateTime.tryParse(json['accessMetadata']['reportPublishedDate'])
          : null,
      youtubeUrl: json['youtubeUrl']?.toString(),
      updates: (json['updates'] as List<dynamic>?)
          ?.map((e) => ReportUpdate.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'category': category,
      'description': description,
      'reportPath': reportPath,
      'reportOriginalName': reportOriginalName,
      'reportName': reportName,
      'publishedStatus': publishedStatus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'youtubeUrl': youtubeUrl,
      'updates': updates.map((e) => e.toJson()).toList(),
    };
  }
}

class ReportUpdate {
  final String text;
  final DateTime timestamp;

  ReportUpdate({required this.text, required this.timestamp});

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    return ReportUpdate(
      text: json['text']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'])?.toLocal() ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

