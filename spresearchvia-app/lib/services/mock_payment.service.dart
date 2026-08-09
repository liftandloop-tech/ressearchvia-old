import 'dart:async';
import 'dart:math';
import '../widgets/payment_method_card.dart';

class MockPaymentService {
  static final MockPaymentService _instance = MockPaymentService._internal();
  factory MockPaymentService() => _instance;
  MockPaymentService._internal();

  final Duration _networkDelay = const Duration(milliseconds: 800);

  Future<PaymentMethodData?> getSavedPaymentMethod() async {
    await Future.delayed(_networkDelay);

    final random = Random();
    final paymentTypes = [
      _generateVisaCard(),
      _generateMastercardCard(),
      _generateRupayCard(),
      _generateUPI(),
      _generateNetBanking(),
    ];

    return random.nextBool()
        ? paymentTypes[random.nextInt(paymentTypes.length)]
        : paymentTypes[0];
  }

  Future<List<PaymentMethodData>> getAllPaymentMethods() async {
    await Future.delayed(_networkDelay);

    return [_generateVisaCard(), _generateMastercardCard(), _generateUPI()];
  }

  Future<bool> savePaymentMethod(PaymentMethodData paymentMethod) async {
    await Future.delayed(_networkDelay);

    return Random().nextInt(10) < 9;
  }

  Future<bool> deletePaymentMethod(String methodId) async {
    await Future.delayed(_networkDelay);

    return Random().nextInt(20) < 19;
  }

  Future<bool> setDefaultPaymentMethod(String methodId) async {
    await Future.delayed(_networkDelay);

    return Random().nextInt(20) < 19;
  }

  PaymentMethodData _generateVisaCard() {
    final lastDigits = ['4532', '4916', '4485', '4024'];
    final expiry = _generateExpiry();
    return PaymentMethodData(
      type: PaymentMethodType.visa,
      lastFourDigits: lastDigits[Random().nextInt(lastDigits.length)],
      expiryDate: expiry,
      isSelected: true,
    );
  }

  PaymentMethodData _generateMastercardCard() {
    final lastDigits = ['5412', '5510', '5234', '5678'];
    final expiry = _generateExpiry();
    return PaymentMethodData(
      type: PaymentMethodType.mastercard,
      lastFourDigits: lastDigits[Random().nextInt(lastDigits.length)],
      expiryDate: expiry,
      isSelected: false,
    );
  }

  PaymentMethodData _generateRupayCard() {
    final lastDigits = ['6077', '6521', '6789', '6234'];
    final expiry = _generateExpiry();
    return PaymentMethodData(
      type: PaymentMethodType.rupay,
      lastFourDigits: lastDigits[Random().nextInt(lastDigits.length)],
      expiryDate: expiry,
      isSelected: false,
    );
  }

  PaymentMethodData _generateUPI() {
    final upiIds = ['user@paytm', 'john@oksbi', 'customer@ybl', 'payment@axl'];
    return PaymentMethodData(
      type: PaymentMethodType.upi,
      upiId: upiIds[Random().nextInt(upiIds.length)],
      isSelected: false,
    );
  }

  PaymentMethodData _generateNetBanking() {
    final banks = [
      'HDFC Bank',
      'ICICI Bank',
      'State Bank of India',
      'Axis Bank',
    ];
    return PaymentMethodData(
      type: PaymentMethodType.netbanking,
      bankName: banks[Random().nextInt(banks.length)],
      isSelected: false,
    );
  }

  String _generateExpiry() {
    final now = DateTime.now();
    final months = ['01', '03', '06', '09', '12'];
    final month = months[Random().nextInt(months.length)];
    final year = (now.year + Random().nextInt(5)).toString().substring(2);
    return '$month/$year';
  }

  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String paymentMethodId,
    required String planId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final success = Random().nextInt(100) < 85;

    if (success) {
      return {
        'success': true,
        'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}',
        'amount': amount,
        'status': 'completed',
        'message': 'Payment processed successfully',
      };
    } else {
      return {
        'success': false,
        'status': 'failed',
        'message': 'Payment processing failed. Please try again.',
      };
    }
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory() async {
    await Future.delayed(_networkDelay);

    final now = DateTime.now();
    return [
      {
        'id': 'PAY001',
        'amount': 1500.0,
        'date': now.subtract(const Duration(days: 30)),
        'status': 'success',
        'planName': 'Index Option - Splendid Plan',
        'transactionId': 'TXN1234567890',
      },
      {
        'id': 'PAY002',
        'amount': 1500.0,
        'date': now.subtract(const Duration(days: 60)),
        'status': 'success',
        'planName': 'Index Option - Premium Plan',
        'transactionId': 'TXN0987654321',
      },
      {
        'id': 'PAY003',
        'amount': 2000.0,
        'date': now.subtract(const Duration(days: 90)),
        'status': 'success',
        'planName': 'Index Option - Elite Plan',
        'transactionId': 'TXN1122334455',
      },
    ];
  }

  Future<Map<String, dynamic>> getInvoice(String transactionId) async {
    await Future.delayed(_networkDelay);

    return {
      'invoiceId': 'INV${DateTime.now().millisecondsSinceEpoch}',
      'transactionId': transactionId,
      'generatedAt': DateTime.now().toIso8601String(),
      'downloadUrl': 'https://example.com/invoice.pdf',
    };
  }
}
