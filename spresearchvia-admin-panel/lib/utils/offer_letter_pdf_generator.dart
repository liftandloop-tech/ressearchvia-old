import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/staff.model.dart';

class OfferLetterPdfGenerator {
  static Future<Uint8List> generate({
    required StaffModel applicant,
    required String designation,
    required String joiningDate,
    required String issueDate,
  }) async {
    final doc = pw.Document();

    // Standard PDF fonts for crisp rendering
    final fontBold = pw.Font.helveticaBold();
    final fontRegular = pw.Font.helvetica();

    // Load official template background from assets
    final ByteData bgData = await rootBundle.load('assets/images/offer_letter_template_bg.png');
    final Uint8List bgBytes = bgData.buffer.asUint8List();
    final bgImage = pw.MemoryImage(bgBytes);

    final candidateName = applicant.name.trim().isNotEmpty &&
            applicant.name.trim().toLowerCase() != 'candidate' &&
            applicant.name.trim() != '—'
        ? applicant.name.trim()
        : (applicant.fullName.trim().isNotEmpty
            ? applicant.fullName.trim()
            : 'Candidate');

    // Format address
    String address1 = '';
    String address2 = '';
    final raw = applicant.rawJson ?? {};
    final curAddr = raw['currentAddress'];
    if (curAddr is Map) {
      final line1 = [curAddr['addressLine1'] ?? curAddr['line1'] ?? curAddr['street']]
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .join(', ');
      final line2 = [curAddr['city'], curAddr['state'], curAddr['pincode'] ?? curAddr['pinCode']]
          .where((e) => e != null && e.toString().trim().isNotEmpty)
          .join(', ');
      address1 = line1;
      address2 = line2;
    } else if (applicant.localAddress?.isNotEmpty == true) {
      address1 = applicant.localAddress!;
    } else if (applicant.permanentAddress?.isNotEmpty == true) {
      address1 = applicant.permanentAddress!;
    } else if (applicant.currentLocation?.isNotEmpty == true) {
      address1 = applicant.currentLocation!;
    }

    final contact = [
      if (applicant.mobile.isNotEmpty && applicant.mobile != '—') applicant.mobile,
      if (applicant.email.isNotEmpty && applicant.email != '—') applicant.email,
    ].join(' | ');

    final effectiveDesignation = designation.trim().isNotEmpty
        ? designation.trim()
        : 'Business Development Executive';
    final effectiveJoiningDate = joiningDate.trim().isNotEmpty ? joiningDate.trim() : '10/11/2026';
    final effectiveIssueDate = issueDate.trim().isNotEmpty ? issueDate.trim() : '04/11/2026';

    // Calculate font size for designation in the inline sentence
    // Gap between "as " (ends ~254) and "commencing" (starts ~338) is 82pt
    const double maxRoleWidth = 80.0;
    final double estWidth = effectiveDesignation.length * 0.54 * 8.5;
    final double roleSize = estWidth > maxRoleWidth ? max(4.8, (maxRoleWidth / estWidth) * 8.5) : 8.5;

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // Official template letterhead, SEBI registration, and watermark background
              pw.Positioned.fill(
                child: pw.Image(bgImage, fit: pw.BoxFit.fill),
              ),

              // 1. DATE: placed to the right of "DATE: "
              pw.Positioned(
                left: 500,
                top: 188,
                child: pw.Text(
                  effectiveIssueDate,
                  style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.black),
                ),
              ),

              // 2. Name: placed to the right of "Name"
              pw.Positioned(
                left: 135,
                top: 202,
                child: pw.Text(
                  candidateName,
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.black),
                ),
              ),

              // 3. Address: placed to the right of "Address"
              pw.Positioned(
                left: 135,
                top: 228,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    if (address1.isNotEmpty)
                      pw.Text(
                        address1,
                        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
                      ),
                    if (address2.isNotEmpty)
                      pw.Text(
                        address2,
                        style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
                      ),
                  ],
                ),
              ),

              // 4. Contact: placed to the right of "Contact"
              if (contact.isNotEmpty)
                pw.Positioned(
                  left: 135,
                  top: 257,
                  child: pw.Text(
                    contact,
                    style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: PdfColors.black),
                  ),
                ),

              // 5. Dear: placed to the right of "Dear "
              pw.Positioned(
                left: 98,
                top: 304,
                child: pw.Text(
                  '$candidateName,',
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.black),
                ),
              ),

              // 6. Congratulations and welcome to: placed to the right of "welcome to "
              pw.Positioned(
                left: 232,
                top: 326.5,
                child: pw.Text(
                  'SP RESEARCHVIA PVT. LTD.',
                  style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: PdfColors.black),
                ),
              ),

              // 7. We are pleased to offer you a position as ... commencing on ...:
              pw.Positioned(
                left: 256,
                top: 350 + (8.5 - roleSize) * 0.5,
                child: pw.Text(
                  effectiveDesignation,
                  style: pw.TextStyle(font: fontBold, fontSize: roleSize, color: PdfColors.black),
                ),
              ),
              pw.Positioned(
                left: 426,
                top: 349.5,
                child: pw.Text(
                  effectiveJoiningDate,
                  style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: PdfColors.black),
                ),
              ),

              // 8. Designation : placed to the right of "Designation :"
              pw.Positioned(
                left: 165,
                top: 489,
                child: pw.Text(
                  effectiveDesignation,
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.black),
                ),
              ),

              // 9. Date of joining : placed to the right of "Date of joining :"
              pw.Positioned(
                left: 165,
                top: 512,
                child: pw.Text(
                  effectiveJoiningDate,
                  style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.black),
                ),
              ),

              // 10. For: placed to the right of "For "
              pw.Positioned(
                left: 98,
                top: 556,
                child: pw.Text(
                  'SP RESEARCHVIA PVT. LTD.',
                  style: pw.TextStyle(font: fontBold, fontSize: 10, color: PdfColors.black),
                ),
              ),

              // Authorized Signatory section
              pw.Positioned(
                left: 72,
                top: 640,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(width: 130, height: 0.8, color: PdfColor.fromHex('#94A3B8')),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Authorized Signatory',
                      style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.black),
                    ),
                    pw.Text(
                      'SP RESEARCHVIA PVT. LTD.',
                      style: pw.TextStyle(font: fontRegular, fontSize: 8, color: PdfColor.fromHex('#475569')),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
