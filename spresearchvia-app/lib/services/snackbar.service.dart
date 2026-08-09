import 'package:flutter/material.dart';
import 'package:get/get.dart' as getx;
import '../core/theme/app_theme.dart';
import '../core/utils/error_message_handler.dart';

enum SnackbarType { success, error, warning, info }

abstract class SnackbarService {
  static OverlayEntry? _currentSnackbar;

  static void show(
    String message, {
    String? title,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 1),
    VoidCallback? onTap,
    String? actionTitle,
    VoidCallback? actionOnTap,
    BuildContext? context,
  }) {
    _dismiss();

    BuildContext? overlayContext = context ?? getx.Get.overlayContext ?? getx.Get.context;

    OverlayState? overlay;
    if (overlayContext != null) {
      overlay = Overlay.maybeOf(overlayContext);
    }
    
    // Fallback to global navigator overlay
    overlay ??= getx.Get.key.currentState?.overlay;

    if (overlay == null) {
      debugPrint('SnackbarService: No overlay found, falling back to Get.rawSnackbar');
      getx.Get.rawSnackbar(
        title: title,
        message: message,
        backgroundColor: backgroundColor ?? AppTheme.primaryBlueDark,
        snackPosition: getx.SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: icon != null ? Icon(icon, color: Colors.white) : const Icon(Icons.notifications_outlined, color: Colors.white),
        duration: duration,
        onTap: onTap != null ? (_) => onTap() : null,
      );
      return;
    }

    _currentSnackbar = OverlayEntry(
      builder: (context) => _SnackbarWidget(
        message: message,
        title: title,
        icon: icon ?? Icons.notifications_outlined,
        backgroundColor: backgroundColor ?? AppTheme.primaryBlueDark,
        duration: duration,
        onTap: onTap,
        actionTitle: actionTitle,
        actionOnTap: actionOnTap,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_currentSnackbar!);
  }

  static void showSuccess(
    String message, {
    String? title,
    Duration? duration,
    BuildContext? context,
  }) {
    show(
      message,
      title: title,
      icon: Icons.check_circle_rounded,
      backgroundColor: AppTheme.success,
      duration: duration ?? const Duration(seconds: 1),
      context: context,
    );
  }

  static void showError(
    String message, {
    String? title,
    Duration? duration,
    BuildContext? context,
  }) {
    show(
      message,
      title: title,
      icon: Icons.error_rounded,
      backgroundColor: AppTheme.error,
      duration: duration ?? const Duration(milliseconds: 1500),
      context: context,
    );
  }

  static void showErrorFromException(
    dynamic error, {
    String? title,
    String? customMessage,
    Duration? duration,
  }) {
    ErrorMessageHandler.logError(title ?? 'Error', error);

    final message =
        customMessage ?? ErrorMessageHandler.getUserFriendlyMessage(error);

    showError(message, title: title, duration: duration);
  }

  static void showWarning(
    String message, {
    String? title,
    Duration? duration,
    BuildContext? context,
  }) {
    show(
      message,
      title: title,
      icon: Icons.warning_rounded,
      backgroundColor: AppTheme.warning,
      duration: duration ?? const Duration(seconds: 1),
      context: context,
    );
  }

  static void showInfo(
    String message, {
    String? title,
    Duration? duration,
    BuildContext? context,
  }) {
    show(
      message,
      title: title,
      icon: Icons.info_rounded,
      backgroundColor: AppTheme.primaryBlueDark,
      duration: duration ?? const Duration(seconds: 1),
      context: context,
    );
  }

  static void showLoading(String message, {String? title}) {
    _dismiss();

    final overlayState = getx.Get.overlayContext;
    if (overlayState == null) return;

    _currentSnackbar = OverlayEntry(
      builder: (context) => _SnackbarWidget(
        message: message,
        title: title,
        icon: Icons.hourglass_empty_rounded,
        backgroundColor: AppTheme.primaryBlueDark,
        duration: const Duration(days: 365),
        showLoading: true,
        onDismiss: _dismiss,
      ),
    );

    Overlay.of(overlayState).insert(_currentSnackbar!);
  }

  static void _dismiss() {
    _currentSnackbar?.remove();
    _currentSnackbar = null;
  }

  static void closeAll() => _dismiss();

  static void close() => _dismiss();

  static void showSnackbar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    show(message, duration: duration);
  }

  static void showSuccessContext(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    showSuccess(message, duration: duration);
  }

  static void showErrorContext(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 1500),
    SnackBarAction? action,
  }) {
    showError(message, duration: duration);
  }

  static void showErrorFromExceptionContext(
    BuildContext context,
    dynamic error, {
    String? customMessage,
    Duration duration = const Duration(milliseconds: 1500),
    SnackBarAction? action,
  }) {
    showErrorFromException(
      error,
      customMessage: customMessage,
      duration: duration,
    );
  }

  static void showWarningContext(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    showWarning(message, duration: duration);
  }

  static void showInfoContext(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 1),
    SnackBarAction? action,
  }) {
    showInfo(message, duration: duration);
  }
}

class _SnackbarWidget extends StatefulWidget {
  final String message;
  final String? title;
  final IconData icon;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback? onTap;
  final String? actionTitle;
  final VoidCallback? actionOnTap;
  final VoidCallback onDismiss;
  final bool showLoading;

  const _SnackbarWidget({
    required this.message,
    this.title,
    required this.icon,
    required this.backgroundColor,
    required this.duration,
    this.onTap,
    this.actionTitle,
    this.actionOnTap,
    required this.onDismiss,
    this.showLoading = false,
  });

  @override
  State<_SnackbarWidget> createState() => _SnackbarWidgetState();
}

class _SnackbarWidgetState extends State<_SnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 50),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    if (!widget.showLoading) {
      Future.delayed(widget.duration, _dismiss);
    }
  }

  void _dismiss() async {
    if (!mounted) return;

    await _controller.reverse(
      from: _controller.value,
    );
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: widget.onTap ?? _dismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: widget.backgroundColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: widget.showLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(widget.icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null && widget.title!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                widget.title!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ),
                          Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.actionTitle != null && widget.actionOnTap != null)
                      TextButton(
                        onPressed: () {
                          _dismiss();
                          widget.actionOnTap!();
                        },
                        child: Text(
                          widget.actionTitle!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    if (!widget.showLoading)
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
