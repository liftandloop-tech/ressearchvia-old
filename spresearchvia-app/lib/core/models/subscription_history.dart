enum SubscriptionStatus { active, expired, failed, success, pending, suspended }

class SubscriptionHistory {
  final String id;
  final String planName;
  final String paymentDate;
  final String amountPaid;
  final String perDayCost;
  final String validityDays;
  final String expiryDate;
  final SubscriptionStatus headerStatus;
  final SubscriptionStatus footerStatus;
  final bool isPartial;
  final String? paymentIntentId;
  final String? invoiceId;
  final String? segmentId;
  final double? partialTotalTarget;
  final List<dynamic> partialPaymentsHistory;
  final double amountValue; // Raw numeric amount paid
  final double? rawRemainingAmount; // Direct from backend
  final double? totalAmount;
  final double? totalAgreedAmount;
  final double? baseAmount;
  final double? gstAmount;
  final double? baseRemaining;
  final double? gstRemaining;

  String get remainingAmount {
    // Use the backend-computed value first
    if (baseRemaining != null && gstRemaining != null) {
      if (baseRemaining! <= 0 && gstRemaining! <= 0) return '₹0';
      return '₹${baseRemaining!.toStringAsFixed(2)} + ₹${gstRemaining!.toStringAsFixed(2)}';
    }

    if (rawRemainingAmount != null && rawRemainingAmount! > 0) {
      final base = (rawRemainingAmount! / 1.18).toStringAsFixed(2);
      final gst = (rawRemainingAmount! - (rawRemainingAmount! / 1.18)).toStringAsFixed(2);
      return '₹$base + ₹$gst';
    }
    
    return '₹0';
  }

  String get totalAmountStr {
    if (baseAmount != null && gstAmount != null) {
      return '₹${baseAmount!.toStringAsFixed(2)} + ₹${gstAmount!.toStringAsFixed(2)}';
    }
    if (totalAmount != null && totalAmount! > 0) {
      final base = (totalAmount! / 1.18).toStringAsFixed(2);
      final gst = (totalAmount! - (totalAmount! / 1.18)).toStringAsFixed(2);
      return '₹$base + ₹$gst';
    }
    return amountPaid;
  }

  SubscriptionHistory({
    required this.id,
    required this.planName,
    required this.paymentDate,
    required this.amountPaid,
    required this.perDayCost,
    required this.validityDays,
    required this.expiryDate,
    required this.headerStatus,
    required this.footerStatus,
    this.isPartial = false,
    this.paymentIntentId,
    this.invoiceId,
    this.segmentId,
    this.partialTotalTarget,
    this.partialPaymentsHistory = const [],
    this.amountValue = 0.0,
    this.rawRemainingAmount,
    this.totalAmount,
    this.totalAgreedAmount,
    this.baseAmount,
    this.gstAmount,
    this.baseRemaining,
    this.gstRemaining,
  });

  factory SubscriptionHistory.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase() ?? 'active';
    SubscriptionStatus headerStatus = SubscriptionStatus.active;
    if (status == 'expired') {
      headerStatus = SubscriptionStatus.expired;
    } else if (status == 'failed') {
      headerStatus = SubscriptionStatus.failed;
    } else if (status == 'pending' || status.contains('pending')) {
      headerStatus = SubscriptionStatus.pending;
    } else if (status == 'suspended') {
      headerStatus = SubscriptionStatus.suspended;
    }

    final startDate = json['startDate'] != null
        ? DateTime.tryParse(json['startDate'].toString())
        : json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : DateTime.now();

    final endDate = json['endDate'] != null
        ? DateTime.tryParse(json['endDate'].toString())
        : null;

    String paymentDate = 'N/A';
    if (startDate != null) {
      paymentDate =
          '${_monthName(startDate.month)} ${startDate.day}, ${startDate.year}';
    }

    String expiryDate = 'N/A';
    if (endDate != null) {
      expiryDate =
          '${_monthName(endDate.month)} ${endDate.day}, ${endDate.year}';
    }

    final validity =
        double.tryParse(json['validity']?.toString() ?? '0') ?? 0;
    final String validityDays = '${validity.toInt()} days';

