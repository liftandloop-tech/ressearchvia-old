import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:web/web.dart' as web;
import '../../config/app.config.dart';

/// Complete in-browser Video KYC Camera Recorder
/// Built exclusively for live camera recording (no pre-recorded upload option for applicants).
/// If the device does not have a camera, a helpful popup instructs the applicant
/// to continue via mobile or a laptop with camera support.
class VideoKycRecorderDialog extends StatefulWidget {
  final String applicantName;
  final Future<bool> Function(Uint8List bytes, String filename) onVideoRecorded;

  const VideoKycRecorderDialog({
    super.key,
    required this.applicantName,
    required this.onVideoRecorded,
  });

  /// Opens the recorder dialog or shows the no-camera popup if hardware is absent.
  static Future<void> showRecorder({
    required BuildContext context,
    required String applicantName,
    required Future<bool> Function(Uint8List bytes, String filename) onVideoRecorded,
  }) async {
    bool hasCamera = true;
    if (kIsWeb) {
      try {
        final devicesPromise = web.window.navigator.mediaDevices.enumerateDevices();
        final devices = await devicesPromise.toDart;
        final list = devices.toDart;
        hasCamera = list.any((d) => d.kind == 'videoinput');
      } catch (_) {
        hasCamera = true; // Attempt in getUserMedia if device list not exposed before permission
      }
    }

    if (!context.mounted) return;

    if (!hasCamera) {
      showNoCameraDialog(context);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (recCtx) => VideoKycRecorderDialog(
        applicantName: applicantName,
        onVideoRecorded: onVideoRecorded,
      ),
    );
  }

  /// Backward-compatible alias for existing callers
  static Future<void> showChoice({
    required BuildContext context,
    required String applicantName,
    required Future<bool> Function(Uint8List bytes, String filename) onVideoRecorded,
    VoidCallback? onFallbackUpload,
  }) {
    return showRecorder(
      context: context,
      applicantName: applicantName,
      onVideoRecorded: onVideoRecorded,
    );
  }

  /// Popup shown when no camera is detected on the applicant's device.
  static void showNoCameraDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.videocam_off_rounded, color: Color(0xFFD97706), size: 28),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Text(
                'Camera Required for Video KYC',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your device does not have a camera or does not support live video recording.',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please continue via mobile or a laptop which supports camera or video recording.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'You can copy your application link below and open it on your smartphone or a laptop with a webcam.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final link = Uri.base.toString();
              Clipboard.setData(ClipboardData(text: link));
              Get.snackbar(
                'Application Link Copied',
                'Link copied to clipboard! Open it on your mobile device to complete Video KYC.',
                backgroundColor: const Color(0xFFECFDF5),
                colorText: const Color(0xFF065F46),
                icon: const Icon(Icons.check_circle, color: Color(0xFF059669)),
              );
              Navigator.of(ctx).pop();
            },
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy Application Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<VideoKycRecorderDialog> createState() => _VideoKycRecorderDialogState();
}

class _VideoKycRecorderDialogState extends State<VideoKycRecorderDialog> {
  bool _isInitializing = true;
  bool _hasCamera = false;
  bool _isDeviceCameraMissing = false;
  String _errorMessage = '';
  bool _isCountingDown = false;
  int _countdown = 3;
  bool _isRecording = false;
  bool _hasRecorded = false;
  int _secondsRecorded = 0;
  Timer? _timer;
  Timer? _countdownTimer;

  bool _isSubmitting = false;
  bool _hasSubmittedSuccess = false;
  double _uploadProgress = 0.0;
  String _uploadStatusText = 'Preparing upload...';
  Timer? _uploadTimer;
  String _submissionError = '';
  String _recordedMimeType = 'video/webm';

  bool _isHindi = false;

  web.MediaStream? _mediaStream;
  web.MediaRecorder? _mediaRecorder;
  final List<web.Blob> _recordedChunks = [];
  Uint8List? _recordedBytes;

