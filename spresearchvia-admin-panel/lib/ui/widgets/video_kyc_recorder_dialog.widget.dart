import 'dart:async';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:web/web.dart' as web;
import '../../config/app.config.dart';

/// Complete in-browser Video KYC Camera Recorder
/// Built to mirror the mobile app Video KYC experience with live camera preview,
/// script declaration prompt, countdown, live timer, and review playback.
class VideoKycRecorderDialog extends StatefulWidget {
  final String applicantName;
  final Function(Uint8List bytes, String filename) onVideoRecorded;
  final VoidCallback onFallbackUpload;

  const VideoKycRecorderDialog({
    super.key,
    required this.applicantName,
    required this.onVideoRecorded,
    required this.onFallbackUpload,
  });

  /// Opens the choice dialog or recorder
  static Future<void> showChoice({
    required BuildContext context,
    required String applicantName,
    required Function(Uint8List bytes, String filename) onVideoRecorded,
    required VoidCallback onFallbackUpload,
  }) async {
    // Check if camera device is available
    bool hasCamera = true;
    if (kIsWeb) {
      try {
        final devicesPromise = web.window.navigator.mediaDevices.enumerateDevices();
        final devices = await devicesPromise.toDart;
        final list = devices.toDart;
        hasCamera = list.any((d) => d.kind == 'videoinput');
      } catch (_) {
        hasCamera = true; // fallback to attempting getUserMedia
      }
    }

    if (!context.mounted) return;

    if (!hasCamera) {
      // PC without camera detected: directly offer file upload
      _showNoCameraPrompt(context, onFallbackUpload);
      return;
    }

    // Camera is available (Mobile phone, Laptop, PC with webcam)
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _VideoKycOptionDialog(
        applicantName: applicantName,
        onRecordSelected: () {
          Navigator.of(ctx).pop();
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (recCtx) => VideoKycRecorderDialog(
              applicantName: applicantName,
              onVideoRecorded: onVideoRecorded,
              onFallbackUpload: onFallbackUpload,
            ),
          );
        },
        onUploadSelected: () {
          Navigator.of(ctx).pop();
          onFallbackUpload();
        },
      ),
    );
  }

  static void _showNoCameraPrompt(BuildContext context, VoidCallback onFallbackUpload) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.videocam_off_outlined, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('No Camera Detected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'We could not detect a camera connected to this device. You can upload a pre-recorded verification video from your files.',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              onFallbackUpload();
            },
            icon: const Icon(Icons.file_upload_outlined, size: 16),
            label: const Text('Upload Video File'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A5F),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  State<VideoKycRecorderDialog> createState() => _VideoKycRecorderDialogState();
}

class _VideoKycOptionDialog extends StatelessWidget {
  final String applicantName;
  final VoidCallback onRecordSelected;
  final VoidCallback onUploadSelected;

  const _VideoKycOptionDialog({
    required this.applicantName,
    required this.onRecordSelected,
    required this.onUploadSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Icon(Icons.video_camera_front_outlined, color: Color(0xFF2563EB), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Video KYC Verification',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Identity Verification Required',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'How would you like to provide your verification video?',
                style: TextStyle(fontSize: 13.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 18),

              // Option 1: Live Camera Recording (Recommended)
              InkWell(
                onTap: onRecordSelected,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2563EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Record with Camera',
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFA7F3D0)),
                                  ),
                                  child: const Text(
                                    'Recommended',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Instant recording via webcam / front camera with declaration script',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Option 2: Upload File
              InkWell(
                onTap: onUploadSelected,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.file_upload_outlined, color: Color(0xFF334155), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Existing Video File',
                              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Select MP4, MOV, or WEBM from your device storage',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Text(
                  isMobile
                      ? 'Mobile device camera will be requested on record.'
                      : 'Laptop or connected USB webcam will be used.',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoKycRecorderDialogState extends State<VideoKycRecorderDialog> {
  bool _isInitializing = true;
  bool _hasCamera = false;
  String _errorMessage = '';
  bool _isCountingDown = false;
  int _countdown = 3;
  bool _isRecording = false;
  bool _hasRecorded = false;
  int _secondsRecorded = 0;
  Timer? _timer;
  Timer? _countdownTimer;

  bool _isHindi = false;

  web.MediaStream? _mediaStream;
  web.MediaRecorder? _mediaRecorder;
  final List<web.Blob> _recordedChunks = [];
  Uint8List? _recordedBytes;

  late final String _previewViewId;
  late final String _playbackViewId;
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
          // 3. Fallback to video only if mic is blocked/absent
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
      if (mounted) {
        setState(() {
          _hasCamera = false;
          _isInitializing = false;
          _errorMessage = 'Camera access was blocked or is unavailable. Please allow camera access in browser permissions, or upload your video file directly.';
        });
      }
    }
  }

  void _triggerCountdownAndRecord() {
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
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
        Get.snackbar('Alert', 'Please record for at least 3 seconds.', backgroundColor: Colors.orange.withValues(alpha: 0.15));
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
    if (_recordedChunks.isEmpty) return;
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

      ui_web.platformViewRegistry.registerViewFactory(
        _playbackViewId,
        (int viewId) => _playbackVideoElement!,
      );

      if (mounted) {
        setState(() {
          _hasRecorded = true;
        });
      }
    } catch (e) {
      debugPrint('Error processing video blob: $e');
    }
  }

  void _reRecord() {
    setState(() {
      _hasRecorded = false;
      _recordedBytes = null;
      _secondsRecorded = 0;
    });
  }

  void _submitVideo() {
    if (_recordedBytes != null && _recordedBytes!.isNotEmpty) {
      final filename = 'kyc_video_${DateTime.now().millisecondsSinceEpoch}.webm';
      widget.onVideoRecorded(_recordedBytes!, filename);
      _cleanUp();
      Navigator.of(context).pop();
    }
  }

  void _cleanUp() {
    _timer?.cancel();
    _countdownTimer?.cancel();
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
            // 1. Camera Live Stream or Playback View
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
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.videocam_off, color: Colors.redAccent, size: 48),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Camera Unavailable',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onFallbackUpload();
                        },
                        icon: const Icon(Icons.file_upload_outlined, size: 16),
                        label: const Text('Upload Video From Files Instead'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ] else if (_hasRecorded) ...[
              // Video Playback review
              Positioned.fill(
                child: HtmlElementView(viewType: _playbackViewId),
              )
            ] else ...[
              // Live camera feed
              Positioned.fill(
                child: HtmlElementView(viewType: _previewViewId),
              )
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
                        const SizedBox(height: 10),
                        if (!_isRecording && !_isCountingDown)
                          TextButton.icon(
                            onPressed: () {
                              _cleanUp();
                              Navigator.of(context).pop();
                              widget.onFallbackUpload();
                            },
                            icon: const Icon(Icons.file_upload_outlined, size: 14, color: Colors.white70),
                            label: const Text('Prefer to upload a pre-recorded video file?', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
                              onPressed: _reRecord,
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
                              onPressed: _submitVideo,
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Submit KYC Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
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
          ],
        ),
      ),
    );
  }
}
