import 'package:get/get.dart';
import '../../services/snackbar.service.dart';
import 'error_message_handler.dart';

extension GetXSnackbarExtension on GetInterface {
  void showErrorSnackbar(
    String title,
    dynamic error, {
    String? customMessage,
    Duration? duration,
  }) {
    ErrorMessageHandler.logError(title, error);

    final message =
        customMessage ?? ErrorMessageHandler.getUserFriendlyMessage(error);

    SnackbarService.showError(
      message,
      title: title,
      duration: duration,
    );
  }

  void showSuccessSnackbar(
    String title,
    String message, {
    Duration? duration,
  }) {
    SnackbarService.showSuccess(
      message,
      title: title,
      duration: duration,
    );
  }
}
