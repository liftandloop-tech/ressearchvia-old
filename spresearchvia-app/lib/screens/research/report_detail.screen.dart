import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:io';
import 'package:intl/intl.dart';

import '../../core/models/research_report.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_styles.dart';
import '../../services/snackbar.service.dart';
import '../../core/config/app.config.dart';
import '../../core/config/api.config.dart';
import '../../services/secure_storage.service.dart';
import 'widgets/youtube_video_player.dart';

class ReportDetailScreen extends StatefulWidget {
  final ResearchReport report;

  const ReportDetailScreen({super.key, required this.report});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  bool isDownloading = false;
  String? _authToken;
  bool _isLoadingToken = true;

  @override
  void initState() {
    super.initState();
    _loadAuthToken();
  }

  Future<void> _loadAuthToken() async {
    final token = await SecureStorageService().getAuthToken();
    if (mounted) {
      setState(() {
        _authToken = token;
        _isLoadingToken = false;
      });
    }
  }

  String _getReportUrl() {
    // If we are using the download-report endpoint, we reconstruct the URL properly
    // This allows us to use proper API authentication (headers) instead of static file access.
    
    // Construct full URL: BaseUrl + /reports/download-report/:id
    final baseUrl = AppConfig.baseUrl; // e.g. http://10.0.2.2:8080/api
    final endpoint = ApiConfig.downloadReport(widget.report.id); // /reports/download-report/:id
    
    // Remove /api from baseUrl if endpoint already contains relevant path segments?
    // Actually, checking standard concatenation:
    // Base: .../api
    // Endpoint: /reports/...
    // Result: .../api/reports/... -> Correct for standard backend structure
    
    // Standard concat:
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanEnd = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    
    return '$cleanBase$cleanEnd';
  }

  Future<void> _downloadReport() async {
    // Need token to download
    if (_authToken == null) {
      SnackbarService.showError('Authentication required');
      return;
    }

    final url = _getReportUrl();

    try {
      setState(() {
        isDownloading = true;
      });

      Directory? dir;
      if (Platform.isAndroid) {
        dir = Directory('/storage/emulated/0/Download');
        if (!await dir.exists()) {
             dir = await getExternalStorageDirectory();
        }
      } else {
        dir = await getApplicationDocumentsDirectory();
      }
      
      if (dir != null) {
        final fileName = widget.report.reportOriginalName.isNotEmpty 
            ? widget.report.reportOriginalName 
            : 'report_${widget.report.id}.pdf';
            
        final savePath = '${dir.path}/$fileName';
        
        await Dio().download(
          url,
          savePath,
          options: Options(
            headers: {
              'authorization': _authToken, 
            },
          ),
          onReceiveProgress: (received, total) {
            // Optional: Show progress
          },
        );
        
        SnackbarService.showSuccess('Report downloaded to $savePath');
      }
    } catch (e) {
      SnackbarService.showError('Failed to download: $e');
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  IconData _getFileIcon(String fileName) {
    if (fileName.endsWith('.pdf')) return Icons.picture_as_pdf_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingToken) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
      );
    }

    // Only show document if we have a path AND we have a token to access it
    // The previous check path.isNotEmpty is enough to know a doc SHOULD exist
    final hasDocument = widget.report.reportPath.isNotEmpty;
    final reportUrl = _getReportUrl();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Report Details',
          style: TextStyle(
            color: AppTheme.primaryBlueDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlueDark),
          onPressed: () => Get.back(),
        ),
        // Download button removed
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.report.title,
              style: AppStyles.heading3.copyWith(color: AppTheme.primaryBlueDark),
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    widget.report.category,
                    style: AppStyles.bodySmall.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  widget.report.formattedDateTime,
                  style: AppStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.report.description,
              style: AppStyles.bodyMedium.copyWith(height: 1.5),
            ),
            const SizedBox(height: 24),
            if (widget.report.youtubeUrl != null && widget.report.youtubeUrl!.trim().isNotEmpty) ...[
              YouTubeVideoPlayer(videoUrl: widget.report.youtubeUrl!.trim()),
              const SizedBox(height: 24),
            ],
            
            if (widget.report.updates.isNotEmpty) ...[
              const Text(
                'Updates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              const SizedBox(height: 12),
              ...widget.report.updates.map((update) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xffFFFBEB), // light amber background
                  border: Border.all(color: const Color(0xffFDE68A)), // amber-200 border
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.text,
                      style: AppStyles.bodyMedium.copyWith(height: 1.5, color: const Color(0xff1F2937)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, size: 14, color: Color(0xff6B7280)),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy hh:mm a').format(update.timestamp),
                          style: AppStyles.bodySmall.copyWith(color: const Color(0xff6B7280)),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 24),
            ],
            
            if (hasDocument) ...[
              const Text(
                'Document Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlueDark,
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final fileName = widget.report.reportOriginalName.toLowerCase();
                  final isPdf = fileName.endsWith('.pdf');
                  final isImage = fileName.endsWith('.png') || 
                                fileName.endsWith('.jpg') || 
                                fileName.endsWith('.jpeg') || 
                                fileName.endsWith('.gif');
                  
                  if (isPdf) {
                    return Container(
                      height: 500,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SfPdfViewer.network(
                          reportUrl,
                          headers: _authToken != null ? {'authorization': _authToken!} : null,
                          canShowScrollHead: true,
                          canShowScrollStatus: true,
                          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
                            debugPrint('PDF Load Failed: ${details.error}');
                          },
                        ),
                      ),
                    );
                  } else if (isImage) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.zoom_in, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Pinch to zoom',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                            child: InteractiveViewer(
                              panEnabled: true,
                              boundaryMargin: const EdgeInsets.all(20),
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.network(
                                reportUrl,
                                headers: _authToken != null ? {'authorization': _authToken!} : null,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 300,
                                    alignment: Alignment.center,
                                    child: const CircularProgressIndicator(),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Failed to load image'),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Premium placeholder for other file types
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade50, Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getFileIcon(fileName),
                              size: 48,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.report.reportOriginalName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppTheme.primaryBlueDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click below to download and view content',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: isDownloading ? null : _downloadReport,
                            icon: isDownloading 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.file_download_outlined),
                            label: Text(isDownloading ? 'Downloading...' : 'Download File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ]
          ],
        ),
      ),
    );
  }
}
