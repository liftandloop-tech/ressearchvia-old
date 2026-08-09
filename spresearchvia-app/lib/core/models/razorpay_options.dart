import '../config/razorpay.config.dart';
import 'payment.options.dart';

class RazorpayOptions {
  final String orderId;
  final double amount;
  final String planName;
  final String userEmail;
  final String userPhone;
  final String userName;
  final PaymentMethod? hiddenMethod;

  RazorpayOptions({
    required this.orderId,
    required this.amount,
    required this.planName,
    required this.userEmail,
    required this.userPhone,
    required this.userName,
    this.hiddenMethod,
  });

  Map<String, dynamic> toMap() {
    final options = {
      'key': RazorpayConfig.keyId,
      'amount': (amount * 100).round(), // Amount must be in paise (Rupees * 100)
      'name': RazorpayConfig.companyName,
      'order_id': orderId,
      'description': planName,
      'timeout': RazorpayConfig.timeout,
      'prefill': {
        'contact': userPhone.isNotEmpty ? userPhone : '9999999999',
        'email': userEmail.isNotEmpty ? userEmail : 'user@example.com',
        'name': userName.isNotEmpty ? userName : 'User'
      },
      'theme': {'color': RazorpayConfig.themeColor},
    };

    // hiddenMethod filtering removed as we now support full Razorpay suite or Bank Transfer
    if (hiddenMethod != null) {
      // Logic for specific hiding removed. 
      // If we wanted to hide wallets for Card payments we could add logic here, 
      // but currently enum only supports 'razorpay' (all) or 'bankTransfer' (offline).
    }

    return options;
  }
}