    // Amount: prefer amountPaid (actual paid), then basicAmount, then amount
    double amount = 0.0;
    if (json['amountPaid'] != null) {
      amount = (json['amountPaid'] is num)
          ? (json['amountPaid'] as num).toDouble()
          : double.tryParse(json['amountPaid'].toString()) ?? 0.0;
    } else if (json['basicAmount'] != null) {
      amount = (json['basicAmount'] is num)
          ? (json['basicAmount'] as num).toDouble()
          : double.tryParse(json['basicAmount'].toString()) ?? 0.0;
    } else if (json['amount'] != null) {
      amount = (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(json['amount'].toString()) ?? 0.0;
    } else if (json['paymentData'] != null &&
        json['paymentData']['amount'] != null) {
      amount = (json['paymentData']['amount'] is num)
          ? (json['paymentData']['amount'] as num).toDouble()
          : double.tryParse(json['paymentData']['amount'].toString()) ?? 0.0;
    }

    final String amountPaidStr =
        amount > 0 ? '₹${amount.toStringAsFixed(2)}' : 'N/A';

    // Per Day Cost: Prefer backend provided perDayCharge if available
    double? backPerDay = json['perDayCharge'] != null ? double.tryParse(json['perDayCharge'].toString()) : null;
    double costPerDay = 0.0;
    
    if (backPerDay != null && backPerDay > 0) {
      costPerDay = backPerDay;
    } else if (validity > 0) {
      // Fallback: use totalAmount for calculation if it's partial payment, otherwise use current amount
      final double calcAmount = (json['isPartial'] == true && json['totalAmount'] != null) 
          ? (double.tryParse(json['totalAmount'].toString()) ?? amount)
          : amount;
      costPerDay = calcAmount / validity;
    }
    
    final String perDayCost =
        costPerDay > 0 ? '₹${costPerDay.toStringAsFixed(2)}' : 'N/A';

    // Parse rawRemainingAmount directly from backend
    double? rawRemaining;
    if (json['remainingAmount'] != null) {
      rawRemaining = (json['remainingAmount'] is num)
          ? (json['remainingAmount'] as num).toDouble()
          : double.tryParse(json['remainingAmount'].toString());
    }

    // Parse totalAmount
    double? totalAmt;
    if (json['totalAmount'] != null) {
      totalAmt = (json['totalAmount'] is num)
          ? (json['totalAmount'] as num).toDouble()
          : double.tryParse(json['totalAmount'].toString());
    }

    return SubscriptionHistory(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      planName: json['planName']?.toString() ??
          json['packageName']?.toString() ??
          'Registration Plan',
      paymentDate: paymentDate,
      amountPaid: amountPaidStr,
      perDayCost: perDayCost,
      validityDays: validityDays,
      expiryDate: expiryDate,
      headerStatus: headerStatus,
      footerStatus: SubscriptionStatus.success,
      isPartial: json['isPartial'] == true,
      paymentIntentId: json['paymentIntentId']?.toString(),
      invoiceId: json['invoiceId']?.toString(),
      segmentId: json['segmentId']?.toString(),
      partialTotalTarget:
          double.tryParse(json['partialTotalTarget']?.toString() ?? ''),
      partialPaymentsHistory: json['partialPaymentsHistory'] is List
          ? json['partialPaymentsHistory']
          : [],
      amountValue: amount,
      rawRemainingAmount: rawRemaining,
      totalAmount: totalAmt,
      totalAgreedAmount: json['totalAgreedAmount'] != null ? double.tryParse(json['totalAgreedAmount'].toString()) : null,
      baseAmount: json['baseAmount'] != null ? double.tryParse(json['baseAmount'].toString()) : null,
      gstAmount: json['gstAmount'] != null ? double.tryParse(json['gstAmount'].toString()) : null,
      baseRemaining: json['baseRemaining'] != null ? double.tryParse(json['baseRemaining'].toString()) : null,
      gstRemaining: json['gstRemaining'] != null ? double.tryParse(json['gstRemaining'].toString()) : null,
    );
  }

  static String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}
