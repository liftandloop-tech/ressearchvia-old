import 'package:spresearch_web/services/api.service.dart';

class UserPaymentService extends ApiService {
  // onInit handled by ApiService

  Future<Map<String, dynamic>> getUserPaymentHistory(
    String userId, {
    int page = 1,
    int pageSize = 200,
  }) async {
    try {
      final response = await get(
        '/segments/segment-payment-history/$userId?page=$page&pageSize=$pageSize',
      );

      if (response.status.hasError) {
        return Future.error(
          response.statusText ?? 'Error fetching payment history',
        );
      }

      return response.body;
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
