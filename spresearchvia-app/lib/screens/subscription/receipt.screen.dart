import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../services/snackbar.service.dart';
import '../../services/api_client.service.dart';
import '../../services/api_exception.service.dart';
import '../../core/config/api.config.dart';
import '../../services/secure_storage.service.dart';
import 'widgets/receipt_info_row.dart';
import 'widgets/receipt_service_item.dart';
import 'widgets/receipt_price_row.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _invoice = {};
  bool _isPartial = false;
  Map<String, dynamic> _partialArgs = {};

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final args = Get.arguments ?? {};
      debugPrint('Receipt args: $args');

      bool invoiceLoaded = false;

      // ── Partial Payment: build invoice from passed args ─────────────────
      if (args is Map<String, dynamic> && args['type'] == 'partial') {
        _isPartial = true;
        _partialArgs = Map<String, dynamic>.from(args);
        invoiceLoaded = true;
      } else if (args is Map<String, dynamic> && args.containsKey('invoiceNo')) {
        _invoice = args;
        invoiceLoaded = true;
      } else if (args is Map<String, dynamic> &&
          args['type'] == 'registration' &&
          args.containsKey('purchase')) {
        final purchase = Map<String, dynamic>.from(args['purchase'] as Map);
        final double basic = _toDouble(purchase['basicAmount']);
        final double cgst = _toDouble(purchase['cgstAmount']);
        final double sgst = _toDouble(purchase['sgstAmount']);
        final double gst = cgst + sgst;
        String pMode = purchase['paymentMode'] ?? purchase['paymentMethod'] ?? '';
        if (pMode.isEmpty) {
          if (purchase['razorpayPaymentId'] != null) {
            pMode = 'Online';
          } else if (purchase['paymentProof'] != null) {
             pMode = 'Bank Transfer';
          } else {
             pMode = 'Online'; // Default for registration
          }
        } else {
          pMode = _formatPaymentMode(pMode);
        }

        _invoice = {
          'invoiceNumber': purchase['_id'] ?? '',
          'createdAt': purchase['createdAt'] ?? purchase['startDate'],
          'paymentMode': pMode,
          'status': purchase['status'] ?? '',
          'userId': purchase['userId'] ?? {},
          'segmentId': {
            'segmentName': purchase['packageName'] ?? '',
            'amount': basic,
            'gstAmount': gst,
            'validity': purchase['validity'] ?? '',
          },
          'amountPaid': (basic + gst),
          'paymentRefId':
              purchase['paymentRefId'] ?? purchase['paymentId'] ?? '',
        };
        invoiceLoaded = true;
      }

      if (!invoiceLoaded) {
        final invoiceId = args is Map<String, dynamic> ? args['invoiceId'] : null;
        final segmentId = args is Map<String, dynamic>
            ? args['segmentId'] ?? args['segment_id'] ?? args['id']
            : null;

        if (invoiceId != null || segmentId != null) {
          final queryParams = <String, dynamic>{};
          if (invoiceId != null) queryParams['invoiceId'] = invoiceId;
          if (segmentId != null) queryParams['segmentId'] = segmentId;

          final response = await _apiClient.get(
            '/segments/segment-invoice',
            queryParameters: queryParams,
          );

          if (response.statusCode == 200) {
            final data = response.data['data'];
            if (data != null) {
              _invoice = Map<String, dynamic>.from(data as Map);
              if (args is Map && args.containsKey('planName')) {
                _invoice['planName'] = args['planName'];
              }
            } else {
              _error = 'No invoice data available';
            }
          } else {
            _error = 'Failed to load invoice';
          }
        } else if (args is Map<String, dynamic> && args.isNotEmpty) {
          _invoice = Map<String, dynamic>.from(args);
        } else {
          _error = 'No invoice identifier provided';
        }
      }

      // Fetch user details (skip lookup for partial – user info fetched below)
      try {
        String? uid;
        
        // 1. Try to get ID from Secure Storage (Current Logged In User)
        final secureStorage = SecureStorageService();
        uid = await secureStorage.getUserId();

        // 2. If not found, try to extract from invoice data
        if (uid == null && _invoice.containsKey('userId')) {
           var userIdVal = _invoice['userId'];
           if (userIdVal is String) {
             uid = userIdVal;
           } else if (userIdVal is Map) {
             uid = userIdVal['_id']?.toString() ?? userIdVal['id']?.toString();
           }
        }

        if (uid != null) {
          final userRes = await _apiClient.get(ApiConfig.getUserDetails(uid));
          if (userRes.statusCode == 200 && userRes.data['data'] != null) {
            final data = userRes.data['data'];
            Map<String, dynamic> userDetails;
            if (data is Map && data.containsKey('userDetails')) {
              userDetails = Map<String, dynamic>.from(data['userDetails'] as Map);
            } else {
              userDetails = Map<String, dynamic>.from(data as Map);
            }
            if (_isPartial) {
              _partialArgs['userDetails'] = userDetails;
            } else {
              _invoice['userId'] = userDetails;
            }
          }
        }
      } catch (e) {
        debugPrint('Failed to fetch user details for receipt: $e');
      }

    } catch (e) {
      final apiError = ApiErrorHandler.handleError(e);
      _error = apiError.message;
      SnackbarService.showError(_error!);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatInvoiceNumber(String invoiceNo) {
    if (invoiceNo.isEmpty) return 'N/A';

    // If it's a MongoDB ID (24 hex characters), take first 12 characters
    if (invoiceNo.length >= 24 &&
        RegExp(r'^[a-f0-9]+$').hasMatch(invoiceNo.substring(0, 24))) {
      return invoiceNo.substring(0, 12).toUpperCase();
    }

    // If it's too long, truncate to reasonable length
    if (invoiceNo.length > 20) {
      return invoiceNo.substring(0, 20).toUpperCase();
    }

    return invoiceNo.toUpperCase();
  }

  String _formatPaymentMode(String rawMode) {
    final m = rawMode.trim().toUpperCase();
    if (m.isEmpty || m == 'BANK_TRANSFER' || m == 'OFFLINE' || m == 'MANUAL'
        || m == 'BANK' || m.contains('TRANSFER')) {
      return 'Bank Transfer';
    }
    if (m == 'UPI' || m == 'NETBANKING' || m == 'CARD' || m == 'EMI'
        || m == 'ONLINE' || m == 'RAZORPAY') {
      return 'Online';
    }
    // Title-case fallback
    return rawMode
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    String invoiceNo = _formatInvoiceNumber(
      _invoice['invoiceNumber']?.toString() ?? '',
    );
    String date = _formatDate(
      _invoice['createdAt'] ??
          _invoice['userActiveSegmentsId']?['purchaseDate'],
    );
    String paymentMode = _formatPaymentMode(_invoice['paymentMode']?.toString() ?? '');
    String status = _invoice['status']?.toString() ?? '';
    final user = _invoice['userId'];

    String clientName = '';
    String fatherName = '';
    String address = '';
    String mobile = '';
    String pan = '';
    String email = '';
    String aadhaar = '';
    String gstin = '';
    String firmName = '';

    if (user is Map) {
      clientName =
          (user['fullName']?.toString() ??
          user['userObject']?['APP_NAME']?.toString() ??
          '');
      fatherName = user['userObject']?['fatherName']?.toString() ?? '';
      address = user['userObject']?['address']?.toString() ?? '';
      mobile = user['phone']?.toString() ?? '';
      pan = user['userObject']?['pan']?.toString() ?? '';
      email = user['userObject']?['APP_EMAIL']?.toString() ?? 
              user['email']?.toString() ?? 
              '';
      aadhaar = user['aadhaarNumber']?.toString() ?? '';
      gstin = user['gstin']?.toString() ?? '';
      firmName = user['firmName']?.toString() ?? '';
    } else if (user is String) {
      clientName = user;
    } else if (user != null) {
      clientName = user.toString();
    }

    final segment = _invoice['segmentId'] ?? {};
    final intentData = _invoice['intentData'] ?? {};
    final List<dynamic> installments = (intentData['installments'] is List)
        ? (intentData['installments'] as List<dynamic>)
            .where((e) => e['status'] != 'REJECTED')
            .toList()
        : [];
    final bool isPartial = intentData['isPartial'] ?? false;
    
    double gstAmount = _toDouble(segment['gstAmount']);
    if (gstAmount == 0) {
      gstAmount = _toDouble(_invoice['gstAmount']);
    }

    double amount = _toDouble(segment['amount']);
    if (amount == 0) {
      final double totalInvoiceAmount = _toDouble(_invoice['amount']);
      if (totalInvoiceAmount > 0) {
        amount = totalInvoiceAmount - gstAmount;
      }
    }

    final double originalTotal = _toDouble(intentData['totalAmount'] ?? (amount + gstAmount));
    final double discountAmount = _toDouble(intentData['discount']);
    final double totalPayable = originalTotal - discountAmount;
    final double amountPaid = installments.isEmpty
        ? (_invoice['status'] == 'REJECTED' ? 0.0 : _toDouble(intentData['amountPaid'] ?? _invoice['amountPaid']))
        : installments.fold(0.0, (sum, item) => sum + _toDouble(item['amountPaid'] ?? item['amount']));
    final double remaining = totalPayable - amountPaid;

    // Recalculate breakdown based on Original Total (Actual Plan Amount)
    final double actualSubtotal = originalTotal / 1.18;
    final double actualGst = originalTotal - actualSubtotal;
    final double actualCgst = actualGst / 2;
    final double actualSgst = actualGst / 2;
    
    final String subtotalStr = _fmt(actualSubtotal);
    final String cgstStr = _fmt(actualCgst);
    final String sgstStr = _fmt(actualSgst);
    final String totalGstStr = _fmt(actualGst);
    final String discountStr = _fmt(discountAmount);
    final String totalPayableStr = _fmt(totalPayable);
    final String amountPaidStr = _fmt(amountPaid);
    final String remainingStr = _fmt(remaining);
    final String originalTotalStr = _fmt(originalTotal);
    
    // Plan name display
    String planNameDisplay = _invoice['planName']?.toString() ?? segment['segmentName']?.toString() ?? 'Subscription';
    if (planNameDisplay.toLowerCase() == 'silver') {
      planNameDisplay = 'Silver Registration';
    } else if (planNameDisplay.toLowerCase() == 'gold') {
      planNameDisplay = 'Gold Registration';
    }
    
    if (isPartial && amountPaid < totalPayable) {
       planNameDisplay = '$planNameDisplay (Paid Partially)';
    }

    // Extract validity from multiple possible sources
    String validity = '';
    
    debugPrint('=== VALIDITY DEBUG ===');
    debugPrint('segment object: $segment');
    debugPrint('userActiveSegmentsId: ${_invoice['userActiveSegmentsId']}');
    debugPrint('planName: ${_invoice['planName']}');
    
    // 1. Try from segment object
    if (segment['validity'] != null && segment['validity'].toString().isNotEmpty) {
      validity = segment['validity'].toString();
      debugPrint('Validity from segment: $validity');
    }
    
    // 2. Try from userActiveSegmentsId
    if (validity.isEmpty && _invoice['userActiveSegmentsId'] != null) {
      final activeSegment = _invoice['userActiveSegmentsId'];
      debugPrint('activeSegment type: ${activeSegment.runtimeType}');
      debugPrint('activeSegment data: $activeSegment');
      
      if (activeSegment is Map) {
        // Calculate from purchaseDate and expiryDate
        var purchaseDate = activeSegment['purchaseDate'];
        final expiryDate = activeSegment['expiryDate'];
        
        // Fallback: use invoice createdAt if purchaseDate is missing
        if (purchaseDate == null && _invoice['createdAt'] != null) {
          purchaseDate = _invoice['createdAt'];
          debugPrint('Using invoice createdAt as purchaseDate: $purchaseDate');
        }
        
        debugPrint('purchaseDate: $purchaseDate, expiryDate: $expiryDate');
        
        if (purchaseDate != null && expiryDate != null) {
          try {
            final start = DateTime.parse(purchaseDate.toString());
            final end = DateTime.parse(expiryDate.toString());
            final days = end.difference(start).inDays;
            validity = days.toString();
            debugPrint('Calculated validity from dates: $validity days');
          } catch (e) {
            debugPrint('Error calculating validity from dates: $e');
          }
        }
      }
    }
    
    // 3. Try from root invoice object
    if (validity.isEmpty && _invoice['validity'] != null) {
      validity = _invoice['validity'].toString();
      debugPrint('Validity from root invoice: $validity');
    }
    
    // 4. Try from planName (might contain validity info like "30 Days Plan")
    if (validity.isEmpty && _invoice['planName'] != null) {
      final planName = _invoice['planName'].toString();
      final match = RegExp(r'(\d+)\s*(?:day|days)', caseSensitive: false).firstMatch(planName);
      if (match != null) {
        validity = match.group(1) ?? '';
        debugPrint('Extracted validity from planName: $validity');
      }
    }
    
    debugPrint('Final validity: $validity');
    debugPrint('=== END VALIDITY DEBUG ===');
    
    final String paymentRefId = _invoice['paymentRefId']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xffF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xff163174)),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Receipt',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xff163174),
          ),
        ),
        actions: const [],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isPartial
          ? _buildPartialInvoice()
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xff163174),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SP RESEARCHVIA',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'PRIVATE LIMITED',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '129 A, Kalani Bagh, AB Road',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                'Dewas, MP - 455001',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                'info@researchvia.in',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              Text(
                                'www.researchvia.in',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'GSTIN: 23ABMCS3444G1ZC',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Text(
                                'SEBI REGISTRATION: INH000015808',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Text(
                                'CIN: U73200MP2023PTC069041',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              Text(
                                'BSE Enlistment no. : 6120',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Text(
                                'SP',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xff163174),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'INVOICE',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff163174),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Invoice No:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xff6B7280),
                                ),
                              ),
                              Text(
                                invoiceNo,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff163174),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Date:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xff6B7280),
                                ),
                              ),
                              Text(
                                date,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff163174),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Mode:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xff6B7280),
                                ),
                              ),
                              Text(
                                paymentMode.isNotEmpty ? paymentMode : 'N/A',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xff163174),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Status:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xff6B7280),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: remaining <= 0
                                      ? const Color(0xff10B981)
                                      : const Color(0xffF59E0B),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  remaining <= 0 ? 'paid' : 'partially paid',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CLIENT INFORMATION',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff163174),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (firmName.isNotEmpty) ...[
                            ReceiptInfoRow(
                              label: 'Firm Name:',
                              value: firmName,
                              labelWidth: 90,
                            ),
                            const SizedBox(height: 8),
                          ],
                          ReceiptInfoRow(
                            label: 'Name:',
                            value: clientName,
                            labelWidth: 90,
                          ),
                          const SizedBox(height: 8),

                          ReceiptInfoRow(
                            label: 'Mobile:',
                            value: mobile,
                            labelWidth: 90,
                          ),
                          const SizedBox(height: 8),
                          ReceiptInfoRow(
                            label: 'Email:',
                            value: email,
                            labelWidth: 90,
                          ),
                          if (gstin.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            ReceiptInfoRow(
                              label: 'GSTIN:',
                              value: gstin,
                              labelWidth: 90,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xffF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xffE5E7EB), width: 0.5),
                      ),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(2),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xff163174),
                            ),
                            children: const [
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('DESCRIPTION',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('BREAKDOWN',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('AMOUNT',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          // Service Row
                          TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(planNameDisplay,
                                    style: const TextStyle(
                                        fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Subtotal (Base):',
                                    style: TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(subtotalStr,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          // Tax Rows
                          TableRow(
                            children: [
                              const SizedBox(),
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('CGST (9%):',
                                    style: TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(cgstStr,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          TableRow(
                            children: [
                              const SizedBox(),
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('SGST (9%):',
                                    style: TextStyle(fontSize: 11)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(sgstStr,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 11)),
                              ),
                            ],
                          ),
                          if (discountAmount > 0)
                            TableRow(
                              children: [
                                const SizedBox(),
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Discount:',
                                      style: TextStyle(fontSize: 11, color: Colors.red)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text('-$discountStr',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 11, color: Colors.red)),
                                ),
                              ],
                            ),
                          // Total Payable
                          TableRow(
                            decoration: BoxDecoration(
                              color: const Color(0xff163174).withValues(alpha: 0.05),
                            ),
                            children: [
                              const SizedBox(),
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Total Payable:',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(totalPayableStr,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          // Installments List (if any)
                          if (installments.isNotEmpty) ...[
                             TableRow(
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                              ),
                              children: const [
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  child: Text('PAYMENT HISTORY',
                                      style: TextStyle(
                                          fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
                                ),
                                SizedBox(),
                                SizedBox(),
                              ],
                            ),
                            ...installments.map((inst) {
                              final double instTotal = _toDouble(inst['amount']);
                              final double instSubtotal = instTotal / 1.18;
                              final double instGst = instTotal - instSubtotal;
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Text('Installment ${inst['index']}',
                                        style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Base:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                        const Text('GST:', style: TextStyle(fontSize: 9, color: Colors.grey)),
                                        const Text('Total:', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(_fmt(instSubtotal), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                        Text(_fmt(instGst), style: const TextStyle(fontSize: 9, color: Colors.grey)),
                                        Text(_fmt(instTotal), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ],
                          // Amount Paid
                          TableRow(
                            children: [
                              const SizedBox(),
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Amount Paid:',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Text(amountPaidStr,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green)),
                              ),
                            ],
                          ),
                          if (remaining > 0)
                            TableRow(
                              children: [
                                const SizedBox(),
                                const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Text('Balance Due:',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(remainingStr,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffF9FAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ADDITIONAL INFORMATION',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff163174),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ReceiptInfoRow(
                            label: 'Payment Ref ID:',
                            value: paymentRefId,
                          ),
                          const SizedBox(height: 8),
                          ReceiptInfoRow(
                            label: 'Generated By:',
                            value: 'ResearchVia Admin',
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Authorized Signatory:',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xff6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '[Digital Signature]',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Color(0xff9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xffF9FAFB),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: const Column(
                        children: [
                          Text(
                            'This is a computer-generated invoice. No physical signature required.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Color(0xff6B7280),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Disclaimer: SP ResearchVia Pvt. Ltd. is a SEBI-registered Research Analyst entity. All services provided are subject to SEBI guidelines and market risks.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Color(0xff9CA3AF),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Support: For billing queries, contact support@researchvia.in',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Color(0xff9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Partial Payment Invoice ────────────────────────────────────────────
  Widget _buildPartialInvoice() {
    final args = _partialArgs;
    String planName = args['planName']?.toString() ?? 'Subscription Plan';
    if (planName.toLowerCase() == 'silver') {
      planName = 'Silver Registration';
    } else if (planName.toLowerCase() == 'gold') {
      planName = 'Gold Registration';
    }
    final double totalAmount = _toDouble(args['totalAmount']);
    final double discount = _toDouble(args['discount'] ?? 0);
    final double effectiveTotalPayable = _toDouble(args['effective_total_payable'] ?? (totalAmount - discount));
    
    final startDate = args['startDate']?.toString() ?? '';
    final expiryDate = args['expiryDate']?.toString() ?? '';
    final validityDays = args['validityDays']?.toString() ?? '';
    final status = args['status']?.toString() ?? '';
    final List<dynamic> history = (args['partialPaymentsHistory'] is List)
        ? (args['partialPaymentsHistory'] as List<dynamic>)
            .where((e) => e['status'] != 'REJECTED')
            .toList()
        : [];
        
    final double amountPaid = history.isEmpty
        ? (status.toLowerCase() == 'rejected' ? 0.0 : _toDouble(args['amountPaid']))
        : history.fold(0.0, (sum, item) => sum + _toDouble(item['amountPaid'] ?? item['amount']));
        
    final double remaining = effectiveTotalPayable - amountPaid;
    final user = args['userDetails'];
    String clientName = '';
    String mobile = '';
    String email = '';
    String gstin = '';
    String firmName = '';
    if (user is Map) {
      clientName = user['fullName']?.toString() ??
          user['userObject']?['APP_NAME']?.toString() ?? '';
      mobile = user['phone']?.toString() ?? '';
      email = user['userObject']?['APP_EMAIL']?.toString() ??
          user['email']?.toString() ?? '';
      gstin = user['gstin']?.toString() ?? '';
      firmName = user['firmName']?.toString() ?? '';
    }

    Color statusColor = const Color(0xffF59E0B);
    String statusText = 'PARTIALLY PAID';
    
    if (remaining <= 0) {
      statusColor = const Color(0xff10B981);
      statusText = 'PAID';
    } else if (status.toLowerCase() == 'expired') {
      statusColor = Colors.red;
      statusText = 'EXPIRED';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xff163174),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SP RESEARCHVIA',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 18,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                      Text('PRIVATE LIMITED',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.9))),
                      const SizedBox(height: 8),
                      Text('129 A, Kalani Bagh, AB Road',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8))),
                      Text('Dewas, MP - 455001',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8))),
                      Text('info@researchvia.in',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8))),
                      Text('www.researchvia.in',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8))),
                      const SizedBox(height: 8),
                      Text('GSTIN: 23ABMCS3444G1ZC',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9))),
                      Text('SEBI REGISTRATION: INH000015808',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9))),
                      Text('CIN: U73200MP2023PTC069041',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9))),
                      Text('BSE Enlistment no. : 6120',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.9))),
                    ],
                  ),
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Center(
                      child: Text('SP',
                          style: TextStyle(
                              fontFamily: 'Poppins', fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Color(0xff163174))),
                    ),
                  ),
                ],
              ),
            ),

            // ── INVOICE label + type badge ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  const Text('INVOICE',
                      style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff163174))),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xffF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('PARTIAL PAYMENT',
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xffF59E0B))),
                  ),
                ],
              ),
            ),

            // ── Status + Dates ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Start Date:',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                              color: Color(0xff6B7280))),
                      Text(startDate,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xff163174))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Status:',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                              color: Color(0xff6B7280))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(statusText,
                            style: const TextStyle(
                                fontFamily: 'Poppins', fontSize: 12,
                                fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Client Info ────────────────────────────────────────────
            if (clientName.isNotEmpty || mobile.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xffF9FAFB),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CLIENT INFORMATION',
                        style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff163174))),
                    const SizedBox(height: 12),
                    if (firmName.isNotEmpty) ...[
                      ReceiptInfoRow(label: 'Firm Name:', value: firmName, labelWidth: 90),
                      const SizedBox(height: 8),
                    ],
                    ReceiptInfoRow(label: 'Name:', value: clientName, labelWidth: 90),
                    const SizedBox(height: 8),
                    ReceiptInfoRow(label: 'Mobile:', value: mobile, labelWidth: 90),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ReceiptInfoRow(label: 'Email:', value: email, labelWidth: 90),
                    ],
                    if (gstin.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ReceiptInfoRow(label: 'GSTIN:', value: gstin, labelWidth: 90),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 24),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                  color: const Color(0xffF9FAFB),
                  border: Border.all(color: const Color(0xffE5E7EB), width: 0.5),
                  borderRadius: BorderRadius.circular(8)),
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xff163174),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('DATE',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('BREAKDOWN',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('AMOUNT',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Initial Plan Info Row
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(planName,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Base Amount:',
                            style: TextStyle(fontSize: 11)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_fmt(totalAmount),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (discount > 0)
                    TableRow(
                      children: [
                        const SizedBox(),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Discount:',
                              style: TextStyle(fontSize: 11, color: Colors.red)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('-${_fmt(discount)}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
                        ),
                      ],
                    ),
                  TableRow(
                    decoration: BoxDecoration(
                      color: const Color(0xff163174).withValues(alpha: 0.05),
                    ),
                    children: [
                      const SizedBox(),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Total Payable:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_fmt(effectiveTotalPayable),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Divider like decoration
                  TableRow(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                    ),
                    children: [
                      const SizedBox(height: 1),
                      const SizedBox(height: 1),
                      const SizedBox(height: 1),
                    ],
                  ),
                  // Installments Header
                  TableRow(
                    decoration: BoxDecoration(
                      color: const Color(0xff163174).withValues(alpha: 0.05),
                    ),
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('INSTALLMENTS',
                            style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      SizedBox(),
                      SizedBox(),
                    ],
                  ),
                  if (history.isEmpty)
                    const TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('No history found',
                              style: TextStyle(fontSize: 10)),
                        ),
                        SizedBox(),
                        SizedBox(),
                      ],
                    )
                  else
                    ...history.asMap().entries.expand((entry) {
                      final idx = entry.key;
                      final inst = entry.value as Map;
                      final instAmount = _toDouble(inst['amountPaid']);
                      final tDate = inst['transactionDate']?.toString() ?? '';
                      String formattedDate = '-';
                      try {
                        if (tDate.isNotEmpty) {
                          formattedDate = DateFormat('dd MMM yyyy').format(
                              DateTime.parse(tDate).toLocal());
                        }
                      } catch (_) {
                        formattedDate = tDate;
                      }

                      return [
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text('${idx + 1}. $formattedDate',
                                  style: const TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Subtotal (Base):',
                                  style: TextStyle(fontSize: 10)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_fmt(instAmount / 1.18),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const SizedBox(),
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('GST:',
                                  style: TextStyle(fontSize: 10)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_fmt(instAmount - (instAmount / 1.18)),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 10)),
                            ),
                          ],
                        ),
                        TableRow(
                          children: [
                            const SizedBox(),
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('Total Paid:',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(_fmt(instAmount),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green)),
                            ),
                          ],
                        ),
                      ];
                    }).toList(),
                  // Final Totals
                  TableRow(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey[300]!)),
                    ),
                    children: [
                      const SizedBox(),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('Accumulated Paid:',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(_fmt(amountPaid),
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ),
                    ],
                  ),
                  if (remaining > 0)
                    TableRow(
                      children: [
                        const SizedBox(),
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text('Balance Due:',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(_fmt(remaining),
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange)),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Additional Info ────────────────────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xffF9FAFB),
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ADDITIONAL INFORMATION',
                      style: TextStyle(
                          fontFamily: 'Poppins', fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xff163174))),
                  const SizedBox(height: 12),
                  ReceiptInfoRow(label: 'Expiry Date:', value: expiryDate),
                  const SizedBox(height: 8),
                  ReceiptInfoRow(label: 'Generated By:', value: 'ResearchVia Admin'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Footer ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xffF9FAFB),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    'This is a computer-generated invoice. No physical signature required.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 11,
                        color: Color(0xff6B7280)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Disclaimer: SP ResearchVia Pvt. Ltd. is a SEBI-registered Research Analyst entity. All services provided are subject to SEBI guidelines and market risks.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 10,
                        color: Color(0xff9CA3AF)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Support: For billing queries, contact support@researchvia.in',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Poppins', fontSize: 10,
                        color: Color(0xff9CA3AF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final DateTime dateTime;
      if (date is DateTime) {
        dateTime = date.toLocal();
      } else {
        final str = date.toString();
        if (str.isEmpty) return '';
        dateTime = DateTime.parse(str).toLocal();
      }
      return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
    } catch (_) {
      return date.toString();
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '')) ?? 0.0;
    return 0.0;
  }

  String _fmt(double v) {
    if (v == 0) return '₹0';
    return '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+\.)'), (m) => '${m[1]},')}';
  }

  Widget _breakdownRow(String text, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}
