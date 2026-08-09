import 'package:get/get.dart';
import 'package:spresearch_web/services/api.service.dart';

class NotificationService extends ApiService {
  Future<Response> sendBulkEmail(FormData data) {
    return post('/notifications/send-bulk-email', data);
  }

  Future<Response> getHtmlPreview(String message) {
    return post('/notifications/preview-email', {'message': message});
  }

  Future<Response> getScheduledNotifications() {
    return get('/notifications/scheduled');
  }

  Future<Response> deleteScheduledNotification(String id) {
    return delete('/notifications/scheduled/$id');
  }

  Future<Response> getNotificationHistory() {
    return get('/notifications/history');
  }
}
