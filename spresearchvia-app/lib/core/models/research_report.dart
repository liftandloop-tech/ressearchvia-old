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
      updates: (json['updates'] is List)
          ? (json['updates'] as List)
              .where((e) => e != null && e is Map)
              .map((e) => ReportUpdate.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : [],
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
  final String? status;
  final DateTime timestamp;

  ReportUpdate({
    required this.text,
    this.status,
    required this.timestamp,
  });

  /// Normalizes status to 'stoploss_hit', 'target_achieved', 'partial_profit', or 'general'
  String get normalizedStatus {
    final s = (status ?? '').toLowerCase().trim();
    if (s == 'stoploss_hit' ||
        s == 'stoploss' ||
        s == 'stop_loss' ||
        s == 'sl_hit' ||
        s == 'stop loss hit' ||
        s == 'stoploss hit' ||
        s == 'sl' ||
        s == 'sl triggered' ||
        s == 'sl trigger') {
      return 'stoploss_hit';
    }
    if (s == 'target_achieved' ||
        s == 'target' ||
        s == 'target_hit' ||
        s == 'target achieved' ||
        s == 'tgt_achieved' ||
        s == 'tgt achieved' ||
        s == 'tgt hit' ||
        s == 'tgt' ||
        s == 'full_profit' ||
        s == 'full profit') {
      return 'target_achieved';
    }
    if (s == 'partial_profit' ||
        s == 'partial' ||
        s == 'profit' ||
        s == 'partial profit' ||
        s == 'part_profit' ||
        s == 'part profit') {
      return 'partial_profit';
    }

    // Keyword detection fallback from text
    final t = text.toLowerCase();
    if (t.contains('sl triggered') ||
        t.contains('sl trigger') ||
        t.contains('sl hit') ||
        t.contains('stoploss') ||
        t.contains('stop loss') ||
        t.contains('exit sl') ||
        t.contains('exit, sl') ||
        t.contains('kindly exit') ||
        t.contains('exit in') ||
        t.contains('hit sl') ||
        t.contains('sl tirgger') ||
        t.contains('sl ttigger') ||
        t.contains('stoploss triggered')) {
      return 'stoploss_hit';
    }
    if (t.contains('partial profit') ||
        t.contains('part profit') ||
        t.contains('partial') ||
        t.contains('book partial') ||
        t.contains('parital profit')) {
      return 'partial_profit';
    }
    if (t.contains('target achieved') ||
        t.contains('target hit') ||
        t.contains('tgt achieved') ||
        t.contains('tgt hit') ||
        t.contains('target') ||
        t.contains('tgt') ||
        t.contains('trgt') ||
        t.contains('full profit') ||
        t.contains('book full profit') ||
        t.contains('porfit') ||
        t.contains('book profit') ||
        t.contains('all targets') ||
        t.contains('target met')) {
      return 'target_achieved';
    }

    return 'general';
  }

  factory ReportUpdate.fromJson(Map<String, dynamic> json) {
    DateTime parsedTime = DateTime.now();
    if (json['timestamp'] != null) {
      if (json['timestamp'] is String) {
        parsedTime = DateTime.tryParse(json['timestamp'])?.toLocal() ?? DateTime.now();
      } else if (json['timestamp'] is Map && json['timestamp']['\$date'] != null) {
        parsedTime = DateTime.tryParse(json['timestamp']['\$date'].toString())?.toLocal() ?? DateTime.now();
      }
    }
    return ReportUpdate(
      text: json['text']?.toString() ?? '',
      status: json['status']?.toString(),
      timestamp: parsedTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

enum TradingCallOutcome {
  targetAchieved,
  partiallyBooked,
  stoplossHit,
  active,
}

extension ResearchReportOutcome on ResearchReport {
  TradingCallOutcome get outcome {
    // Check updates in reverse order (latest decisive outcome first)
    for (int i = updates.length - 1; i >= 0; i--) {
      final s = updates[i].normalizedStatus;
      if (s == 'target_achieved') return TradingCallOutcome.targetAchieved;
      if (s == 'partial_profit') return TradingCallOutcome.partiallyBooked;
      if (s == 'stoploss_hit') return TradingCallOutcome.stoplossHit;
    }

    // Fallback: check title and description
    final combined = '$title $description'.toLowerCase();
    if (combined.contains('target achieved') ||
        combined.contains('target hit') ||
        combined.contains('tgt achieved') ||
        combined.contains('full profit') ||
        combined.contains('all targets') ||
        combined.contains('target met')) {
      return TradingCallOutcome.targetAchieved;
    }
    if (combined.contains('partial profit') ||
        combined.contains('partially booked') ||
        combined.contains('book partial')) {
      return TradingCallOutcome.partiallyBooked;
    }
    if (combined.contains('stop loss hit') ||
        combined.contains('stoploss hit') ||
        combined.contains('sl hit') ||
        combined.contains('sl triggered') ||
        combined.contains('hit sl')) {
      return TradingCallOutcome.stoplossHit;
    }

    return TradingCallOutcome.active;
  }
}

class TradingAccuracyStats {
  final int totalCalls;
  final int closedCalls;
  final int targetAchieved;
  final int partiallyBooked;
  final int stoplossHit;
  final int active;
  final double accuracyRate;

  const TradingAccuracyStats({
    this.totalCalls = 0,
    this.closedCalls = 0,
    this.targetAchieved = 0,
    this.partiallyBooked = 0,
    this.stoplossHit = 0,
    this.active = 0,
    this.accuracyRate = 0.0,
  });

  factory TradingAccuracyStats.fromJson(Map<String, dynamic> json) {
    final total = json['totalCalls'] is int
        ? json['totalCalls'] as int
        : int.tryParse(json['totalCalls']?.toString() ?? '') ?? 0;
    final closed = json['closedCalls'] is int
        ? json['closedCalls'] as int
        : int.tryParse(json['closedCalls']?.toString() ?? '') ?? 0;
    final target = json['targetAchieved'] is int
        ? json['targetAchieved'] as int
        : int.tryParse(json['targetAchieved']?.toString() ?? '') ?? 0;
    final partial = json['partiallyBooked'] is int
        ? json['partiallyBooked'] as int
        : int.tryParse(json['partiallyBooked']?.toString() ?? '') ?? 0;
    final sl = json['stoplossHit'] is int
        ? json['stoplossHit'] as int
        : int.tryParse(json['stoplossHit']?.toString() ?? '') ?? 0;
    final act = json['active'] is int
        ? json['active'] as int
        : int.tryParse(json['active']?.toString() ?? '') ?? 0;
    final acc = json['accuracyRate'] is num
        ? (json['accuracyRate'] as num).toDouble()
        : double.tryParse(json['accuracyRate']?.toString() ?? '') ?? 0.0;

    return TradingAccuracyStats(
      totalCalls: total,
      closedCalls: closed,
      targetAchieved: target,
      partiallyBooked: partial,
      stoplossHit: sl,
      active: act,
      accuracyRate: double.parse(acc.toStringAsFixed(1)),
    );
  }

  factory TradingAccuracyStats.fromReports(List<ResearchReport> reports) {
    int target = 0;
    int partial = 0;
    int sl = 0;
    int act = 0;

    for (final r in reports) {
      switch (r.outcome) {
        case TradingCallOutcome.targetAchieved:
          target++;
          break;
        case TradingCallOutcome.partiallyBooked:
          partial++;
          break;
        case TradingCallOutcome.stoplossHit:
          sl++;
          break;
        case TradingCallOutcome.active:
          act++;
          break;
      }
    }

    final closed = target + partial + sl;
    final total = reports.length;
    final acc = closed > 0 ? ((target + partial) / closed) * 100 : 0.0;

    return TradingAccuracyStats(
      totalCalls: total,
      closedCalls: closed,
      targetAchieved: target,
      partiallyBooked: partial,
      stoplossHit: sl,
      active: act,
      accuracyRate: double.parse(acc.toStringAsFixed(1)),
    );
  }

  double get targetRate => closedCalls > 0 ? (targetAchieved / closedCalls) * 100 : 0.0;
  double get partialRate => closedCalls > 0 ? (partiallyBooked / closedCalls) * 100 : 0.0;
  double get stoplossRate => closedCalls > 0 ? (stoplossHit / closedCalls) * 100 : 0.0;
}

