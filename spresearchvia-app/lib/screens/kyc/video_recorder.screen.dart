import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../../controllers/kyc.controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/theme/app_theme.dart';
import '../../services/snackbar.service.dart';


class VideoRecorderScreen extends StatefulWidget {
  final String language;

  const VideoRecorderScreen({super.key, required this.language});

  @override
  State<VideoRecorderScreen> createState() => _VideoRecorderScreenState();
}

class _VideoRecorderScreenState extends State<VideoRecorderScreen> with WidgetsBindingObserver {
  KycController? _kycController;
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isCountingDown = false;
  int _countdown = 3;
  int _seconds = 0;
  Timer? _timer;
  Timer? _countdownTimer;

  late String _declarationText;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    try {
      _kycController = Get.find<KycController>();
    } catch (e) {
      SnackbarService.showError('Controller error. Please restart the app.');
    }
    
    // DELAY FIX: waiting for page transition to finish prevents "Illegal State" / resource contention
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted) return;

      // SAFETY NET: Check permissions status only (no request).
      // Permissions should already be granted by VideoKycIntroScreen (the gatekeeper).
      // This guard protects against future navigation bypasses (deep links, backend changes, etc.).
      final camOk = await Permission.camera.status;
      final micOk = await Permission.microphone.status;

      if (!mounted) return;

      if (!camOk.isGranted || !micOk.isGranted) {
        // Redirect back to the gatekeeper — do NOT request here
        debugPrint('VideoRecorder: Permissions not granted. Redirecting to videoKycIntro.');
        Get.offAllNamed(AppRoutes.videoKycIntro);
        return;
      }

      _initializeCamera();
    });
    
    _setDeclarationText();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      // Always try to init on resume
      _initializeCamera();
    }
  }

  void _setDeclarationText() {
    if (widget.language.toLowerCase() == 'hindi') {
      _declarationText =
          'मैं इस सेवा को स्वीकार करता हूँ और मुझे बाज़ार में शामिल जोखिमों की पूरी जानकारी है।';
    } else {
      _declarationText =
          'I accept the service and i also aware about the Risk involve in the market.';
    }
  }

  Future<ResolutionPreset> _getBestResolution() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // Older Android versions (<= Android 10) or lower-end devices
        if (androidInfo.version.sdkInt <= 29) {
          return ResolutionPreset.medium; // 480p - Best for stability
        }
      }
    } catch (e) {
      debugPrint('Error detecting device info: $e');
    }
    return ResolutionPreset.high; // Default for newer/iOS devices
  }

  Future<void> _initializeCamera() async {
    // Permissions are confirmed by VideoKycIntroScreen (gatekeeper) and the
    // safety net in initState. We only check status here — no system prompts.
    final cameraStatus = await Permission.camera.status;
    final micStatus = await Permission.microphone.status;

    if (cameraStatus.isGranted && micStatus.isGranted) {
      try {
        final cameras = await availableCameras();
        if (cameras.isNotEmpty) {
          final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
            orElse: () => cameras.first,
          );

          if (_controller != null) {
            await _controller!.dispose();
          }

          final resolution = await _getBestResolution();

          _controller = CameraController(
            frontCamera,
            resolution,
            enableAudio: true,
            imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.jpeg,
          );

          await _controller!.initialize();
          await _controller!.prepareForVideoRecording();

          // HARDWARE STABILITY DELAY: Give the sensor/mic time to settle
          await Future.delayed(const Duration(milliseconds: 1000));
          
          if (mounted) {
            setState(() {
              _isCameraInitialized = true;
            });
          }
        } else {
          SnackbarService.showError('No camera found');
        }
      } catch (e) {
        debugPrint('Camera initialization error: $e');
        if (mounted) {
          SnackbarService.showError('Camera Error: Please restart app');
        }
      }
    } else {
      // Should never reach here due to gatekeeper + safety net in initState.
      // Fallback: send user back to intro to re-confirm permissions.
      debugPrint('VideoRecorder: _initializeCamera found no permission. Redirecting to intro.');
      if (mounted) {
        Get.offAllNamed(AppRoutes.videoKycIntro);
      }
    }
  }

  bool _isProcessing = false;

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isProcessing || _isRecording || _isCountingDown) return;
    
    setState(() {
      _isCountingDown = true;
      _countdown = 3;
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 1) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
          _isProcessing = true;
        });

        try {
          // Pre-recording brief delay
          await Future.delayed(const Duration(milliseconds: 300));
          await _controller!.startVideoRecording();
          
          setState(() {
            _isRecording = true;
            _seconds = 0;
          });
          _startTimer();

          // AUTO-STOP SAFETY: Stop after 30 seconds
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted && _isRecording) {
              _stopRecording();
            }
          });

        } catch (e) {
          SnackbarService.showError('Failed to start recording: $e');
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_isRecording || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final file = await _controller!.stopVideoRecording();
      _stopTimer();
      
      setState(() {
        _isRecording = false;
      });
      
      // Upload explicitly

      await _uploadVideo(File(file.path));

    } catch (e) {

      SnackbarService.showError('Failed to stop recording: $e');
      setState(() {
        _isProcessing = false; // Only reset if error, otherwise upload handles loading state
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _uploadVideo(File videoFile) async {
    // _isProcessing is already true coming from _stopRecording
    if (_kycController == null) {
      SnackbarService.showError('KYC Controller not initialized.');
      setState(() => _isProcessing = false);
      return;
    }
    
    // We rely on the controller's isLoading for the UI now, but we can keep _isProcessing true to lock buttons
    // The previous Obx handles the "Uploading..." text based on controller.isLoading
    
    // Ensure controller loading is triggered if not already inside uploadKycVideo (it is)
    final success = await _kycController!.uploadKycVideo(videoFile);

    
    if (success) {
      Get.offAllNamed(AppRoutes.sebiCompilanceCheck);
    } else {
      // If failed, allow retry or just reset states
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _stopTimer();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final int min = seconds ~/ 60;
    final int sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // LOADING SCREEN (Now with Back Button)
    if (!_isCameraInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text("Initializing Camera...", style: TextStyle(color: Colors.white54))
                  ],
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Get.back(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // MAIN CAMERA SCREEN
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera Preview
            if (_controller != null && _controller!.value.isInitialized)
              Positioned.fill(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: CameraPreview(_controller!),
                ),
              ),

            // Countdown Overlay
            if (_isCountingDown)
              Positioned.fill(
                child: Container(
                  color: Colors.black45,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "$_countdown",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 100,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Prepare to speak...",
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top Bar (Back button + Timer)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black54, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Get.back(),
                    ),
                    if (_isRecording)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatDuration(_seconds),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Area (Marquee + Controls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Marquee Text
                    // Static Declaration Text
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        _declarationText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Controls
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Obx(() {
                        final isLoading = _kycController?.isLoading.value ?? false;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoading) ...[
                              const CircularProgressIndicator(color: Colors.white),
                              const SizedBox(height: 20),
                              const Text("Uploading...",
                                  style: TextStyle(color: Colors.white)),
                            ] else ...[
                              if (!_isRecording)
                                GestureDetector(
                                  onTap: (_isProcessing || _isCountingDown) ? null : _startRecording,
                                  child: Container(
                                    height: 70,
                                    width: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: (_isProcessing || _isCountingDown) ? Colors.white24 : Colors.white, 
                                          width: 4),
                                      color: (_isProcessing || _isCountingDown) ? Colors.grey : Colors.red,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.videocam,
                                          color: Colors.white, size: 30),
                                    ),
                                  ),
                                ),
                              if (_isRecording)
                                GestureDetector(
                                  onTap: (_seconds < 1 || _isProcessing) ? null : _stopRecording,
                                  child: Container(
                                    height: 70,
                                    width: 70,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: (_seconds < 1 || _isProcessing) ? Colors.white24 : Colors.white, 
                                          width: 4),
                                      color: Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Container(
                                        height: 30,
                                        width: 30,
                                        decoration: BoxDecoration(
                                          color: (_seconds < 1 || _isProcessing) ? Colors.grey : Colors.red,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ]
                          ],
                        );
                      }),
                    ),
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
