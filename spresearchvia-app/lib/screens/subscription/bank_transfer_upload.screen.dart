import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/api.config.dart';
import '../../widgets/button.dart';
import '../../controllers/plan_purchase.controller.dart';
import '../../controllers/segment_plan.controller.dart';
import '../../controllers/auth.controller.dart';
import '../../controllers/user.controller.dart';
import '../../services/snackbar.service.dart';
import '../../services/secure_storage.service.dart';

class BankTransferUploadScreen extends StatefulWidget {
  const BankTransferUploadScreen({super.key});

  @override
  State<BankTransferUploadScreen> createState() =>
      _BankTransferUploadScreenState();
}

class _BankTransferUploadScreenState extends State<BankTransferUploadScreen> {
  final Map<String, dynamic> args = Get.arguments ?? {};
  List<File> _selectedImages = [];
  bool _isUploading = false;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _utrController = TextEditingController();
  DateTime? _selectedDate;

  final ImagePicker _picker = ImagePicker();
  late final PlanPurchaseController _purchaseController;

  // Dynamic Bank Details
  String _bankName = "HDFC Bank";
  String _accName = "SP ResearchVia Pvt Ltd";
  String _accNo = "50200012345678";
  String _ifsc = "HDFC0001234";
  bool _isLoadingDetails = true;
  String _upiId = "";
  String _qrCode = "";
  late final SegmentPlanController _segmentController;

  String? _amountError;

  @override
  void initState() {
    super.initState();
    _purchaseController = Get.find<PlanPurchaseController>();
    if (!Get.isRegistered<SegmentPlanController>()) {
      Get.put(SegmentPlanController());
    }
    _segmentController = Get.find<SegmentPlanController>();
    _fetchBankDetails();
    _fetchPartialInfo();

    _amountController.addListener(_validateAmount);
  }

