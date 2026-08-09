import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';

class Loading extends StatelessWidget {
  final String? message;

  const Loading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTheme.cardTitleStyle),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionText;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.subtitleTextColor),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.sectionTitleStyle),
          const SizedBox(height: 8),
          Text(message, style: AppTheme.cardTitleStyle),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: AppTheme.primaryButtonStyle,
              child: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}

class ErrorDisplay extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.sectionTitleStyle),
          const SizedBox(height: 8),
          Text(message, style: AppTheme.cardTitleStyle),
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              style: AppTheme.primaryButtonStyle,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}
