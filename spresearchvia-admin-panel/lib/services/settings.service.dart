import 'package:get/get.dart';
import 'package:spresearch_web/services/api.service.dart';

import 'package:get/get_connect/http/src/multipart/form_data.dart';
import 'package:get/get_connect/http/src/multipart/multipart_file.dart';

class SettingsService extends ApiService {
  Future<Response> getSettings(String key) => get('/settings/$key');

  Future<Response> updateSettings(String key, Map<String, dynamic> value) =>
      post('/settings/$key', {'value': value});

  Future<Response> uploadQR(List<int> fileBytes, String fileName) async {
    final formData = FormData({
      'file': MultipartFile(fileBytes, filename: fileName),
    });
    return post('/settings/upload-qr', formData);
  }
}