  Future<void> _fetchBankDetails() async {
    try {
      final details = await _purchaseController.fetchBankDetails();
      if (details != null && mounted) {
        setState(() {
          _bankName = details['bankName'] ?? _bankName;
          _accName = details['accountName'] ?? _accName;
          _accNo = details['accountNumber'] ?? _accNo;
          _ifsc = details['ifscCode'] ?? _ifsc;
          _upiId = details['upiId'] ?? _upiId;
          _qrCode = details['qrCode'] ?? _qrCode;
          _isLoadingDetails = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching bank details: $e');
    } finally {
      if (mounted) setState(() => _isLoadingDetails = false);
    }
  }

  Future<void> _fetchPartialInfo() async {
    await _segmentController.fetchActivePartialInfo();
  }

  void _validateAmount() {
    final inputStr = _amountController.text.trim();
    if (inputStr.isEmpty) {
      if (mounted) setState(() => _amountError = null);
      return;
    }

    final inputAmount = double.tryParse(inputStr);
    if (inputAmount == null) {
      if (mounted) setState(() => _amountError = 'Invalid amount format');
      return;
    }

    final partialInfo = _segmentController.activePartialInfo.value;
    if (partialInfo == null) return;

    final totalAmount = (partialInfo['actual_total_amount'] as num?)?.toDouble() ?? 0.0;
    final totalPaid = (partialInfo['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
    final pendingAmount = (partialInfo['pending_amount'] as num?)?.toDouble() ?? 0.0;

    final totalCommitted = totalPaid + pendingAmount;
    final remaining = totalAmount - totalCommitted;

    // Reject amount will not be calculated in amount paid (handled by backend API already)
    // total_amount_paid only includes APPROVED
    // pending_amount only includes PENDING

    if (inputAmount > (remaining + 0.01)) { // 0.01 for rounding floating point
       if (mounted) {
         setState(() {
           _amountError = 'Exceeds remaining balance: ₹${remaining.toStringAsFixed(2)}';
         });
       }
    } else {
       if (mounted) setState(() => _amountError = null);
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_validateAmount);
    _amountController.dispose();
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      if ((_selectedImages.length + images.length) > 5) {
        SnackbarService.showError('Maximum 5 images allowed');
        return;
      }
      setState(() {
        _selectedImages.addAll(images.map((img) => File(img.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitProof() async {
    if (_selectedImages.isEmpty) {
      SnackbarService.showError('Please select at least one screenshot');
      return;
    }
    if (_amountController.text.isEmpty) {
      SnackbarService.showError('Please enter amount paid');
      return;
    }
    if (_amountError != null) {
      SnackbarService.showError(_amountError!);
      return;
    }
    if (_utrController.text.isEmpty) {
      SnackbarService.showError('Please enter UTR / Transaction ID');
      return;
    }
    if (_selectedDate == null) {
      SnackbarService.showError('Please select transaction date');
      return;
    }

    final paymentId = args['paymentId'];
    if (paymentId == null) {
      SnackbarService.showError('Invalid Payment ID');
      return;
    }

    setState(() => _isUploading = true);

    try {
      final success = await _purchaseController.uploadPaymentProof(
        paymentId: paymentId,
        files: _selectedImages,
        amountPaid: _amountController.text,
        utrNumber: _utrController.text,
        transactionDate: _selectedDate!.toIso8601String(),
      );

      if (success) {
        // Clear skip flag in storage & memory
        final storage = SecureStorageService();
        await storage.setRegistrationSkipped(false);
        if (Get.isRegistered<UserController>()) {
          Get.find<UserController>().isRegistrationSkipped.value = false;
        }

        SnackbarService.showSuccess(
          'Proof uploaded successfully! Waiting for verification.',
        );
        
        // Refresh Auth User from backend and navigate to Dashboard
        await Get.find<AuthController>().checkAuthStatus();
      }
    } catch (e) {
      SnackbarService.showError('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  /// Returns the full URL for the QR code image
  String get _qrImageUrl {
    if (_qrCode.startsWith('http')) return _qrCode;
    return '${ApiConfig.baseUrl.replaceAll(RegExp(r"/api$"), "")}/$_qrCode';
  }

  /// Downloads the QR code image to the device gallery/downloads
  Future<void> _downloadQrCode() async {
    try {
      SnackbarService.showSuccess('Downloading QR code...');
      final response = await http.get(Uri.parse(_qrImageUrl));
      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final filePath = '${dir.path}/qr_code.png';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        if (mounted) {
          SnackbarService.showSuccess('QR code saved!');
        }
      } else {
        if (mounted) SnackbarService.showError('Failed to download QR code');
      }
    } catch (e) {
      if (mounted) SnackbarService.showError('Download failed: $e');
    }
  }

  /// Shows the QR code in a full-screen popup with a download button
  void _showQrPopup() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        bool isDownloading = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(24),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Main card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 48, 20, 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Scan QR to Pay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use any UPI app to scan and pay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _qrImageUrl,
                            height: 260,
                            width: 260,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const SizedBox(
                                height: 260,
                                width: 260,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            },
                            errorBuilder: (c, e, s) => const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'QR Unavailable',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_upiId.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundLightBlue,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.primaryBlue.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 16,
                                  color: AppTheme.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _upiId,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Close button (top right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 20,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),

                  // Circular download button (bottom right)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: isDownloading
                          ? null
                          : () async {
                              setDialogState(() => isDownloading = true);
                              await _downloadQrCode();
                              if (ctx.mounted) {
                                setDialogState(() => isDownloading = false);
                              }
                            },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue,
                              AppTheme.primaryBlue.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryBlue.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isDownloading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isInstallment = args['isPartial'] == true;
    final planName = args['planName'] ?? 'Plan';

    return Scaffold(
      appBar: AppBar(
        title: Text(isInstallment ? 'Pay Installment' : 'Bank Transfer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isInstallment) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continuing Payment for $planName',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'This payment will extend your plan validity',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
            const Text(
              'Transfer Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLightBlue,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    args['isPartial'] == true
                        ? 'Plan Total (Target)'
                        : 'Amount to Pay',
                    args['totalToPay'] != null
                        ? '₹${args['totalToPay'].toStringAsFixed(2)}'
                        : (args['amount'] != null
                              ? '₹${args['amount']}'
                              : 'Contact Support'),
                    isBold: true,
                  ),
                  const Divider(),
                  _isLoadingDetails
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Bank Name', _bankName),
                            _buildDetailRow('Account Name', _accName),
                            _buildDetailRow('Account No', _accNo),
                            _buildDetailRow('IFSC Code', _ifsc),

                            // UPI ID — only shown if admin filled it
                            if (_upiId.isNotEmpty)
                              _buildDetailRow('UPI ID', _upiId, isBold: true),

                            // QR Code — only shown if admin uploaded it
                            if (_qrCode.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      'QR Code',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _showQrPopup,
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: AppTheme.primaryBlue
                                                    .withValues(alpha: 0.4),
                                                width: 2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.08),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                _qrImageUrl,
                                                height: 160,
                                                width: 160,
                                                fit: BoxFit.contain,
                                                loadingBuilder:
                                                    (context, child, progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      }
                                                      return const SizedBox(
                                                        height: 160,
                                                        width: 160,
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(),
                                                        ),
                                                      );
                                                    },
                                                errorBuilder: (c, e, s) =>
                                                    const SizedBox(
                                                      height: 160,
                                                      width: 160,
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.broken_image,
                                                            color: Colors.grey,
                                                          ),
                                                          SizedBox(height: 4),
                                                          Text(
                                                            'QR Unavailable',
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                              ),
                                            ),
                                          ),
                                          // Tap to expand hint overlay
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.primaryBlue
                                                    .withValues(alpha: 0.85),
                                                borderRadius:
                                                    const BorderRadius.only(
                                                      bottomLeft:
                                                          Radius.circular(10),
                                                      bottomRight:
                                                          Radius.circular(10),
                                                    ),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.zoom_in,
                                                    color: Colors.white,
                                                    size: 14,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'Tap to enlarge',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Payment Confirmation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Remaining Balance Hint for Partial Payments
            if (args['isPartial'] == true) ...[
              Obx(() {
                final partialInfo = _segmentController.activePartialInfo.value;
                if (partialInfo == null) return const SizedBox.shrink();

                final totalAmount = (partialInfo['actual_total_amount'] as num?)?.toDouble() ?? 0.0;
                final totalPaid = (partialInfo['total_amount_paid'] as num?)?.toDouble() ?? 0.0;
                final pendingAmount = (partialInfo['pending_amount'] as num?)?.toDouble() ?? 0.0;
                final remaining = totalAmount - totalPaid - pendingAmount;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    'Remaining Balance to Pay: ₹${remaining.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: remaining <= 0 ? Colors.green : AppTheme.primaryBlue,
                    ),
                  ),
                );
              }),
            ],

            // Amount Paid Input
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Paid *',
                hintText: args['isPartial'] == true
                    ? 'Enter installment amount'
                    : 'Enter amount transferred',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.currency_rupee),
                errorText: _amountError,
              ),
            ),
            const SizedBox(height: 16),

            // UTR Number Input
            TextField(
              controller: _utrController,
              decoration: const InputDecoration(
                labelText: 'UTR / Transaction ID *',
                hintText: 'Enter 12-digit UTR or Ref No.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),

            // Transaction Date Picker
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Transaction Date *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _selectedDate != null
                      ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}"
                      : 'Select Date',
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Upload Payment Screenshots (Max 5) *',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap to select images *',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (_selectedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _selectedImages[index],
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: -4,
                          child: IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 32),
            Button(
              title: _isUploading ? 'Uploading...' : 'Submit Proof',
              buttonType: ButtonType.green,
              onTap: (_isUploading || _amountError != null) ? null : _submitProof,
              showLoading: _isUploading,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 14,
              color: isBold ? AppTheme.primaryBlue : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
