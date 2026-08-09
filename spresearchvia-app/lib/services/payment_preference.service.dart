import 'package:get_storage/get_storage.dart';
import '../core/models/payment.options.dart';

class PaymentPreferenceService {
  static const String _paymentMethodKey = 'preferred_payment_method';
  final _storage = GetStorage();

  void savePaymentMethod(PaymentMethod method) {
    _storage.write(_paymentMethodKey, method.name);
  }

  PaymentMethod? getPaymentMethod() {
    final methodName = _storage.read<String>(_paymentMethodKey);
    if (methodName == null) return null;
    
    return PaymentMethod.values.firstWhere(
      (m) => m.name == methodName,
      orElse: () => PaymentMethod.razorpay,
    );
  }

  void clearPaymentMethod() {
    _storage.remove(_paymentMethodKey);
  }

  String getMethodForRazorpay(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.razorpay:
        return 'online';
      case PaymentMethod.bankTransfer:
        return 'offline';
      case PaymentMethod.adminEntitlement:
        return 'admin';
    }
  }
}
