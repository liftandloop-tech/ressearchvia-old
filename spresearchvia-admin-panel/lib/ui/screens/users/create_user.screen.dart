import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/controllers/users/user_management.controller.dart';
import 'package:spresearch_web/services/subscription.service.dart';
import 'package:spresearch_web/models/subscription_plan.model.dart';
import 'package:spresearch_web/services/user.service.dart';
import 'package:spresearch_web/services/staff.service.dart';
import 'package:spresearch_web/models/staff.model.dart';
import 'package:spresearch_web/models/segment.model.dart';
import 'package:spresearch_web/controllers/users/users_navigation.controller.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = Get.find<UserService>();
  final _subscriptionService = Get.find<SubscriptionService>();
  final _staffService = Get.put(
    StaffService(),
  ); // Put if not already in bindings
  final _userManagementController = Get.find<UserManagementController>();
  final _navigationController = Get.find<UsersNavigationController>();

  String _fullName = '';
  String _phone = '';
  String _mpin = ''; // Added MPIN
  String _email = '';
  String _userType = 'user'; // user, admin, staff
  String _registrationType = 'YEARLY'; // YEARLY, LIFETIME

  final List<String> _selectedPlanIds = [];
  final Map<String, Map<String, dynamic>> _planConfigs =
      {}; // Track segment, isPartial, paidAmount, raId, etc
  List<SubscriptionPlanModel> _availablePlans = [];
  List<SegmentModel> _availableSegments = [];
  List<StaffModel> _availableRAs = [];
  bool _isLoadingPlans = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    final result = await _subscriptionService.getSubscriptionPlans(
      pageSize: 100,
      status: 'active',
    );
    final segments = await _subscriptionService.getSegments();

    // Fetch RAs (Staff)
    List<StaffModel> ras = [];
    try {
      ras = await _staffService.getStaffList();
    } catch (e) {
      debugPrint('Error fetching RAs: $e');
    }

    setState(() {
      _availablePlans = result.plans;
      _availableSegments = segments;
      _availableRAs = ras;
      _isLoadingPlans = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gray50, // Page background
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(32),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New User',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryBlue,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => _navigationController.goBack(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Basic Info
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'Full Name *',
                          (val) => _fullName = val,
                          required: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Phone (10 digits) *',
                          (val) => _phone = val,
                          required: true,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          'MPIN (4 digits) *',
                          (val) => _mpin = val,
                          required: true,
                          isNumber: true,
                          maxLength: 4,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          'Email *',
                          (val) => _email = val,
                          required: true,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Create User',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildTextField(
    String label,
    Function(String) onChanged, {
    bool required = false,
    bool isNumber = false,
    int? maxLength,
  }) {
    return TextFormField(
      decoration: _inputDecoration(label),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return '${label.replaceAll(' *', '')} is required';
        }
        if (isNumber) {
          if (maxLength != null && value!.length != maxLength) {
            return 'Enter valid $maxLength digit number';
          }
          if (maxLength == null && value!.length != 10) {
            // Default phone check
            return 'Enter valid 10 digit number';
          }
        }
        return null;
      },
      onChanged: onChanged,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final data = {
      'fullName': _fullName,
      'phone': _phone,
      'email': _email,
      'userType': _userType,
      'paymentMode': 'OFFLINE',
      'mpin': _mpin,
    };

    final success = await _userService.adminCreateUser(data);

    setState(() => _isSubmitting = false);

    if (success) {
      _navigationController.goBack(); // Close popup correctly
      Get.snackbar(
        'Success',
        'User created successfully.',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      _userManagementController.fetchUsers(); // Refresh list
    } else {
      Get.snackbar(
        'Error',
        'Failed to create user.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
