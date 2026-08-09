import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controllers/hni_request.controller.dart';
import '../../../config/theme.config.dart';
import '../../widgets/button.widget.dart';

class HniRequestsScreen extends StatefulWidget {
  const HniRequestsScreen({super.key});

  @override
  State<HniRequestsScreen> createState() => _HniRequestsScreenState();
}

class _HniRequestsScreenState extends State<HniRequestsScreen> {
  final controller = Get.put(HniRequestController());

  @override
  void initState() {
    super.initState();
    controller.fetchHniRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'HNI Custom Plan Requests',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.workspace_premium_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No HNI requests yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.requests.length,
                  itemBuilder: (context, index) {
                    final request = controller.requests[index];
                    return _buildRequestCard(request);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'PENDING';
    final isPending = status == 'PENDING';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request['userId']?['fullName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        request['userId']?['email'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      Text(
                        request['userId']?['phone'] ?? '',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.orange.withOpacity(0.1)
                        : status == 'APPROVED'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isPending
                          ? Colors.orange
                          : status == 'APPROVED'
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildInfoColumn(
                    'Plan',
                    request['planId']?['planName'] ?? 'Unknown',
                  ),
                ),
                Expanded(
                  child: _buildInfoColumn(
                    'Segment',
                    request['segmentId']?['segmentName'] ?? 'Unknown',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoColumn('Requested On', _formatDate(request['createdAt'])),
            if (isPending) ...[
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Button(
                      title: 'Grant Plan',
                      buttonType: ButtonType.green,
                      fullWidth: true,
                      onTap: () => _showGrantDialog(request),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Button(
                      title: 'Reject',
                      buttonType: ButtonType.red,
                      fullWidth: true,
                      onTap: () => controller.rejectRequest(request['_id']),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showGrantDialog(Map<String, dynamic> request) {
    final priceController = TextEditingController();
    final validityController = TextEditingController();
    String? selectedRaId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant HNI Custom Plan'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User: ${request['userId']?['fullName'] ?? 'Unknown'}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Custom Price (₹)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: validityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Validity (Days)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Obx(() {
                if (controller.staffList.isEmpty) {
                  return const Text('Loading staff...');
                }
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Assign Research Analyst',
                    border: OutlineInputBorder(),
                  ),
                  items: controller.staffList.map((staff) {
                    return DropdownMenuItem<String>(
                      value: staff['_id'],
                      child: Text(staff['fullName'] ?? 'Unknown'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedRaId = value;
                  },
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (priceController.text.isEmpty ||
                  validityController.text.isEmpty ||
                  selectedRaId == null) {
                Get.snackbar(
                  'Error',
                  'Please fill all fields',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              controller.grantHniPlan(
                requestId: request['_id'],
                userId: request['userId']['_id'],
                segmentId: request['segmentId']['_id'],
                planId: request['planId']['_id'],
                customPrice: double.parse(priceController.text),
                customValidity: int.parse(validityController.text),
                assignedRaId: selectedRaId!,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.buttonGreen,
            ),
            child: const Text('Grant Plan'),
          ),
        ],
      ),
    );
  }
}
