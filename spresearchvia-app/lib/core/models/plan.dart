class Plan {
  final String id;
  final String name;
  final double amount;
  final String validity;
  final double cgstPercent;
  final double sgstPercent;
  final String? description;
  final int? validityDays;
  final DateTime? expiryDate;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? purchaseDate;
  final List<String>? features;
  final bool isActive;
  final bool isExpired;
  final bool isFailed;
  final bool isPending;

  Plan({
    required this.id,
    required this.name,
    required this.amount,
    required this.validity,
    this.cgstPercent = 9.0,
    this.sgstPercent = 9.0,
    this.description,
    this.validityDays,
    this.expiryDate,
    this.startDate,
    this.endDate,
    this.purchaseDate,
    this.features,
    this.isActive = false,
    this.isExpired = false,
    this.isFailed = false,
    this.isPending = false,
  });

  double get cgstAmount => (amount * cgstPercent) / 100;
  double get sgstAmount => (amount * sgstPercent) / 100;
  double get totalAmount => amount + cgstAmount + sgstAmount;

  factory Plan.fromJson(Map<String, dynamic> json) {
    final rawStatus =
        (json['status'] ?? json['paymentStatus'] ?? json['planStatus'] ?? '')
            .toString()
            .toLowerCase();
    final normalizedStatus = rawStatus.replaceAll(RegExp(r'[^a-z]'), '');

    final isActive =
        json['isActive'] == true ||
        normalizedStatus == 'active' ||
        normalizedStatus == 'success' ||
        normalizedStatus == 'completed';
    final isExpired =
        json['isExpired'] == true || normalizedStatus == 'expired';
    final isFailed = json['isFailed'] == true || normalizedStatus == 'failed';
    final isPending = normalizedStatus == 'pending';

    final validityVal = json['validity'];
    String validityStr = '';
    int? validityDaysVal = json['validityDays'];

    if (validityVal is int) {
      validityDaysVal = validityVal;
      validityStr = '$validityVal Days';
    } else if (validityVal is String) {
      validityStr = validityVal;
    }

    return Plan(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['packageName'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      validity: validityStr,
      cgstPercent: (json['cgstPercent'] ?? 9.0).toDouble(),
      sgstPercent: (json['sgstPercent'] ?? 9.0).toDouble(),
      description: json['description'],
      validityDays: validityDaysVal,
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString())
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString())
          : null,
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.tryParse(json['purchaseDate'].toString())
          : null,
      features: json['features'] != null
          ? List<String>.from(json['features'])
          : null,
      isActive: isActive,
      isExpired: isExpired,
      isFailed: isFailed,
      isPending: isPending,
    );
  }

  static List<Plan> getMockPlans() {
    return [
      Plan(
        id: 'YEARLY',
        name: 'Silver',
        amount: 5000,
        validity:
            '5 days research desk access\nRegistration amount is not refundable\nAnnual renewal process\n\nKey features:\n\u2022 Experienced RM will be assigned\n\u2022 Real time market guidance\n\u2022 Real time news and updates',
        validityDays: 365,
      ),
      Plan(
        id: 'LIFETIME',
        name: 'Gold',
        amount: 10000,
        validity:
            '7 days research desk access\nOne time registration method\nRegistration amount will be adjusted in service package\n\nKey features:\n\u2022 Experienced RM will be assigned\n\u2022 Real time market guidance\n\u2022 Real time news and updates',
        validityDays: 3652,
      ),
    ];
  }
}
