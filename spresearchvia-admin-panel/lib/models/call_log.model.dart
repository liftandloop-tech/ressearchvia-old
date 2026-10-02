class CallLogModel {
  final String id;
  final String leadId;
  final String? staffId;
  final String? staffName;
  final String provider;
  final String? callId;
  final String fromDestination;
  final String toDestination;
  final String status;
  final DateTime startedAt;
  final DateTime? answeredAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final String? notes;
  final String? disposition;

  CallLogModel({
    required this.id,
    required this.leadId,
    this.staffId,
    this.staffName,
    required this.provider,
    this.callId,
    required this.fromDestination,
    required this.toDestination,
    required this.status,
    required this.startedAt,
    this.answeredAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.notes,
    this.disposition,
  });

  factory CallLogModel.fromJson(Map<String, dynamic> json) {
    String? staffId;
    String? staffName;
    if (json['staffId'] != null) {
      if (json['staffId'] is Map) {
        staffId = json['staffId']['_id']?.toString() ?? json['staffId']['id']?.toString();
        staffName = json['staffId']['fullName']?.toString() ?? json['staffId']['name']?.toString();
      } else {
        staffId = json['staffId']?.toString();
      }
    }

    final fromObj = json['from'];
    final fromDest = fromObj is Map ? (fromObj['destination']?.toString() ?? '') : '';

    final toObj = json['to'];
    final toDest = toObj is Map ? (toObj['destination']?.toString() ?? '') : '';

    return CallLogModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      leadId: json['leadId']?.toString() ?? '',
      staffId: staffId,
      staffName: staffName,
      provider: json['provider']?.toString() ?? 'airtel_vonage',
      callId: json['callId']?.toString(),
      fromDestination: fromDest,
      toDestination: toDest,
      status: json['status']?.toString() ?? 'initiated',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      answeredAt: json['answeredAt'] != null ? DateTime.tryParse(json['answeredAt'].toString()) : null,
      endedAt: json['endedAt'] != null ? DateTime.tryParse(json['endedAt'].toString()) : null,
      durationSeconds: int.tryParse(json['durationSeconds']?.toString() ?? '0') ?? 0,
      notes: json['notes']?.toString(),
      disposition: json['disposition']?.toString(),
    );
  }
}
