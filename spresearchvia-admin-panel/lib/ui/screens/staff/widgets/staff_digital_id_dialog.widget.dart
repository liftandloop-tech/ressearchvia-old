import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:spresearch_web/controllers/staff/staff.controller.dart';
import '../../../../models/staff.model.dart';
import 'add_staff_dialog.widget.dart';

class StaffDigitalIdDialog extends StatefulWidget {
  final StaffModel staff;

  const StaffDigitalIdDialog({super.key, required this.staff});

  @override
  State<StaffDigitalIdDialog> createState() => _StaffDigitalIdDialogState();
}

class _StaffDigitalIdDialogState extends State<StaffDigitalIdDialog> {
  bool _showFront = true;
  bool _isGeneratingPdf = false;

  String get _verificationUrl {
    final baseUrl = AppConfig.apiBaseUrl.replaceAll('/api', '');
    return '$baseUrl/verify/staff/${widget.staff.staffId.isNotEmpty ? widget.staff.staffId : widget.staff.id}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
      final emergencyName = staff.emergencyContact?.name ?? 'N/A';
      final emergencyPhone = staff.emergencyContact?.phone ?? 'N/A';
      final emergencyRelation = staff.emergencyContact?.relation ?? 'N/A';

      // Page with CR80 Standard ID dimensions (approx 54mm x 86mm in points: 153 x 243 pt, or standard A4 / badge layout)
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  // FRONT CARD (PDF)
                  pw.Container(
                    width: 220,
                    height: 350,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: PdfColor.fromHex('#1E3A5F'), width: 1.5),
                    ),
                    child: pw.Column(
                      children: [
                        // Header
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#1E3A5F'),
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(10),
                              topRight: pw.Radius.circular(10),
                            ),
                          ),
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'RESEARCHVIA',
                                style: pw.TextStyle(
                                  font: fontBold,
                                  color: PdfColors.white,
                                  fontSize: 14,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              pw.Text(
                                'SEBI REG. RESEARCH ANALYST',
                                style: pw.TextStyle(
                                  font: fontMedium,
                                  color: PdfColor.fromHex('#F59E0B'),
                                  fontSize: 6.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 12),
                        // Avatar placeholder
                        pw.Container(
                          width: 58,
                          height: 58,
                          decoration: pw.BoxDecoration(
                            shape: pw.BoxShape.circle,
                            color: PdfColor.fromHex('#E0E7FF'),
                            border: pw.Border.all(color: PdfColor.fromHex('#1E3A5F'), width: 1.5),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                              style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColor.fromHex('#1E3A5F')),
                            ),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          staff.name,
                          style: pw.TextStyle(font: fontBold, fontSize: 13, color: PdfColor.fromHex('#1E3A5F')),
                        ),
                        pw.Container(
                          margin: const pw.EdgeInsets.symmetric(vertical: 4),
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#EEF2FF'),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(
                            staff.department.isNotEmpty ? staff.department : staff.role,
                            style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('#4F46E5')),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          child: pw.Column(
                            children: [
                              _buildPdfRow('Staff ID', staff.staffId, font, fontBold),
                              _buildPdfRow('Email', staff.email, font, fontBold),
                              _buildPdfRow('Mobile', staff.mobile, font, fontBold),
                              _buildPdfRow('Join Date', joinDateStr, font, fontBold),
                            ],
                          ),
                        ),
                        pw.Spacer(),
                        // QR Code barcode
                        pw.Container(
                          padding: const pw.EdgeInsets.all(6),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#F8FAFC'),
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                          ),
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: _verificationUrl,
                            width: 48,
                            height: 48,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'Scan to Verify Authenticity',
                          style: pw.TextStyle(font: font, fontSize: 6, color: PdfColors.grey700),
                        ),
                        pw.SizedBox(height: 8),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),

                  // BACK CARD (PDF)
                  pw.Container(
                    width: 220,
                    height: 350,
                    decoration: pw.BoxDecoration(
                      color: PdfColors.white,
                      borderRadius: pw.BorderRadius.circular(12),
                      border: pw.Border.all(color: PdfColor.fromHex('#1E3A5F'), width: 1.5),
                    ),
                    child: pw.Column(
                      children: [
                        // Back Header
                        pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromHex('#0F172A'),
                            borderRadius: const pw.BorderRadius.only(
                              topLeft: pw.Radius.circular(10),
                              topRight: pw.Radius.circular(10),
                            ),
                          ),
                          child: pw.Center(
                            child: pw.Text(
                              'EMERGENCY & COMPLIANCE',
                              style: pw.TextStyle(font: fontBold, color: PdfColors.white, fontSize: 9),
                            ),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(12),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Emergency Contact:', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('#1E3A5F'))),
                              pw.SizedBox(height: 2),
                              pw.Text('$emergencyName ($emergencyRelation)', style: pw.TextStyle(font: font, fontSize: 7.5)),
                              pw.Text('Ph: $emergencyPhone', style: pw.TextStyle(font: font, fontSize: 7.5)),
                              pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 0.5, height: 12),

                              pw.Text('Corporate Office:', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('#1E3A5F'))),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'SP ResearchVia Global Markets Ltd.\nTower B, Financial District, BKC, Mumbai - 400051\nEmail: compliance@researchvia.com',
                                style: pw.TextStyle(font: font, fontSize: 6.8, lineSpacing: 1.2),
                              ),
                              pw.Divider(color: PdfColor.fromHex('#E2E8F0'), thickness: 0.5, height: 12),

                              pw.Text('Terms & Conditions:', style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColor.fromHex('#1E3A5F'))),
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'This card is the property of ResearchVia and is strictly non-transferable. Loss must be reported immediately to HR. If found, please return to the corporate address above.',
                                style: pw.TextStyle(font: font, fontSize: 6.2, color: PdfColors.grey700, lineSpacing: 1.2),
                              ),
                            ],
                          ),
                        ),
                        pw.Spacer(),
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text('SEBI Reg: INH000012345', style: pw.TextStyle(font: fontBold, fontSize: 6.5, color: PdfColor.fromHex('#1E3A5F'))),
                                  pw.Text('Status: ACTIVE / VERIFIED', style: pw.TextStyle(font: fontBold, fontSize: 6.5, color: PdfColors.green700)),
                                ],
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Container(
                                    width: 40,
                                    height: 12,
                                    decoration: const pw.BoxDecoration(
                                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.black, width: 0.8)),
                                    ),
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text('Auth Signatory', style: pw.TextStyle(font: fontBold, fontSize: 6)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 10),
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

  pw.Widget _buildPdfRow(String label, String value, pw.Font font, pw.Font fontBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(font: font, fontSize: 7.5, color: PdfColors.grey700)),
          pw.Text(
            value.length > 22 ? '${value.substring(0, 20)}...' : value,
            style: pw.TextStyle(font: fontBold, fontSize: 7.5, color: PdfColor.fromHex('#0F172A')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      elevation: 24,
      child: Container(
        width: 720,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Modern dark slate
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 32,
              offset: const Offset(0, 12),
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
                        color: AppTheme.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.4)),
                      ),
                      child: const Icon(Icons.badge, color: Color(0xFF60A5FA), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff Digital ID Card',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Official Verified Identity & Credential Badge',
                          style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Card Display Area (With Front / Back Switcher)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // The Visual Digital ID Card
                _buildDigitalIdCard(),

                const SizedBox(width: 32),

                // Controls & Actions Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle Front/Back Buttons
                      const Text(
                        'Card View',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => setState(() => _showFront = true),
                                icon: const Icon(Icons.credit_card, size: 16),
                                label: const Text('Front Side'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _showFront ? AppTheme.primaryBlue : Colors.transparent,
                                  foregroundColor: _showFront ? Colors.white : Colors.grey[400],
                                  elevation: _showFront ? 2 : 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => setState(() => _showFront = false),
                                icon: const Icon(Icons.flip_to_back, size: 16),
                                label: const Text('Back Side'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: !_showFront ? AppTheme.primaryBlue : Colors.transparent,
                                  foregroundColor: !_showFront ? Colors.white : Colors.grey[400],
                                  elevation: !_showFront ? 2 : 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Verification QR Details Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified, color: Colors.greenAccent, size: 16),
                                const SizedBox(width: 6),
                                const Text(
                                  'Public Verification URL',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _verificationUrl,
                              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _verificationUrl));
                                Get.snackbar(
                                  'Link Copied',
                                  'Verification link copied to clipboard.',
                                  backgroundColor: AppTheme.successGreen,
                                  colorText: Colors.white,
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              },
                              icon: const Icon(Icons.copy, size: 14),
                              label: const Text('Copy Verification Link', style: TextStyle(fontSize: 12)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF60A5FA),
                                side: const BorderSide(color: Color(0xFF3B82F6)),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action Buttons: Print & Download PDF
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isGeneratingPdf ? null : () => _downloadOrPrintPdf(isPrintOnly: false),
                          icon: _isGeneratingPdf
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.picture_as_pdf, size: 18),
                          label: const Text('Download High-Res PDF (CR80)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isGeneratingPdf ? null : () => _downloadOrPrintPdf(isPrintOnly: true),
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Print Badge Directly'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withOpacity(0.2)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            final staffCtrl = Get.isRegistered<StaffController>()
                                ? Get.find<StaffController>()
                                : Get.put(StaffController());
                            staffCtrl.populateForEdit(widget.staff);
                            Get.dialog(
                              AddStaffDialog(controller: staffCtrl),
                            );
                          },
                          icon: const Icon(Icons.edit_note, size: 18),
                          label: const Text('Edit Staff / Emergency Details'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF60A5FA),
                            side: const BorderSide(color: Color(0xFF3B82F6)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
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

  // Visual Interactive Digital ID Card widget
  Widget _buildDigitalIdCard() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return RotationTransition(
          turns: Tween(begin: 0.05, end: 0.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: _showFront ? _buildCardFront() : _buildCardBack(),
    );
  }

  Widget _buildCardFront() {
    final staff = widget.staff;
    final joinDateStr = _formatDate(staff.joiningDate);

    return Container(
      key: const ValueKey('front'),
      width: 290,
      height: 460,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
      ),
      child: Column(
        children: [
          // Lanyard Hole Design
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header with Corporate Logo and SEBI text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.token, color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 6),
                    const Text(
                      'RESEARCHVIA',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'SEBI REG. RESEARCH ANALYST',
                  style: TextStyle(
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF59E0B),
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Profile Image Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: staff.photoUrl != null && staff.photoUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 36,
                    backgroundImage: NetworkImage(AppConfig.buildImageUrl(staff.photoUrl)),
                  )
                : CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFF1E3A5F),
                    child: Text(
                      staff.name.isNotEmpty ? staff.name[0].toUpperCase() : 'S',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
          ),

          const SizedBox(height: 8),

          // Employee Full Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              staff.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(height: 4),

          // Designation Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Text(
              staff.department.isNotEmpty ? staff.department : staff.role,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4F46E5),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Details List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildCardInfoRow('Staff ID', staff.staffId, isHighlight: true),
                _buildCardInfoRow('Email', staff.email),
                _buildCardInfoRow('Mobile', staff.mobile),
                _buildCardInfoRow('Joined', joinDateStr),
              ],
            ),
          ),

          const Spacer(),

          // QR Code Scanner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QrImageView(
                  data: _verificationUrl,
                  version: QrVersions.auto,
                  size: 46.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF1E3A5F),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SCAN TO VERIFY',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3A5F),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Official Corporate ID',
                      style: TextStyle(fontSize: 8, color: Colors.grey[600]),
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

  Widget _buildCardBack() {
    final staff = widget.staff;
    final emergencyName = staff.emergencyContact?.name ?? 'N/A';
    final emergencyPhone = staff.emergencyContact?.phone ?? 'N/A';
    final emergencyRelation = staff.emergencyContact?.relation ?? 'N/A';

    return Container(
      key: const ValueKey('back'),
      width: 290,
      height: 460,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: const Color(0xFF1E3A5F), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Lanyard Hole Design
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 4),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // Back Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
            ),
            child: const Center(
              child: Text(
                'EMERGENCY & COMPLIANCE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Emergency Contact:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 2),
                Text(
                  (emergencyName.isNotEmpty && emergencyName != 'N/A')
                      ? '$emergencyName ($emergencyRelation)'
                      : 'Not Configured (Click Edit below)',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: (emergencyName.isNotEmpty && emergencyName != 'N/A')
                        ? const Color(0xFF334155)
                        : const Color(0xFFD97706),
                    fontStyle: (emergencyName.isNotEmpty && emergencyName != 'N/A')
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
                Text(
                  (emergencyPhone.isNotEmpty && emergencyPhone != 'N/A')
                      ? 'Phone: $emergencyPhone'
                      : 'Corporate Helpline: +91 22 6900 4400',
                  style: const TextStyle(fontSize: 9.5, color: Color(0xFF334155)),
                ),
                const Divider(height: 16),

                const Text(
                  'Corporate Headquarters:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'SP ResearchVia Global Markets Ltd.\nTower B, Financial District, BKC, Mumbai - 400051\nEmail: compliance@researchvia.com\nTel: +91 22 6900 4400',
                  style: TextStyle(fontSize: 8.5, color: Color(0xFF475569), height: 1.3),
                ),
                const Divider(height: 16),

                const Text(
                  'Terms & Conditions:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                ),
                const SizedBox(height: 2),
                const Text(
                  '• This card is the property of ResearchVia and is strictly non-transferable.\n'
                  '• Must be worn and produced on demand during official duties.\n'
                  '• If found, please return to the corporate address above.',
                  style: TextStyle(fontSize: 7.8, color: Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Signature & Verification Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('SEBI: INH000012345', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                    Text('Status: VERIFIED', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      width: 60,
                      height: 1,
                      color: Colors.black54,
                    ),
                    const SizedBox(height: 2),
                    const Text('Auth Signatory', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9.5, color: Colors.grey[600]),
          ),
          Text(
            value.length > 20 ? '${value.substring(0, 18)}...' : value,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? const Color(0xFF1E3A5F) : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}
