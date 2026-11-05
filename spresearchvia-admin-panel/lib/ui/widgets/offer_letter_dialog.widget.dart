import 'dart:js_interop';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:spresearch_web/services/applicant.service.dart';
import 'package:web/web.dart' as web;

class OfferLetterDialog extends StatefulWidget {
  final StaffModel applicant;
  final VoidCallback? onSuccess;

  const OfferLetterDialog({
    super.key,
    required this.applicant,
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required StaffModel applicant,
    VoidCallback? onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => OfferLetterDialog(
        applicant: applicant,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<OfferLetterDialog> createState() => _OfferLetterDialogState();
}

class _OfferLetterDialogState extends State<OfferLetterDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _designationCtrl;
  late TextEditingController _joiningDateCtrl;
  late TextEditingController _issueDateCtrl;
  late TextEditingController _noteCtrl;

  bool _isPreviewLoading = false;
  bool _isSending = false;
  String? _statusMessage;
  bool _isError = false;
  Uint8List? _previewBytes;
  String? _blobUrl;

  late final ApplicantService _applicantService = Get.isRegistered<ApplicantService>()
      ? Get.find<ApplicantService>()
      : Get.put(ApplicantService());

  @override
  void initState() {
    super.initState();
    final applicant = widget.applicant;

    // Resolve prefilled role/designation
    String defaultRole = applicant.role.isNotEmpty && applicant.role != 'Applicant'
        ? applicant.role
        : (applicant.currentDesignation?.isNotEmpty == true
            ? applicant.currentDesignation!
            : 'Business Development Executive');

    // Default joining date: existing joiningDate or +7 days
    DateTime defaultJoinDt = applicant.joiningDate ?? DateTime.now().add(const Duration(days: 7));
    String joinStr = _formatDate(defaultJoinDt);

    // Default issue date: Today
    String issueStr = _formatDate(DateTime.now());

    _designationCtrl = TextEditingController(text: defaultRole);
    _joiningDateCtrl = TextEditingController(text: joinStr);
    _issueDateCtrl = TextEditingController(text: issueStr);
    _noteCtrl = TextEditingController(text: 'Offer-cum-Appointment letter issued for $defaultRole.');
  }

  @override
  void dispose() {
    _designationCtrl.dispose();
    _joiningDateCtrl.dispose();
    _issueDateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    return '$d/$m/$y';
  }

  DateTime? _parseDate(String str) {
    try {
      final parts = str.trim().split('/');
      if (parts.length == 3) {
        final d = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final y = int.parse(parts[2]);
        return DateTime(y, m, d);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _selectJoiningDate() async {
    final parsed = _parseDate(_joiningDateCtrl.text);
    final initial = (parsed != null && parsed.isAfter(DateTime(1999, 12, 31)) && parsed.isBefore(DateTime(2101, 1, 1)))
        ? parsed
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _joiningDateCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _selectIssueDate() async {
    final parsed = _parseDate(_issueDateCtrl.text);
    final initial = (parsed != null && parsed.isAfter(DateTime(1999, 12, 31)) && parsed.isBefore(DateTime(2101, 1, 1)))
        ? parsed
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4F46E5),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _issueDateCtrl.text = _formatDate(picked);
      });
    }
  }

  String _resolveCandidateAddress() {
    final raw = widget.applicant.rawJson ?? {};
    final curAddr = raw['currentAddress'];
    if (curAddr != null) {
      if (curAddr is Map) {
        final parts = [
          curAddr['addressLine1'] ?? curAddr['line1'],
          curAddr['addressLine2'] ?? curAddr['line2'],
          curAddr['city'],
          curAddr['state'],
          curAddr['pincode'] ?? curAddr['pinCode']
        ].where((e) => e != null && e.toString().trim().isNotEmpty).map((e) => e.toString().trim());
        if (parts.isNotEmpty) return parts.join(', ');
      } else if (curAddr.toString().trim().isNotEmpty) {
        return curAddr.toString().trim();
      }
    }
    if (widget.applicant.localAddress?.isNotEmpty == true) {
      return widget.applicant.localAddress!;
    }
    if (widget.applicant.permanentAddress?.isNotEmpty == true) {
      return widget.applicant.permanentAddress!;
    }
    if (widget.applicant.currentLocation?.isNotEmpty == true) {
      return widget.applicant.currentLocation!;
    }
    return 'Not provided in application';
  }

  Future<void> _handlePreview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isPreviewLoading = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      final res = await _applicantService.previewOfferLetter(
        widget.applicant.id,
        applicant: widget.applicant,
        designation: _designationCtrl.text.trim(),
        joiningDate: _joiningDateCtrl.text.trim(),
        issueDate: _issueDateCtrl.text.trim(),
      );

      if (res.success && res.bytes != null) {
        _previewBytes = res.bytes;
        final blob = web.Blob(
          [res.bytes!.toJS].toJS,
          web.BlobPropertyBag(type: 'application/pdf'),
        );
        _blobUrl = web.URL.createObjectURL(blob);

        // Open in browser interactive PDF viewer
        try {
          await Printing.layoutPdf(
            onLayout: (_) async => res.bytes!,
            name: res.fileName ?? 'Offer_Letter.pdf',
          );
        } catch (_) {
          if (_blobUrl != null) {
            web.window.open(_blobUrl!, '_blank');
          }
        }

        setState(() {
          _statusMessage = 'Official Offer-cum-Appointment Letter preview generated.';
          _isError = false;
        });
      } else {
        setState(() {
          _statusMessage = res.message ?? 'Failed to generate preview PDF';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Preview error: $e';
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isPreviewLoading = false);
      }
    }
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.applicant.email.isEmpty) {
      Get.snackbar(
        'Missing Email',
        'This applicant does not have a registered email address to receive the offer letter.',
        backgroundColor: const Color(0xFFFEF2F2),
        colorText: const Color(0xFFDC2626),
        snackPosition: SnackPosition.TOP,
      );
      return;
    }

    setState(() {
      _isSending = true;
      _statusMessage = null;
      _isError = false;
    });

    try {
      final res = await _applicantService.sendOfferLetter(
        widget.applicant.id,
        designation: _designationCtrl.text.trim(),
        joiningDate: _joiningDateCtrl.text.trim(),
        issueDate: _issueDateCtrl.text.trim(),
        customNote: _noteCtrl.text.trim(),
      );

      if (res.success) {
        Get.back(); // close dialog
        Get.snackbar(
          'Offer Letter Dispatched',
          res.message ?? 'Offer letter successfully sent to ${widget.applicant.email}!',
          backgroundColor: const Color(0xFFF0FDF4),
          colorText: const Color(0xFF16A34A),
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
        widget.onSuccess?.call();
      } else {
        setState(() {
          _statusMessage = res.message ?? 'Failed to send offer letter.';
          _isError = true;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Dispatch error: $e';
        _isError = true;
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final applicant = widget.applicant;
    final addressText = _resolveCandidateAddress();
    final bool hasExistingOffer = applicant.stage == 'OFFER_SENT' ||
        applicant.rawJson?['offerLetterUrl'] != null;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF4F46E5), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Issue Offer-cum-Appointment Letter',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Fill in position details, preview the official document, and email to candidate.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Color(0xFF94A3B8)),
                      onPressed: (_isSending || _isPreviewLoading) ? null : () => Get.back(),
                      splashRadius: 18,
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 18),

                // Existing offer notice
                if (hasExistingOffer) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'An offer letter was previously sent to this candidate. Sending again will issue an updated letter and send an email notification.',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF166534), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Candidate Details Snapshot Card (Auto-filled from application)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, size: 16, color: Color(0xFF4F46E5)),
                              const SizedBox(width: 6),
                              Text(
                                applicant.name.isNotEmpty ? applicant.name : 'Candidate',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              applicant.stage.isNotEmpty ? applicant.stage : 'APPLIED',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              applicant.email.isNotEmpty ? applicant.email : 'No email provided',
                              style: TextStyle(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.phone_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            applicant.mobile.isNotEmpty ? applicant.mobile : 'No mobile',
                            style: TextStyle(fontSize: 12, color: const Color(0xFF334155), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              addressText,
                              style: TextStyle(fontSize: 11.5, color: const Color(0xFF64748B)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Form Fields
                // 1. Designation
                const Text(
                  'Position / Designation *',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _designationCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Business Development Executive',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.badge_outlined, size: 18, color: Color(0xFF64748B)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter the designation / position' : null,
                ),

                const SizedBox(height: 14),

                // 2. Dates Row: Joining Date & Issue Date
                Row(
                  children: [
                    // Joining Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Joining (DD/MM/YYYY) *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _joiningDateCtrl,
                            decoration: InputDecoration(
                              hintText: 'DD/MM/YYYY',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.event_available_outlined, size: 18, color: Color(0xFF64748B)),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF4F46E5)),
                                onPressed: _selectJoiningDate,
                                splashRadius: 18,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                            ),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Issue Date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date of Issue (DD/MM/YYYY) *',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _issueDateCtrl,
                            decoration: InputDecoration(
                              hintText: 'DD/MM/YYYY',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              prefixIcon: const Icon(Icons.today_outlined, size: 18, color: Color(0xFF64748B)),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month_outlined, size: 18, color: Color(0xFF4F46E5)),
                                onPressed: _selectIssueDate,
                                splashRadius: 18,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                            ),
                            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 3. Admin Custom Note (optional)
                const Text(
                  'Internal Note / Timeline Remark (Optional)',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. Cleared 2 rounds of interview. Selected by Yashraj.',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5)),
                  ),
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  maxLines: 2,
                ),

                // Status message banner
                if (_statusMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isError ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _isError ? const Color(0xFFFECACA) : const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                              color: _isError ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _statusMessage!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isError ? const Color(0xFF991B1B) : const Color(0xFF1E40AF),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_previewBytes != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  Printing.layoutPdf(
                                    onLayout: (_) async => _previewBytes!,
                                    name: 'Offer_Letter_${widget.applicant.name.replaceAll(' ', '_')}.pdf',
                                  );
                                },
                                icon: const Icon(Icons.print_outlined, size: 14),
                                label: const Text('Print / Save PDF', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF1E40AF),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  backgroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (_blobUrl != null)
                                TextButton.icon(
                                  onPressed: () {
                                    web.window.open(_blobUrl!, '_blank');
                                  },
                                  icon: const Icon(Icons.open_in_new_rounded, size: 14),
                                  label: const Text('Open in New Tab', style: TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E40AF),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(6),
                                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 18),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Preview Button
                    OutlinedButton.icon(
                      onPressed: (_isPreviewLoading || _isSending) ? null : _handlePreview,
                      icon: _isPreviewLoading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4F46E5)),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined, size: 16),
                      label: Text(
                        _isPreviewLoading ? 'Generating...' : 'Preview PDF',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        side: const BorderSide(color: Color(0xFF818CF8)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),

                    Row(
                      children: [
                        TextButton(
                          onPressed: (_isSending || _isPreviewLoading) ? null : () => Get.back(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: (_isSending || _isPreviewLoading) ? null : _handleSend,
                          icon: _isSending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.send_rounded, size: 16),
                          label: Text(
                            _isSending ? 'Sending...' : 'Send Offer Letter',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