  late final String _previewViewId;
  String _playbackViewId = '';
  web.HTMLVideoElement? _previewVideoElement;
  web.HTMLVideoElement? _playbackVideoElement;

  @override
  void initState() {
    super.initState();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _previewViewId = 'kyc-preview-$timestamp';
    _playbackViewId = 'kyc-playback-$timestamp';

    if (kIsWeb) {
      _initCamera();
    } else {
      _errorMessage = 'In-browser recording is supported in modern web browsers.';
      _isInitializing = false;
    }
  }

  Future<void> _initCamera() async {
    try {
      final nav = web.window.navigator;
      final mediaDevices = nav.mediaDevices;

      web.MediaStream? stream;
      // 1. Try front/user-facing camera with audio
      try {
        final constraints = web.MediaStreamConstraints(
          video: {'facingMode': 'user'}.jsify()!,
          audio: true.toJS,
        );
        stream = await mediaDevices.getUserMedia(constraints).toDart;
      } catch (_) {
        // 2. Fallback to any connected video input with audio
        try {
          final constraints = web.MediaStreamConstraints(
            video: true.toJS,
            audio: true.toJS,
          );
          stream = await mediaDevices.getUserMedia(constraints).toDart;
        } catch (_) {
          // 3. Fallback to video only
          final constraints = web.MediaStreamConstraints(
            video: true.toJS,
            audio: false.toJS,
          );
          stream = await mediaDevices.getUserMedia(constraints).toDart;
        }
      }

      _mediaStream = stream;

      _previewVideoElement = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = stream
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.transform = 'scaleX(-1)';

      _previewVideoElement!.setAttribute('playsinline', 'true');

      ui_web.platformViewRegistry.registerViewFactory(
        _previewViewId,
        (int viewId) => _previewVideoElement!,
      );

      if (mounted) {
        setState(() {
          _hasCamera = true;
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('Camera access error: $e');
      final errStr = e.toString().toLowerCase();
      final isHardwareMissing = errStr.contains('notfound') ||
          errStr.contains('not found') ||
          errStr.contains('device') ||
          errStr.contains('overconstrained');

      if (mounted) {
        setState(() {
          _hasCamera = false;
          _isInitializing = false;
          _isDeviceCameraMissing = isHardwareMissing;
          if (isHardwareMissing) {
            _errorMessage = 'Your device does not support a camera or video recording. Please continue via mobile or a laptop which supports camera or video recording.';
          } else {
            _errorMessage = 'Camera access was blocked by browser permissions. Please allow camera permissions in your browser URL bar or settings to continue.';
          }
        });
      }
    }
  }

  void _triggerCountdownAndRecord() {
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
      _submissionError = '';
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _startRecording();
      }
    });
  }

  void _startRecording() {
    if (_mediaStream == null) return;
    try {
      _recordedChunks.clear();
      _secondsRecorded = 0;
      _submissionError = '';

      String mimeType = 'video/webm;codecs=vp8,opus';
      if (!web.MediaRecorder.isTypeSupported(mimeType)) {
        mimeType = 'video/webm';
        if (!web.MediaRecorder.isTypeSupported(mimeType)) {
          mimeType = 'video/mp4';
          if (!web.MediaRecorder.isTypeSupported(mimeType)) {
            mimeType = '';
          }
        }
      }
      _recordedMimeType = mimeType.isNotEmpty ? mimeType : 'video/webm';

      final options = mimeType.isNotEmpty
          ? web.MediaRecorderOptions(mimeType: mimeType)
          : web.MediaRecorderOptions();

      _mediaRecorder = web.MediaRecorder(_mediaStream!, options);

      _mediaRecorder!.ondataavailable = ((web.BlobEvent event) {
        if (event.data.size > 0) {
          _recordedChunks.add(event.data);
        }
      }).toJS;

      _mediaRecorder!.onstop = ((web.Event event) {
        _processRecordedVideo();
      }).toJS;

      _mediaRecorder!.start(1000);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (mounted) {
          setState(() {
            _secondsRecorded++;
          });
          // Auto-stop at 45 seconds max
          if (_secondsRecorded >= 45) {
            _stopRecording();
          }
        }
      });

