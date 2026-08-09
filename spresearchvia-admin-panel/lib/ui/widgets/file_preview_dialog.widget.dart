import 'dart:typed_data';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/services/report.service.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;

class FilePreviewDialog extends StatelessWidget {
  final String fileName;
  final Uint8List? fileBytes;
  final String? fileUrl;

  const FilePreviewDialog({
    super.key,
    required this.fileName,
    this.fileBytes,
    this.fileUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    final isImage = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
    ].any((ext) => fileName.toLowerCase().endsWith(ext));
    final isVideo = [
      '.mp4',
      '.mov',
      '.avi',
      '.mkv',
      '.webm',
      '.3gp',
    ].any((ext) => fileName.toLowerCase().endsWith(ext));

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Preview: $fileName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: Container(
                color: AppTheme.gray50,
                child: Center(child: _buildPreviewContent(isPdf, isImage, isVideo)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(bool isPdf, bool isImage, bool isVideo) {
    if (fileBytes != null) {
      if (isImage) {
        return InteractiveViewer(child: Image.memory(fileBytes!));
      } else if (isPdf) {
        return _WebPdfViewer(bytes: fileBytes);
      }
    } else if (fileUrl != null) {
      if (isImage) {
        return InteractiveViewer(
          child: Image.network(
            AppConfig.buildImageUrl(fileUrl),
            errorBuilder: (context, error, stackTrace) =>
                const Text('Error loading image'),
          ),
        );
      } else if (isPdf) {
        return _WebPdfViewer(url: fileUrl);
      } else if (isVideo) {
        return _WebVideoPlayer(url: fileUrl!);
      }
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.insert_drive_file, size: 64, color: AppTheme.gray300),
        const SizedBox(height: 16),
        Text(
          'Preview not available for this file type',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}

class _WebVideoPlayer extends StatelessWidget {
  final String url;
  const _WebVideoPlayer({required this.url});

  @override
  Widget build(BuildContext context) {
    final viewId = 'video-player-${DateTime.now().millisecondsSinceEpoch}';
    final fullUrl = AppConfig.buildImageUrl(url);
    ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final element = web.HTMLVideoElement()
        ..src = fullUrl
        ..controls = true
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return element;
    });
    return HtmlElementView(viewType: viewId);
  }
}

class _WebPdfViewer extends StatefulWidget {
  final Uint8List? bytes;
  final String? url;

  const _WebPdfViewer({this.bytes, this.url});

  @override
  State<_WebPdfViewer> createState() => _WebPdfViewerState();
}

class _WebPdfViewerState extends State<_WebPdfViewer> {
  late String viewId;
  String? blobUrl;
  bool isLoading = false;
  Uint8List? fetchedBytes;

  @override
  void initState() {
    super.initState();
    viewId = 'pdf-viewer-${DateTime.now().millisecondsSinceEpoch}';

    if (widget.bytes != null) {
      _registerBlob(widget.bytes!);
    } else if (widget.url != null) {
      _fetchAndRegister();
    }
  }

  Future<void> _fetchAndRegister() async {
    // Direct static URL
    if (!widget.url!.contains('/download-report/')) {
      blobUrl = AppConfig.buildImageUrl(widget.url);
      ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
        final element = web.HTMLIFrameElement()
          ..src = blobUrl!
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return element;
      });
      if (mounted) setState(() {});
      return;
    }

    setState(() => isLoading = true);
    try {
      final uri = Uri.parse(widget.url!);
      final lastSegment = uri.pathSegments.last;

      final reportService = Get.find<ReportService>();
      Uint8List? bytes;

      if (widget.url!.contains('/download-report/')) {
        bytes = await reportService.downloadReport(lastSegment);
      } else {
        bytes = await reportService.downloadReport(
          null,
          reportName: lastSegment,
        );
      }

      if (bytes != null && mounted) {
        fetchedBytes = bytes;
        _registerBlob(bytes);
      }
    } catch (e) {
      debugPrint('Error fetching PDF for preview: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _registerBlob(Uint8List bytes) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'application/pdf'),
    );
    blobUrl = web.URL.createObjectURL(blob);

    ui.platformViewRegistry.registerViewFactory(viewId, (int id) {
      final element = web.HTMLIFrameElement()
        ..src = blobUrl!
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return element;
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (blobUrl != null && !widget.url!.contains('/uploads/')) {
      web.URL.revokeObjectURL(blobUrl!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (blobUrl == null) {
      return const Center(child: Text('Failed to load preview'));
    }
    return HtmlElementView(viewType: viewId);
  }
}
