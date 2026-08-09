import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_theme.dart';

/// A diagnostic dialog that checks Camera and Microphone permissions
/// before entering the Video KYC recorder. Blocks proceeding until
/// both permissions are granted.
class KycPermissionDialog extends StatefulWidget {
  /// Called when both permissions are confirmed granted.
  final VoidCallback onBothGranted;

  const KycPermissionDialog({super.key, required this.onBothGranted});

  @override
  State<KycPermissionDialog> createState() => _KycPermissionDialogState();
}

class _KycPermissionDialogState extends State<KycPermissionDialog> {
  PermissionStatus _cameraStatus = PermissionStatus.denied;
  PermissionStatus _micStatus = PermissionStatus.denied;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    final cam = await Permission.camera.status;
    final mic = await Permission.microphone.status;
    if (mounted) {
      setState(() {
        _cameraStatus = cam;
        _micStatus = mic;
      });
    }
  }

  Future<void> _requestPermissions() async {
    setState(() => _isChecking = true);

    // Request only those that are not yet granted
    if (!_cameraStatus.isGranted) {
      _cameraStatus = await Permission.camera.request();
    }
    if (!_micStatus.isGranted) {
      _micStatus = await Permission.microphone.request();
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }

    // If both granted after request, auto-proceed
    if (_cameraStatus.isGranted && _micStatus.isGranted) {
      Navigator.of(context).pop();
      widget.onBothGranted();
    }
  }

  Future<void> _openSettings() async {
    await openAppSettings();
    // After returning from settings, re-check status
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkCurrentStatus();
    if (mounted && _cameraStatus.isGranted && _micStatus.isGranted) {
      Navigator.of(context).pop();
      widget.onBothGranted();
    }
  }

  bool get _anyPermanentlyDenied =>
      _cameraStatus.isPermanentlyDenied || _micStatus.isPermanentlyDenied;

  bool get _bothGranted =>
      _cameraStatus.isGranted && _micStatus.isGranted;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.12),
            blurRadius: 24,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppTheme.primaryBlue,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          const Text(
            'Permissions Required',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xff111827),
            ),
          ),
          const SizedBox(height: 8),

          // Subtitle
          const Text(
            'Video KYC requires both camera and microphone access to record your verification video.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xff6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Permission status rows
          _buildPermissionRow(
            icon: Icons.videocam_rounded,
            label: 'Camera',
            status: _cameraStatus,
          ),
          const SizedBox(height: 12),
          _buildPermissionRow(
            icon: Icons.mic_rounded,
            label: 'Microphone',
            subLabel: 'Covers phone mic, wired earphones\n& Bluetooth neckbands / earbuds',
            status: _micStatus,
          ),

          const SizedBox(height: 20),

          // Divider
          const Divider(color: Color(0xffF3F4F6)),
          const SizedBox(height: 16),

          // Action buttons
          if (_isChecking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: CircularProgressIndicator(
                color: AppTheme.primaryBlue,
                strokeWidth: 2.5,
              ),
            )
          else if (_anyPermanentlyDenied) ...[
            _buildActionButton(
              label: 'Open App Settings',
              icon: Icons.settings_rounded,
              onTap: _openSettings,
              isPrimary: true,
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
              isPrimary: false,
            ),
          ] else ...[
            _buildActionButton(
              label: _bothGranted ? 'Proceed to Record' : 'Grant Access',
              icon: _bothGranted ? Icons.videocam_rounded : Icons.lock_open_rounded,
              onTap: _bothGranted
                  ? () {
                      Navigator.of(context).pop();
                      widget.onBothGranted();
                    }
                  : _requestPermissions,
              isPrimary: true,
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop(),
              isPrimary: false,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String label,
    String? subLabel,
    required PermissionStatus status,
  }) {
    final bool granted = status.isGranted;
    final bool permanentlyDenied = status.isPermanentlyDenied;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (granted) {
      statusColor = const Color(0xff16A34A);
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Allowed';
    } else if (permanentlyDenied) {
      statusColor = const Color(0xffDC2626);
      statusIcon = Icons.block_rounded;
      statusText = 'Blocked';
    } else {
      statusColor = const Color(0xffF59E0B);
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'Not Allowed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: granted
            ? const Color(0xffF0FDF4)
            : permanentlyDenied
                ? const Color(0xffFEF2F2)
                : const Color(0xffFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: granted
              ? const Color(0xff86EFAC)
              : permanentlyDenied
                  ? const Color(0xffFCA5A5)
                  : const Color(0xffFDE68A),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff111827),
                  ),
                ),
                if (subLabel != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff9CA3AF),
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.primaryBlue : const Color(0xffF3F4F6),
          foregroundColor: isPrimary ? Colors.white : const Color(0xff6B7280),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
