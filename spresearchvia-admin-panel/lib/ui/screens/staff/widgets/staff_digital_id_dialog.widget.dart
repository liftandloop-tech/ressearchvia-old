import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import '../../../../models/staff.model.dart';

class StaffDigitalIdDialog extends StatefulWidget {
  final StaffModel staff;

  const StaffDigitalIdDialog({super.key, required this.staff});

  @override
  State<StaffDigitalIdDialog> createState() => _StaffDigitalIdDialogState();
}

class _StaffDigitalIdDialogState extends State<StaffDigitalIdDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _showFront = true;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flipAnimation = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    if (_flipController.isAnimating) return;
    if (_showFront) {
      _flipController.forward();
      setState(() => _showFront = false);
    } else {
      _flipController.reverse();
      setState(() => _showFront = true);
    }
  }

  void _setSide(bool front) {
    if (front == _showFront || _flipController.isAnimating) return;
    if (front) {
      _flipController.reverse();
      setState(() => _showFront = true);
    } else {
      _flipController.forward();
      setState(() => _showFront = false);
    }
  }

  String get _verificationUrl {
    final staffKey = widget.staff.staffId.isNotEmpty
        ? widget.staff.staffId
        : widget.staff.id;
    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        if (origin.isNotEmpty && origin != 'null') {
          return '$origin/#/verify/staff/$staffKey';
        }
      } catch (_) {}
    }
    return '${AppConfig.adminUrl}/#/verify/staff/$staffKey';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _openVerificationUrl() async {
    final uri = Uri.parse(_verificationUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: _verificationUrl));
        Get.snackbar(
          'Verification Link',
          'Link copied to clipboard: $_verificationUrl',
          backgroundColor: AppTheme.successGreen,
          colorText: Colors.white,
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: _verificationUrl));
      Get.snackbar(
        'Verification Link',
        'Link copied to clipboard: $_verificationUrl',
        backgroundColor: AppTheme.successGreen,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _downloadOrPrintPdf({bool isPrintOnly = false}) async {
    setState(() => _isGeneratingPdf = true);
    try {
      final doc = pw.Document();

      final font = await PdfGoogleFonts.poppinsRegular();
      final fontBold = await PdfGoogleFonts.poppinsBold();
      final fontMedium = await PdfGoogleFonts.poppinsMedium();

      final staff = widget.staff;
      final joinDateStr = _formatDate(staff.joiningDate);
      final emergencyName = (staff.emergencyContact?.name ?? '').trim();
      final emergencyPhone = (staff.emergencyContact?.phone ?? '').trim();
      final emergencyRelation = (staff.emergencyContact?.relation ?? '').trim();
      final isDummy = emergencyName.toLowerCase().contains('test') ||
          emergencyPhone.toLowerCase().contains('test');
      final hasEmergency =
          !isDummy && (emergencyName.isNotEmpty || emergencyPhone.isNotEmpty);

      String emergencyFormatted = '';
      if (hasEmergency) {
        if (emergencyName.isNotEmpty && emergencyPhone.isNotEmpty) {
          emergencyFormatted = emergencyRelation.isNotEmpty
              ? '$emergencyName ($emergencyRelation) • $emergencyPhone'
              : '$emergencyName • $emergencyPhone';
        } else if (emergencyName.isNotEmpty) {
          emergencyFormatted = emergencyRelation.isNotEmpty
              ? '$emergencyName ($emergencyRelation)'
              : emergencyName;
        } else {
          emergencyFormatted = emergencyPhone;
        }
      }

      // Page with CR80 Standard ID dimensions (Front and Back side by side on A4)
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // ================= FRONT CARD (PDF) =================
                  pw.Container(
                    width: 210,
                    height: 340,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(14),
                      border: pw.Border.all(
                        color: PdfColor.fromHex('#0F172A'),
                        width: 1.2,
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        // Lanyard slot
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
                          width: 28,
                          height: 3,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#E2E8F0'),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                        // Dark Header
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'SP RESEARCHVIA PVT. LTD.',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  color: PdfColors.white,
                                  fontSize: 10,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              pw.SizedBox(height: 1),
                              pw.Text(
                                'SEBI REG. RESEARCH ANALYST • INH000015808',
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  color: PdfColor.fromHex('#F59E0B'),
                                  fontSize: 5.5,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              pw.Text(
                                'CIN: U73200MP2023PTC069041 • BSE: 6120',
                                style: pw.TextStyle(
                                  font: font,
                                  color: PdfColor.fromHex('#94A3B8'),
                                  fontSize: 4.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 10),

                        // Avatar Circle
                        pw.Container(
                          width: 52,
                          height: 52,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            color: PdfColor.fromHex('#0F172A'),
                            border: pw.Border.all(
                              color: PdfColor.fromHex('#10B981'),
                              width: 1.5,
                            ),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              staff.name.isNotEmpty
                                  ? staff.name[0].toUpperCase()
                                  : 'S',
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 22,
                                color: PdfColors.white,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 6),

                        // Employee Name
                        pw.Text(
                          staff.name,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 12,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                        pw.SizedBox(height: 2),

                        // Role / Department Pill
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#EEF2FF'),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            (staff.department.isNotEmpty
                                    ? staff.department
                                    : staff.role)
                                .toUpperCase(),
                            style: pw.TextStyle(
                              font: fontBold,
                              fontSize: 7.0,
                              color: PdfColor.fromHex('#4338CA'),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 2),

                        // Staff ID
                        pw.Text(
                          'ID: ${staff.staffId}',
                          style: pw.TextStyle(
                            font: fontMedium,
                            fontSize: 7.5,
                            color: PdfColor.fromHex('#64748B'),
                          ),
                        ),
                        pw.SizedBox(height: 8),

                        // Info Grid
                        pw.Container(
                          margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F8FAFC'),
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(
                              color: PdfColor.fromHex('#E2E8F0'),
                              width: 0.8,
                            ),
                          ),
                          child: pw.Column(
                            children: [
                              _buildPdfRow(
                                'Department',
                                staff.department.isNotEmpty
                                    ? staff.department
                                    : staff.role,
                                font,
                                fontBold,
                              ),
                              _buildPdfRow('Joined', joinDateStr, font, fontBold),
                              _buildPdfRow(
                                'Email',
                                staff.email,
                                font,
                                fontBold,
                              ),
                              _buildPdfRow(
                                'Mobile',
                                staff.mobile,
                                font,
                                fontBold,
                              ),
                            ],
                          ),
                        ),

                        pw.Spacer(),

                        // Bottom Strip with QR
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F1F5F9'),
                            borderRadius: const pw.BorderRadius.only(
                              bottomLeft: pw.Radius.circular(13),
                              bottomRight: pw.Radius.circular(13),
                            ),
                          ),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.all(2),
                                decoration: pw.BoxDecoration(
                                  color: PdfColors.white,
                                  borderRadius: pw.BorderRadius.circular(4),
                                ),
                                child: pw.BarcodeWidget(
                                  barcode: pw.Barcode.qrCode(),
                                  data: _verificationUrl,
                                  width: 36,
                                  height: 36,
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      'VERIFIED CREDENTIAL',
                                      style: pw.TextStyle(
                                        font: fontBold,
                                        fontSize: 6.5,
                                        color: PdfColor.fromHex('#0F172A'),
                                      ),
                                    ),
                                    pw.Text(
                                      'Scan with camera to verify authenticity',
                                      style: pw.TextStyle(
                                        font: font,
                                        fontSize: 5.5,
                                        color: PdfColor.fromHex('#64748B'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(width: 24),

                  // ================= BACK CARD (PDF) =================
                  pw.Container(
                    width: 210,
                    height: 340,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(14),
                      border: pw.Border.all(
                        color: PdfColor.fromHex('#0F172A'),
                        width: 1.2,
                      ),
                    ),
                    child: pw.Column(
                      children: [
                        // Lanyard slot
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 6, bottom: 4),
                          width: 28,
                          height: 3,
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#E2E8F0'),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                        ),
                        // Back Header
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 8,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'OFFICIAL CREDENTIALS & COMPLIANCE',
                              style: pw.TextStyle(
                                font: fontBold,
                                color: PdfColors.white,
                                fontSize: 7.5,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 10),

                        // Centered High-Contrast QR Code
                        pw.Container(
                          padding: const pw.EdgeInsets.all(4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.white,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(
                              color: PdfColor.fromHex('#CBD5E1'),
                              width: 1,
                            ),
                          ),
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: _verificationUrl,
                            width: 68,
                            height: 68,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'EMPLOYEE AUTHENTICITY QR',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 7.5,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                        pw.Text(
                          'Scan with any smartphone camera to verify SEBI status',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 5.5,
                            color: PdfColor.fromHex('#64748B'),
                          ),
                        ),
                        pw.SizedBox(height: 8),

                        // Emergency Contact Box
                        pw.Container(
                          margin: const pw.EdgeInsets.symmetric(horizontal: 10),
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F8FAFC'),
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(
                              color: PdfColor.fromHex('#E2E8F0'),
                              width: 0.8,
                            ),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'EMERGENCY CONTACT',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 6.0,
                                  color: PdfColor.fromHex('#475569'),
                                ),
                              ),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                emergencyFormatted,
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  fontSize: 6.8,
                                  color: PdfColor.fromHex('#1E293B'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 6),

                        // Corporate details
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'SP ResearchVia Pvt. Ltd.',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  fontSize: 6.8,
                                  color: PdfColor.fromHex('#0F172A'),
                                ),
                              ),
                              pw.Text(
                                '129 A, Kalani Bagh, AB Road, Dewas, MP - 455001',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 5.5,
                                  color: PdfColor.fromHex('#64748B'),
                                ),
                              ),
                              pw.Text(
                                'Quick Connect: +91 9755016839 • info@researchvia.in',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 5.0,
                                  color: PdfColor.fromHex('#64748B'),
                                ),
                              ),
                              pw.SizedBox(height: 3),
                              pw.Text(
                                'Property of SP ResearchVia Pvt. Ltd. Strictly non-transferable. If found, please return to address above.',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 4.8,
                                  color: PdfColor.fromHex('#94A3B8'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        pw.Spacer(),

                        // Bottom Signature Strip
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F1F5F9'),
                            borderRadius: const pw.BorderRadius.only(
                              bottomLeft: pw.Radius.circular(13),
                              bottomRight: pw.Radius.circular(13),
                            ),
                          ),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'SEBI: INH000015808',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 6.5,
                                      color: PdfColor.fromHex('#0F172A'),
                                    ),
                                  ),
                                  pw.Text(
                                    'STATUS: ACTIVE',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 6.0,
                                      color: PdfColor.fromHex('#10B981'),
                                    ),
                                  ),
                                ],
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    width: 50,
                                    height: 0.8,
                                    color: PdfColor.fromHex('#0F172A'),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    'Auth Signatory',
                                    style: pw.TextStyle(
                                      font: fontBold,
                                      fontSize: 6.0,
                                      color: PdfColor.fromHex('#475569'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      if (isPrintOnly) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => doc.save(),
          name: 'Staff_ID_${widget.staff.staffId}_${widget.staff.name}.pdf',
        );
      } else {
        await Printing.sharePdf(
          bytes: await doc.save(),
          filename: 'Staff_ID_${widget.staff.staffId}_${widget.staff.name}.pdf',
        );
      }
    } catch (e) {
      Get.snackbar(
        'PDF Error',
        'Could not export ID card: $e',
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  pw.Widget _buildPdfRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: font,
              fontSize: 6.5,
              color: PdfColor.fromHex('#64748B'),
            ),
          ),
          pw.Text(
            value.length > 20 ? '${value.substring(0, 18)}...' : value,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 6.5,
              color: PdfColor.fromHex('#0F172A'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      elevation: 32,
      child: Container(
        width: 780,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Modal Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Color(0xFF60A5FA),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff Digital Identity Card',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SP ResearchVia Pvt. Ltd. • SEBI Reg: INH000015808 • CIN: U73200MP2023PTC069041',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                  hoverColor: Colors.white.withValues(alpha: 0.08),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Content: 3D Card on Left, Controls & Verification on Right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visual 3D Interactive Card Column
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: _toggleFlip,
                      child: Tooltip(
                        message: 'Click to flip card',
                        child: AnimatedBuilder(
                          animation: _flipAnimation,
                          builder: (context, child) {
                            final angle = _flipAnimation.value * math.pi;
                            final isBack = angle >= (math.pi / 2);
                            final transform = Matrix4.identity()
                              ..setEntry(3, 2, 0.0012)
                              ..rotateY(angle);

                            return Transform(
                              transform: transform,
                              alignment: Alignment.center,
                              child: isBack
                                  ? Transform(
                                      transform: Matrix4.identity()
                                        ..rotateY(math.pi),
                                      alignment: Alignment.center,
                                      child: _buildCardBack(),
                                    )
                                  : _buildCardFront(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Flip Hint / Button
                    InkWell(
                      onTap: _toggleFlip,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sync,
                              size: 14,
                              color: Colors.blue[300],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _showFront
                                  ? 'Click to Flip to Back'
                                  : 'Click to Flip to Front',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 32),

                // Controls, Verification details, & Actions Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Segmented Card View Toggle
                      const Text(
                        'CARD VIEW',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _setSide(true),
                                icon: const Icon(Icons.badge, size: 15),
                                label: const Text('Front Side'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _showFront
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  foregroundColor: _showFront
                                      ? Colors.white
                                      : Colors.grey[400],
                                  elevation: _showFront ? 2 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _setSide(false),
                                icon: const Icon(Icons.flip_to_back, size: 15),
                                label: const Text('Back Side'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_showFront
                                      ? const Color(0xFF2563EB)
                                      : Colors.transparent,
                                  foregroundColor: !_showFront
                                      ? Colors.white
                                      : Colors.grey[400],
                                  elevation: !_showFront ? 2 : 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Verification Details Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Public QR Verification Link',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Scanning this QR code directs clients and auditors to the live SEBI employee verification record confirming authentic employment.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _verificationUrl,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        fontFamily: 'monospace',
                                        color: Color(0xFF93C5FD),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.copy,
                                      size: 15,
                                      color: Color(0xFF60A5FA),
                                    ),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    tooltip: 'Copy link',
                                    onPressed: () {
                                      Clipboard.setData(
                                        ClipboardData(text: _verificationUrl),
                                      );
                                      Get.snackbar(
                                        'Link Copied',
                                        'Verification link copied to clipboard.',
                                        backgroundColor: AppTheme.successGreen,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Open verification page directly button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _openVerificationUrl,
                                icon: const Icon(Icons.open_in_new, size: 14),
                                label: const Text(
                                  'Test & Open Public Verification Page',
                                  style: TextStyle(fontSize: 11.5),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF60A5FA),
                                  side: const BorderSide(
                                    color: Color(0xFF3B82F6),
                                    width: 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons: Print & Download PDF
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingPdf
                              ? null
                              : () => _downloadOrPrintPdf(isPrintOnly: false),
                          icon: _isGeneratingPdf
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.picture_as_pdf, size: 17),
                          label: const Text(
                            'Download High-Res PDF (CR80 PVC Ready)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isGeneratingPdf
                                  ? null
                                  : () => _downloadOrPrintPdf(isPrintOnly: true),
                              icon: const Icon(Icons.print, size: 16),
                              label: const Text('Print Badge Directly'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                final staffCtrl =
                                    Get.isRegistered<StaffController>()
                                        ? Get.find<StaffController>()
                                        : Get.put(StaffController());
                                staffCtrl.populateForEdit(widget.staff);
                                Get.toNamed('/staff/edit/${widget.staff.id}');
                              },
                              icon: const Icon(Icons.edit_note, size: 16),
                              label: const Text('Edit Staff Info'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF94A3B8),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= FRONT CARD WIDGET =================
  Widget _buildCardFront() {
    final staff = widget.staff;

    return Container(
      key: const ValueKey('front'),
      width: 290,
      height: 460,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Lanyard Hole
          _buildLanyardSlot(),

          // Minimalist Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.token, color: Color(0xFFF59E0B), size: 13),
                    SizedBox(width: 5),
                    Text(
                      'SP RESEARCHVIA PVT. LTD.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'SEBI REG. RESEARCH ANALYST • INH000015808',
                  style: TextStyle(
                    fontSize: 6.8,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFF59E0B),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 1),
                const Text(
                  'CIN: U73200MP2023PTC069041 • BSE: 6120',
                  style: TextStyle(
                    fontSize: 6.0,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Profile Image Avatar with Status Indicator
          _buildAvatar(),

          const SizedBox(height: 8),

          // Employee Full Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              staff.name,
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 3),

          // Designation Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Text(
              (staff.department.isNotEmpty ? staff.department : staff.role)
                  .toUpperCase(),
              style: const TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF4338CA),
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(height: 3),

          // Staff ID Pill
          Text(
            'ID: ${staff.staffId}',
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 10),

          // 2x2 Minimal Credential Grid
          _buildFrontCredentialGrid(),

          const Spacer(),

          // Front Verification Strip with Embedded Micro QR
          _buildFrontFooter(),
        ],
      ),
    );
  }

  // ================= BACK CARD WIDGET =================
  Widget _buildCardBack() {
    final staff = widget.staff;
    final emName = (staff.emergencyContact?.name ?? '').trim();
    final emRelation = (staff.emergencyContact?.relation ?? '').trim();
    final emPhone = (staff.emergencyContact?.phone ?? '').trim();
    final isDummy = emName.toLowerCase().contains('test') ||
        emPhone.toLowerCase().contains('test');
    final hasEmergency = !isDummy && (emName.isNotEmpty || emPhone.isNotEmpty);

    String emergencyFormatted = '';
    if (hasEmergency) {
      if (emName.isNotEmpty && emPhone.isNotEmpty) {
        emergencyFormatted = emRelation.isNotEmpty
            ? '$emName ($emRelation) • $emPhone'
            : '$emName • $emPhone';
      } else if (emName.isNotEmpty) {
        emergencyFormatted =
            emRelation.isNotEmpty ? '$emName ($emRelation)' : emName;
      } else {
        emergencyFormatted = emPhone;
      }
    }

    return Container(
      key: const ValueKey('back'),
      width: 290,
      height: 460,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Lanyard Hole
          _buildLanyardSlot(),

          // Back Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: const Center(
              child: Text(
                'OFFICIAL CREDENTIALS & COMPLIANCE',
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Large High-Contrast Central QR Code
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: QrImageView(
              data: _verificationUrl,
              version: QrVersions.auto,
              size: 92.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'EMPLOYEE AUTHENTICITY QR',
            style: TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Scan with smartphone camera to verify SEBI credentials & employment status',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 7.5,
                color: Colors.grey[600],
                height: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Emergency Contact Card
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.contact_emergency,
                  size: 16,
                  color: hasEmergency
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EMERGENCY CONTACT',
                        style: TextStyle(
                          fontSize: 7.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF475569),
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        emergencyFormatted,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Corporate Headquarters & Terms
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SP ResearchVia Pvt. Ltd.',
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '129 A, Kalani Bagh, AB Road, Dewas, MP - 455001\nQuick Connect: +91 9755016839 • info@researchvia.in\nCIN: U73200MP2023PTC069041 • BSE: 6120',
                  style: TextStyle(
                    fontSize: 7.2,
                    color: Colors.grey[600],
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Property of SP ResearchVia Pvt. Ltd. Strictly non-transferable. If found, please return to corporate address above or call +91 9755016839.',
                  style: TextStyle(
                    fontSize: 6.6,
                    color: Colors.grey[500],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bottom Signature Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'SEBI: INH000015808',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'ACTIVE & VERIFIED',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 65,
                      height: 1,
                      color: const Color(0xFF0F172A),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Authorised Signatory',
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildLanyardSlot() {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 6),
      width: 32,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 0.5),
      ),
    );
  }

  Widget _buildAvatar() {
    final staff = widget.staff;
    final hasPhoto = staff.photoUrl != null && staff.photoUrl!.isNotEmpty;
    final photoUrl =
        hasPhoto ? AppConfig.buildImageUrl(staff.photoUrl) : '';

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF0F172A),
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          ClipOval(
            child: hasPhoto
                ? Image.network(
                    photoUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildInitialsAvatar(),
                  )
                : _buildInitialsAvatar(),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    final initial = widget.staff.name.isNotEmpty
        ? widget.staff.name[0].toUpperCase()
        : 'S';
    return Container(
      width: 76,
      height: 76,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCredentialGrid() {
    final staff = widget.staff;
    final joinDate = _formatDate(staff.joiningDate);
    final dept = staff.department.isNotEmpty
        ? staff.department
        : (staff.role.isNotEmpty ? staff.role : 'Operations');
    final mobile = staff.mobile.isNotEmpty ? staff.mobile : 'N/A';
    final email = staff.email.isNotEmpty ? staff.email : 'N/A';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildMicroField('DEPARTMENT', dept)),
              Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 8),
              Expanded(child: _buildMicroField('JOINED', joinDate)),
            ],
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(child: _buildMicroField('WORK EMAIL', email)),
              Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
              const SizedBox(width: 8),
              Expanded(child: _buildMicroField('MOBILE', mobile)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 7.0,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: const TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFrontFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            child: QrImageView(
              data: _verificationUrl,
              version: QrVersions.auto,
              size: 38.0,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.verified, color: Color(0xFF10B981), size: 12),
                    SizedBox(width: 4),
                    Text(
                      'VERIFIED SEBI CREDENTIAL',
                      style: TextStyle(
                        fontSize: 8.0,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Scan with smartphone camera to verify authenticity',
                  style: TextStyle(
                    fontSize: 7.2,
                    color: Color(0xFF64748B),
                    height: 1.2,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
