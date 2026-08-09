import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoicePdfGenerator {
  static final _fmtCurrency = NumberFormat('#,##,###.##');

  static String _fmt(double val) => '₹${_fmtCurrency.format(val)}';

  static double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static String _formatPaymentMode(String rawMode) {
    final m = rawMode.trim().toUpperCase();
    if (m.isEmpty ||
        m == 'BANK_TRANSFER' ||
        m == 'OFFLINE' ||
        m == 'MANUAL' ||
        m == 'BANK' ||
        m.contains('TRANSFER'))
      return 'Bank Transfer';
    if (m == 'UPI' ||
        m == 'NETBANKING' ||
        m == 'CARD' ||
        m == 'EMI' ||
        m == 'ONLINE' ||
        m == 'RAZORPAY')
      return 'Online';
    return rawMode
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String _formatInvoiceNumber(String invoiceNo) {
    if (invoiceNo.isEmpty) return 'N/A';
    if (invoiceNo.length >= 24 &&
        RegExp(r'^[a-f0-9]+$').hasMatch(invoiceNo.substring(0, 24))) {
      return invoiceNo.substring(0, 12).toUpperCase();
    }
    if (invoiceNo.length > 20) return invoiceNo.substring(0, 20).toUpperCase();
    return invoiceNo.toUpperCase();
  }

  static Future<void> printInvoice(Map<String, dynamic> payment) async {
    final user = payment['userId'] is Map
        ? Map<String, dynamic>.from(payment['userId'] as Map)
        : <String, dynamic>{};
    final planData = payment['segmentPlanId'];
    final Map<String, dynamic> plan = (planData is Map)
        ? Map<String, dynamic>.from(planData as Map)
        : {};
    final isRegistration = payment['purchaseType'] == 'REGISTRATION';

    final List<dynamic> history = (payment['partialPaymentsHistory'] is List)
        ? (payment['partialPaymentsHistory'] as List<dynamic>)
              .where((e) => e['status'] != 'REJECTED')
              .toList()
        : [];

    final double amountPaid = history.isEmpty
        ? (payment['status'] == 'REJECTED'
              ? 0.0
              : _toDouble(payment['amountPaid']))
        : history.fold(
            0.0,
            (sum, item) =>
                sum + _toDouble(item['amountPaid'] ?? item['amount']),
          );

    final double totalAmount = _toDouble(payment['amount']);
    final double discount = _toDouble(payment['discount']);
    final double remaining = totalAmount - discount - amountPaid;
    final double baseAmount = totalAmount / 1.18;
    final double gstTotal = totalAmount - baseAmount;
    final double cgst = gstTotal / 2;
    final double sgst = gstTotal / 2;

    final bool isPartial = payment['isPartial'] == true;

    String planNameDisplay = isRegistration
        ? (user['registrationType']?.toString().toUpperCase() == 'LIFETIME'
              ? 'Gold Registration'
              : 'Silver Registration')
        : (plan['segmentsName'] != null &&
                  plan['segmentsName'].toString().isNotEmpty
              ? '${plan['planName']} (${plan['segmentsName']})'
              : (plan['planName'] ?? 'Subscription'));

    final date =
        DateTime.tryParse(payment['createdAt'] ?? '') ?? DateTime.now();
    final String rawInvoice =
        payment['invoiceNumber']?.toString() ??
        payment['invoiceNo']?.toString() ??
        (payment['_id'] ?? '').toString();
    final invoiceNo = _formatInvoiceNumber(rawInvoice);
    final paymentModeDisplay = _formatPaymentMode(
      payment['paymentMethod']?.toString() ??
          payment['paymentMode']?.toString() ??
          'BANK_TRANSFER',
    );
    final paymentRefId =
        payment['paymentRefId']?.toString() ??
        payment['utrNumber']?.toString() ??
        payment['razorpayOrderId']?.toString() ??
        'N/A';

    // Colors
    final brandBlue = PdfColor.fromHex('#163174');
    final lightGrey = PdfColor.fromHex('#F9FAFB');
    final textGrey = PdfColor.fromHex('#6B7280');

    // Fonts (Google Fonts via printing package)
    final font = await PdfGoogleFonts.notoSansRegular();
    final fontBold = await PdfGoogleFonts.notoSansBold();

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          final widgets = <pw.Widget>[
            // ── HEADER ──────────────────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SP RESEARCHVIA',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 20,
                        color: brandBlue,
                      ),
                    ),
                    pw.Text(
                      'PRIVATE LIMITED',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 11,
                        color: brandBlue,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      '129 A, Kalani Bagh, AB Road\nDewas, MP - 455001\ninfo@researchvia.in',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 9,
                        color: textGrey,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'GSTIN: 23ABMCS3444G1ZC',
                      style: pw.TextStyle(font: fontBold, fontSize: 9),
                    ),
                    pw.Text(
                      'SEBI REG: INH000015808',
                      style: pw.TextStyle(font: fontBold, fontSize: 9),
                    ),
                    pw.Text(
                      'CIN: U73200MP2023PTC069041',
                      style: pw.TextStyle(font: fontBold, fontSize: 9),
                    ),
                    pw.Text(
                      'BSE Enlistment no. : 6120',
                      style: pw.TextStyle(font: fontBold, fontSize: 9),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'INVOICE',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 28,
                        color: PdfColors.grey400,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _metaRow(
                      'Invoice No:',
                      invoiceNo,
                      font,
                      fontBold,
                      brandBlue: brandBlue,
                    ),
                    _metaRow(
                      'Date:',
                      DateFormat('dd MMM yyyy').format(date),
                      font,
                      fontBold,
                      brandBlue: brandBlue,
                    ),
                    _metaRow(
                      'Status:',
                      payment['status']?.toString().toUpperCase() == 'REJECTED'
                          ? 'REJECTED'
                          : (remaining <= 0 ? 'PAID' : 'PARTIALLY PAID'),
                      font,
                      fontBold,
                      brandBlue: brandBlue,
                      valueColor:
                          payment['status']?.toString().toUpperCase() ==
                              'REJECTED'
                          ? PdfColors.red700
                          : (remaining <= 0
                                ? PdfColors.green700
                                : PdfColors.orange700),
                    ),
                    _metaRow(
                      'Payment Mode:',
                      paymentModeDisplay,
                      font,
                      fontBold,
                      brandBlue: brandBlue,
                    ),
                  ],
                ),
              ],
            ),

            pw.Divider(height: 24, color: PdfColors.grey300),

            // ── BILL TO ─────────────────────────────────────────────────────
            pw.Text(
              'BILL TO',
              style: pw.TextStyle(font: fontBold, fontSize: 9, color: textGrey),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              user['fullName'] ?? '-',
              style: pw.TextStyle(font: fontBold, fontSize: 13),
            ),
            pw.Text(
              user['phone'] ?? '-',
              style: pw.TextStyle(font: font, fontSize: 11),
            ),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1.5),
              },
              border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: brandBlue),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'DESCRIPTION',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'BREAKDOWN',
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'AMOUNT',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            planNameDisplay,
                            style: pw.TextStyle(font: fontBold, fontSize: 10),
                          ),
                          if (isPartial && remaining > 0)
                            pw.Text(
                              '(Partial Payment Plan)',
                              style: pw.TextStyle(
                                font: font,
                                fontSize: 8,
                                color: PdfColors.orange700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Subtotal (Base):',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _fmt(baseAmount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'CGST (9%):',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _fmt(cgst),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'SGST (9%):',
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _fmt(sgst),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: font, fontSize: 9),
                      ),
                    ),
                  ],
                ),
                if (discount > 0)
                  pw.TableRow(
                    children: [
                      pw.SizedBox(),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Discount:',
                          style: pw.TextStyle(font: font, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          '-${_fmt(discount)}',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 9,
                            color: PdfColors.red700,
                          ),
                        ),
                      ),
                    ],
                  ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Total Payable:',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _fmt(totalAmount - discount),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                pw.TableRow(
                  children: [
                    pw.SizedBox(),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount Paid:',
                        style: pw.TextStyle(font: fontBold, fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _fmt(amountPaid),
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                          font: fontBold,
                          fontSize: 9,
                          color: PdfColors.green700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (remaining > 0)
                  pw.TableRow(
                    children: [
                      pw.SizedBox(),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'Balance Due:',
                          style: pw.TextStyle(font: fontBold, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          _fmt(remaining),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: PdfColors.orange700,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            pw.SizedBox(height: 24),
          ];

          // ── INSTALLMENT HISTORY ────────────────────────────────────────────
          if (isPartial && history.isNotEmpty) {
            widgets.addAll([
              pw.Text(
                'INSTALLMENT HISTORY',
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 11,
                  color: brandBlue,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                columnWidths: const {
                  0: pw.FlexColumnWidth(2.5),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(1.5),
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey200,
                  width: 0.5,
                ),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: brandBlue),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'DATE',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'BREAKDOWN',
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          'AMOUNT',
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            font: fontBold,
                            fontSize: 9,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  ...history.asMap().entries.expand((entry) {
                    final idx = entry.key;
                    final inst = entry.value;
                    final instAmount = _toDouble(inst['amountPaid']);
                    final instTaxable = instAmount / 1.18;
                    final instGst = instAmount - instTaxable;
                    final instDate =
                        DateTime.tryParse(
                          inst['transactionDate']?.toString() ?? '',
                        ) ??
                        DateTime.now();
                    final dateStr =
                        '${idx + 1}. ${DateFormat('dd MMM yyyy').format(instDate)}';

                    return [
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              dateStr,
                              style: pw.TextStyle(font: fontBold, fontSize: 10),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Subtotal (Base):',
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              _fmt(instTaxable),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.SizedBox(),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'GST:',
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              _fmt(instGst),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(font: font, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.SizedBox(),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              'Total Paid:',
                              style: pw.TextStyle(font: fontBold, fontSize: 9),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              _fmt(instAmount),
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                font: fontBold,
                                fontSize: 9,
                                color: PdfColors.green700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ];
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 24),
            ]);
          }

          // ── ADDITIONAL INFORMATION ─────────────────────────────────────────
          widgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightGrey,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'ADDITIONAL INFORMATION',
                    style: pw.TextStyle(
                      font: fontBold,
                      fontSize: 11,
                      color: brandBlue,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  _addlRow(
                    'Payment Ref ID:',
                    paymentRefId,
                    font,
                    fontBold,
                    textGrey: textGrey,
                  ),
                  _addlRow(
                    'Payment Mode:',
                    paymentModeDisplay,
                    font,
                    fontBold,
                    textGrey: textGrey,
                  ),
                  _addlRow(
                    'Generated By:',
                    'ResearchVia Admin',
                    font,
                    fontBold,
                    textGrey: textGrey,
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Authorized Signatory:',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      color: textGrey,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '[Digital Signature]',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 9,
                      fontStyle: pw.FontStyle.italic,
                      color: PdfColors.grey500,
                    ),
                  ),
                ],
              ),
            ),
          );

          // ── FOOTER ────────────────────────────────────────────────────────
          widgets.addAll([
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'This is a computer-generated invoice. No physical signature required.',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: textGrey,
                    ),
                  ),
                  pw.Text(
                    'Support: support@researchvia.in | SP ResearchVia Pvt. Ltd.',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 8,
                      color: PdfColors.grey400,
                    ),
                  ),
                ],
              ),
            ),
          ]);

          return widgets;
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) async => doc.save(),
      name: 'Invoice_$invoiceNo.pdf',
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static pw.Widget _metaRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold, {
    PdfColor? valueColor,
    required PdfColor brandBlue,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: font,
            fontSize: 9,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: fontBold,
            fontSize: 9,
            color: valueColor ?? brandBlue,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _priceRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold, {
    bool isBold = false,
    PdfColor? valueColor,
    double fontSize = 10,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: isBold ? fontBold : font,
            fontSize: fontSize,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            font: isBold ? fontBold : font,
            fontSize: fontSize,
            color: valueColor,
          ),
        ),
      ],
    ),
  );

  static pw.Widget _addlRow(
    String label,
    String value,
    pw.Font font,
    pw.Font fontBold, {
    required PdfColor textGrey,
  }) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 2),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(font: font, fontSize: 9, color: textGrey),
        ),
        pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 9)),
      ],
    ),
  );
}
