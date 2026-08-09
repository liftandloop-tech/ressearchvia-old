class AttendanceModel {
  final String id;
  final String staffId;
  final String staffName;
  final String staffCode;
  final DateTime loginTime;
  final DateTime? logoutTime;
  final int totalWorkingMinutes;
  final bool isRemote;
  final String? deviceInfo;
  final List<ActivityLogModel> activityLogs;

  AttendanceModel({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.staffCode,
    required this.loginTime,
    this.logoutTime,
    required this.totalWorkingMinutes,
    required this.isRemote,
    this.deviceInfo,
    required this.activityLogs,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    String sName = '';
    String sCode = '';
    String sId = '';
    if (json['staffId'] != null) {
      if (json['staffId'] is Map) {
        sId = json['staffId']['_id']?.toString() ?? '';
        sName = json['staffId']['fullName']?.toString() ?? '';
        sCode = json['staffId']['staffId']?.toString() ?? '';
      } else {
        sId = json['staffId'].toString();
      }
    }

    final logs = json['activityLogs'] as List<dynamic>? ?? [];

    return AttendanceModel(
      id: json['_id']?.toString() ?? '',
      staffId: sId,
      staffName: sName,
      staffCode: sCode,
      loginTime: json['loginTime'] != null
          ? DateTime.tryParse(json['loginTime'].toString()) ?? DateTime.now()
          : DateTime.now(),
      logoutTime: json['logoutTime'] != null
          ? DateTime.tryParse(json['logoutTime'].toString())
          : null,
      totalWorkingMinutes: json['totalWorkingMinutes'] as int? ?? 0,
      isRemote: json['isRemote'] as bool? ?? false,
      deviceInfo: json['deviceInfo']?.toString(),
      activityLogs: logs.map((x) => ActivityLogModel.fromJson(x as Map<String, dynamic>)).toList(),
    );
  }
}

class ActivityLogModel {
  final DateTime timestamp;
  final bool faceDetected;

  ActivityLogModel({
    required this.timestamp,
    required this.faceDetected,
  });

  factory ActivityLogModel.fromJson(Map<String, dynamic> json) {
    return ActivityLogModel(
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      faceDetected: json['faceDetected'] as bool? ?? false,
    );
  }
}