      setState(() {
        _isRecording = true;
        _hasRecorded = false;
      });
    } catch (e) {
      Get.snackbar('Recording Error', 'Failed to start video recording: $e');
    }
  }

  void _stopRecording() {
    if (_mediaRecorder != null && _isRecording) {
      if (_secondsRecorded < 3) {
        Get.snackbar(
          'Recording Too Short',
          'Please record for at least 3 seconds.',
          backgroundColor: Colors.orange.withValues(alpha: 0.15),
        );
        return;
      }
      _timer?.cancel();
      _mediaRecorder!.stop();
      setState(() {
        _isRecording = false;
      });
    }
  }

  Future<void> _processRecordedVideo() async {
    if (_recordedChunks.isEmpty) {
      if (mounted) {
        setState(() {
          _submissionError = 'No video data captured. Please re-record.';
        });
      }
      return;
    }
    try {
      final jsChunks = _recordedChunks.toJS;
      final blob = web.Blob(jsChunks);
      final arrayBufferPromise = blob.arrayBuffer();
      final arrayBuffer = await arrayBufferPromise.toDart;
      final uint8List = arrayBuffer.toDart.asUint8List();

      _recordedBytes = uint8List;

      final videoUrl = web.URL.createObjectURL(blob);
      _playbackVideoElement = web.HTMLVideoElement()
        ..autoplay = true
        ..controls = true
        ..src = videoUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'contain';

      _playbackVideoElement!.setAttribute('playsinline', 'true');

      // Unique view ID per recording avoids registration collision on re-record
      _playbackViewId = 'kyc-playback-${DateTime.now().millisecondsSinceEpoch}-${DateTime.now().microsecond}';
      ui_web.platformViewRegistry.registerViewFactory(
        _playbackViewId,
        (int viewId) => _playbackVideoElement!,
      );

      if (mounted) {
        setState(() {
          _hasRecorded = true;
          _submissionError = '';
        });
      }
    } catch (e) {
      debugPrint('Error processing video blob: $e');
      if (mounted) {
        setState(() {
          _submissionError = 'Error processing recorded video. Please re-record.';
        });
      }
    }
  }

  void _reRecord() {
    setState(() {
      _hasRecorded = false;
      _recordedBytes = null;
      _secondsRecorded = 0;
      _submissionError = '';
    });
  }

  Future<void> _submitVideo() async {
    debugPrint('[VideoKYC] Submit KYC video button pressed! Bytes: ${_recordedBytes?.length}, mime: $_recordedMimeType');
    if (_isSubmitting) return;

    if (_recordedBytes == null || _recordedBytes!.isEmpty) {
      setState(() {
        _submissionError = 'Please record your video first before submitting.';
      });
      return;
    }

    if (_secondsRecorded < 3) {
      setState(() {
        _submissionError = 'Recording must be at least 3 seconds long.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _uploadProgress = 0.15;
      _uploadStatusText = 'Encrypting & transferring KYC video...';
      _submissionError = '';
    });

    // Start progress timer to smoothly advance progress while uploading
    _uploadTimer?.cancel();
    _uploadTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted || !_isSubmitting) {
        t.cancel();
        return;
      }
      setState(() {
        if (_uploadProgress < 0.88) {
          _uploadProgress += 0.04;
          if (_uploadProgress > 0.45 && _uploadProgress < 0.70) {
            _uploadStatusText = 'Uploading KYC video payload...';
          } else if (_uploadProgress >= 0.70) {
            _uploadStatusText = 'Finalizing verification record...';
          }
        }
      });
    });

    try {
      final isMp4 = _recordedMimeType.contains('mp4');
      final ext = isMp4 ? 'mp4' : 'webm';
      final filename = 'kyc_video_${DateTime.now().millisecondsSinceEpoch}.$ext';
      debugPrint('[VideoKYC] Invoking onVideoRecorded: $filename (${_recordedBytes!.length} bytes)');

      final success = await widget.onVideoRecorded(_recordedBytes!, filename);
      _uploadTimer?.cancel();

      if (success) {
        if (mounted) {
          setState(() {
            _uploadProgress = 1.0;
            _uploadStatusText = 'KYC Video Uploaded Successfully!';
            _hasSubmittedSuccess = true;
          });
          await Future.delayed(const Duration(milliseconds: 900));
          _cleanUp();
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _uploadProgress = 0.0;
            _submissionError = 'Video upload failed. Please verify your connection and try again.';
          });
        }
      }
    } catch (e) {
      _uploadTimer?.cancel();
      debugPrint('[VideoKYC] Error in _submitVideo: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _uploadProgress = 0.0;
          _submissionError = 'Upload error: $e';
        });
      }
    }
  }

  void _cleanUp() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    _uploadTimer?.cancel();
    if (_mediaStream != null) {
      try {
        final tracks = _mediaStream!.getTracks().toDart;
        for (final track in tracks) {
          track.stop();
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _cleanUp();
    super.dispose();
  }

  String _formatTimer(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _companyName {
    final raw = AppConfig.appName.replaceAll(' Admin Panel', '').trim();
    if (raw.toLowerCase().contains('bizx')) return 'BizX Research';
    if (raw.toLowerCase().contains('future')) return 'Future Pride Research';
    if (raw.toLowerCase().contains('researchvia') || raw.toLowerCase().contains('spresearch')) return 'ResearchVia';
    return raw.isNotEmpty ? raw : 'the Company';
  }

  String get _declarationText {
    final name = widget.applicantName.trim().isNotEmpty ? widget.applicantName.trim() : 'Applicant';
    final company = _companyName;
    if (_isHindi) {
      return 'मैं $name, $company में रोज़गार के लिए आवेदन कर रहा/रही हूँ और पुष्टि करता/करती हूँ कि मेरे द्वारा दिए गए सभी दस्तावेज़ एवं विवरण पूर्णतः सत्य हैं।';
    }
    return 'I, $name, am applying for employment at $company. I confirm that all details and documents submitted by me are true and authentic.';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 24, vertical: isMobile ? 12 : 24),
      child: Container(
        width: isMobile ? double.infinity : 680,
        height: isMobile ? size.height * 0.92 : 740,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // 1. Camera Live Stream or Playback View or No-Camera Screen
            if (_isInitializing) ...[
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.blueAccent),
                    SizedBox(height: 16),
                    Text('Accessing Camera...', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              )
            ] else if (!_hasCamera) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_off_rounded, color: Color(0xFFFBBF24), size: 48),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Camera Required for Video KYC',
                        style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Text(
                          _isDeviceCameraMissing
                              ? 'Your device does not support a camera or video recording. Please continue via mobile or a laptop which supports camera or video recording.'
                              : _errorMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13.5, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _cleanUp();
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white70,
                              side: const BorderSide(color: Colors.white30),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Close'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              final link = Uri.base.toString();
                              Clipboard.setData(ClipboardData(text: link));
                              Get.snackbar(
                                'Application Link Copied',
                                'Link copied! Open on your mobile phone to complete Video KYC.',
                                backgroundColor: const Color(0xFFECFDF5),
                                colorText: const Color(0xFF065F46),
                                icon: const Icon(Icons.check_circle, color: Color(0xFF059669)),
                              );
                              _cleanUp();
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Application Link'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          if (!_isDeviceCameraMissing)
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isInitializing = true;
                                });
                                _initCamera();
                              },
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Retry Camera Access'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            ] else if (_hasRecorded) ...[
              // Video Playback review bounded between header and bottom controls
              Positioned(
                top: 56,
                bottom: 155,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black,
                  child: HtmlElementView(viewType: _playbackViewId),
                ),
              ),
            ] else ...[
              // Live camera feed bounded between header and bottom controls
              Positioned(
                top: 56,
                bottom: 155,
                left: 0,
                right: 0,
                child: Container(
                  color: Colors.black,
                  child: HtmlElementView(viewType: _previewViewId),
                ),
              ),
            ],

            // 2. Countdown Overlay
            if (_isCountingDown)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_countdown',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 108,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Prepare to read the declaration aloud...',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Top Header Bar (Close button + Live Timer + Language toggle)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 24),
                      onPressed: () {
                        _cleanUp();
                        Navigator.of(context).pop();
                      },
                    ),
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.4),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatTimer(_secondsRecorded),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isHindi = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: !_isHindi ? Colors.white : Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'EN',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: !_isHindi ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => _isHindi = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isHindi ? Colors.white : Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'HI',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: _isHindi ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Declaration Script Card (Top Overlay below Header)
            if (_hasCamera && !_hasRecorded)
              Positioned(
                top: 60,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.record_voice_over, color: Color(0xFF60A5FA), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _isHindi ? 'कृपया इस वाक्य को कैमरे के सामने बोलें:' : 'Please read this declaration aloud:',
                            style: const TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _declarationText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 5. Bottom Controls Bar
            if (_hasCamera)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                        Colors.black,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Error display if submission or recording failed
                      if (_submissionError.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _submissionError,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (!_hasRecorded) ...[
                        // RECORD / STOP BUTTON
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (!_isRecording && !_isCountingDown) ...[
                              GestureDetector(
                                onTap: _triggerCountdownAndRecord,
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    color: Colors.transparent,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFFEF4444),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.videocam, color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              ),
                            ] else if (_isRecording) ...[
                              GestureDetector(
                                onTap: _stopRecording,
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    color: Colors.transparent,
                                  ),
                                  padding: const EdgeInsets.all(18),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      color: const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isRecording
                              ? 'Tap red square to stop recording'
                              : 'Tap red circle to start recording (Min 5 seconds)',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ] else ...[
                        // REVIEW / SUBMIT CONTROLS
                        const Text(
                          'Review your recorded video. Is your face and voice clear?',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSubmitting ? null : _reRecord,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('Re-record'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _submitVideo,
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Icon(
                                      _hasSubmittedSuccess ? Icons.check_circle : Icons.check_circle_outline,
                                      size: 18,
                                    ),
                              label: Text(
                                _isSubmitting
                                    ? 'Uploading KYC Video...'
                                    : _hasSubmittedSuccess
                                        ? 'Video KYC Submitted!'
                                        : 'Submit KYC Video',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _hasSubmittedSuccess ? const Color(0xFF059669) : const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            // 6. Prominent Upload Progress Loader Overlay
            if (_isSubmitting)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.88),
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 440),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _hasSubmittedSuccess
                              ? const Color(0xFF10B981).withValues(alpha: 0.5)
                              : const Color(0xFF38BDF8).withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _hasSubmittedSuccess
                                  ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                  : const Color(0xFF38BDF8).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: _hasSubmittedSuccess
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48)
                                : const Icon(Icons.cloud_upload_rounded, color: Color(0xFF38BDF8), size: 48),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            _hasSubmittedSuccess ? 'Upload Completed!' : 'Uploading KYC Video',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _uploadStatusText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 22),
                          // Linear progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: _uploadProgress > 0 ? _uploadProgress : null,
                              minHeight: 10,
                              backgroundColor: const Color(0xFF334155),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _hasSubmittedSuccess ? const Color(0xFF10B981) : const Color(0xFF38BDF8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _recordedBytes != null
                                    ? '${(_recordedBytes!.length / (1024 * 1024)).toStringAsFixed(2)} MB'
                                    : '',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Secure encrypted upload • Please do not close',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
