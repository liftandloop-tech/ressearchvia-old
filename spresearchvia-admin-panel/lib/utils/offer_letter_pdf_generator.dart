import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/staff.model.dart';

class OfferLetterPdfGenerator {
  static Future<Uint8List> generate({
    required StaffModel applicant,
    required String designation,
    required String joiningDate,
    required String issueDate,
  }) async {
    final doc = pw.Document();

    final fontRegular = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();
    final fontItalic = await PdfGoogleFonts.notoSansItalic();

    final brandNavy = PdfColor.fromHex('#163174');
    final darkCharcoal = PdfColor.fromHex('#1E293B');
    final textGrey = PdfColor.fromHex('#475569');
    final lightBorder = PdfColor.fromHex('#CBD5E1');

    final candidateName = applicant.name.trim().isNotEmpty &&
            applicant.name.trim().toLowerCase() != 'candidate' &&
            applicant.name.trim() != '—'
        ? applicant.name.trim()
        : (applicant.fullName.trim().isNotEmpty
            ? applicant.fullName.trim()
            : 'Candidate');

    final refNo = 'RVI/OFFER/${applicant.staffId.isNotEmpty ? applicant.staffId : (applicant.id.length >= 8 ? applicant.id.substring(applicant.id.length - 8).toUpperCase() : '2026')}';

    // Format address
    String addressStr = '';
    final raw = applicant.rawJson ?? {};
    final curAddr = raw['currentAddress'];
    if (curAddr is Map) {
      final parts = [
        curAddr['addressLine1'] ?? curAddr['line1'],
        curAddr['addressLine2'] ?? curAddr['line2'],
        curAddr['city'],
        curAddr['state'],
        curAddr['pincode'] ?? curAddr['pinCode']
      ].where((e) => e != null && e.toString().trim().isNotEmpty).map((e) => e.toString().trim());
      addressStr = parts.join(', ');
    } else if (applicant.localAddress?.isNotEmpty == true) {
      addressStr = applicant.localAddress!;
    } else if (applicant.permanentAddress?.isNotEmpty == true) {
      addressStr = applicant.permanentAddress!;
    } else if (applicant.currentLocation?.isNotEmpty == true) {
      addressStr = applicant.currentLocation!;
    }

    final contactLine = [
      if (applicant.mobile.isNotEmpty && applicant.mobile != '—') applicant.mobile,
      if (applicant.email.isNotEmpty && applicant.email != '—') applicant.email,
    ].join(' | ');

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── 1. HEADER & BRANDING ──────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SP RESEARCHVIA PRIVATE LIMITED',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 15,
                          color: brandNavy,
                          letterSpacing: 0.5,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Corporate Office: 129 A, Kalani Bagh, AB Road, Dewas, MP - 455001',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 8.5,
                          color: textGrey,
                        ),
                      ),
                      pw.Text(
                        'Email: info@researchvia.in | Web: www.researchvia.in',
                        style: pw.TextStyle(
                          font: fontRegular,
                          fontSize: 8.5,
                          color: textGrey,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F5F9'),
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: lightBorder),
                    ),
                    child: pw.Text(
                      'OFFICIAL APPOINTMENT',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 8.5,
                        color: brandNavy,
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Container(height: 1.5, color: brandNavy),
              pw.SizedBox(height: 12),

              // ── 2. REF & DATE ──────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Ref: $refNo',
                    style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: darkCharcoal),
                  ),
                  pw.Text(
                    'Date: $issueDate',
                    style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: darkCharcoal),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // ── 3. CANDIDATE DETAILS ───────────────────────────────────
              pw.Text('To,', style: pw.TextStyle(font: fontRegular, fontSize: 9.5, color: darkCharcoal)),
              pw.Text(candidateName, style: pw.TextStyle(font: fontBold, fontSize: 11, color: darkCharcoal)),
              if (addressStr.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Text(
                    addressStr,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: textGrey),
                  ),
                ),
              if (contactLine.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 1),
                  child: pw.Text(
                    contactLine,
                    style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: textGrey),
                  ),
                ),
              pw.SizedBox(height: 12),

              // ── 4. TITLE ───────────────────────────────────────────────
              pw.Center(
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F8FAFC'),
                    borderRadius: pw.BorderRadius.circular(4),
                    border: pw.Border.all(color: lightBorder),
                  ),
                  child: pw.Text(
                    'SUB: OFFER-CUM-APPOINTMENT LETTER FOR $designation',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 10,
                      color: brandNavy,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
              pw.SizedBox(height: 10),

              // ── 5. OPENING & BODY ──────────────────────────────────────
              pw.Text(
                'Dear $candidateName,',
                style: pw.TextStyle(font: fontBold, fontSize: 10, color: darkCharcoal),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Congratulations and welcome to SP RESEARCHVIA PVT. LTD. We are pleased to offer you an appointment for the position of "$designation" in our organization commencing on or before $joiningDate.',
                style: pw.TextStyle(font: fontRegular, fontSize: 9, color: darkCharcoal, lineSpacing: 2),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Your employment with the Company shall be governed by the standard terms and conditions set forth below:',
                style: pw.TextStyle(font: fontRegular, fontSize: 8.5, color: darkCharcoal),
              ),
              pw.SizedBox(height: 8),

              // ── 6. KEY TERMS & CLAUSES ─────────────────────────────────
              _buildClause(fontBold, fontRegular, '1. Designation & Role:', 'You will be positioned as "$designation". You will perform the duties assigned to you by your reporting supervisor and management diligently and effectively.'),
              _buildClause(fontBold, fontRegular, '2. Date of Joining:', 'You are required to report to duty on $joiningDate. Failure to report by this date without prior written approval may lead to revocation of this offer.'),
              _buildClause(fontBold, fontRegular, '3. Place of Posting:', 'Your initial posting will be at the Company offices in Indore / Dewas, Madhya Pradesh. However, the Company reserves the right to transfer or reassign you based on operational requirements.'),
              _buildClause(fontBold, fontRegular, '4. Probation & Confirmation:', 'You will be on probation for a period of three (3) to six (6) months from your date of joining. Upon successful evaluation of your performance, your employment will be confirmed in writing.'),
              _buildClause(fontBold, fontRegular, '5. Remuneration & Benefits:', 'Your total compensation package will be as mutually agreed during the interview and outlined in your detailed compensation Annexure.'),
              _buildClause(fontBold, fontRegular, '6. Strict Confidentiality & Code of Conduct:', 'You agree to maintain the strictest confidentiality regarding all proprietary research, trading tools, software systems, client lists, and confidential business information during and after your employment.'),
              _buildClause(fontBold, fontRegular, '7. Notice Period & Termination:', 'During probation, either party may terminate this agreement with seven (7) days written notice. Post-confirmation, a 30-day notice period or salary in lieu thereof will be applicable.'),

              pw.SizedBox(height: 10),
              pw.Text(
                'Please sign and return the duplicate copy of this letter as an acceptance of this offer and its associated terms.',
                style: pw.TextStyle(font: fontItalic, fontSize: 8.5, color: textGrey),
              ),
              pw.Spacer(),

              // ── 7. SIGNATURE BLOCK ─────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'For SP RESEARCHVIA PVT. LTD.',
                        style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: brandNavy),
                      ),
                      pw.SizedBox(height: 34),
                      pw.Container(width: 150, height: 1, color: lightBorder),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Authorized Signatory',
                        style: pw.TextStyle(font: fontBold, fontSize: 9, color: darkCharcoal),
                      ),
                      pw.Text(
                        'HR & Operations Department',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: textGrey),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Candidate Acceptance:',
                        style: pw.TextStyle(font: fontBold, fontSize: 9.5, color: darkCharcoal),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'I accept the terms and conditions outlined above.',
                        style: pw.TextStyle(font: fontRegular, fontSize: 7.5, color: textGrey),
                      ),
                      pw.SizedBox(height: 26),
                      pw.Container(width: 170, height: 1, color: lightBorder),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Signature: __________________________',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: darkCharcoal),
                      ),
                      pw.Text(
                        'Date: ______ / ______ / 2026',
                        style: pw.TextStyle(font: fontRegular, fontSize: 8, color: textGrey),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _buildClause(pw.Font bold, pw.Font regular, String title, String description) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$title ',
              style: pw.TextStyle(font: bold, fontSize: 8.5, color: PdfColor.fromHex('#1E293B')),
            ),
            pw.TextSpan(
              text: description,
              style: pw.TextStyle(font: regular, fontSize: 8.5, color: PdfColor.fromHex('#334155'), lineSpacing: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
