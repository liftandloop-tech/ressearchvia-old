import 'package:flutter/foundation.dart';
import '../../services/snackbar.service.dart';

void devSnack(String title, String message) {
  if (kDebugMode) {
    SnackbarService.showInfo(message, title: title);
  }
}
