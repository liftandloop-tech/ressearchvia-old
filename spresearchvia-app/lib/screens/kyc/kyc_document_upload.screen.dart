import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/button.dart';
import '../../controllers/kyc.controller.dart';
import '../../services/snackbar.service.dart';

import '../auth/set_mpin.screen.dart';
import '../../services/secure_storage.service.dart';
import '../../controllers/user.controller.dart';
import '../../controllers/auth.controller.dart';
import '../../core/routes/app_routes.dart';

class KycDocumentUploadScreen extends StatefulWidget {
  final String? panNumber;
  final String? aadharNumber;

  const KycDocumentUploadScreen({
    super.key,
    this.panNumber,
    this.aadharNumber,
  });

  @override
  State<KycDocumentUploadScreen> createState() =>
      _KycDocumentUploadScreenState();
}

class _KycDocumentUploadScreenState extends State<KycDocumentUploadScreen> {
  final KycController _kycController = Get.put(KycController());
  final ImagePicker _picker = ImagePicker();

  File? _aadhaarFront;
  File? _aadhaarBack;
  File? _panCard;

  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source, Function(File) onPicked) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        onPicked(File(pickedFile.path));
      }
    } catch (e) {
      SnackbarService.showError('Failed to pick image: $e');
    }
  }

  void _showImageSourceSheet(Function(File) onPicked) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppTheme.primaryBlue),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, onPicked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppTheme.primaryBlue),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery, onPicked);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_aadhaarFront == null || _aadhaarBack == null || _panCard == null) {
      SnackbarService.showWarning('Please upload all required documents.');
      return;
    }

    setState(() => _isUploading = true);

    // Resolve Data
    String? resolvedPan = widget.panNumber;
    String? resolvedAadhar = widget.aadharNumber;
    
    if (resolvedPan == null || resolvedAadhar == null) {
       final userC = Get.isRegistered<UserController>() ? Get.find<UserController>() : Get.put(UserController());
       final user = userC.currentUser.value;
       
       // Use properties from User model
       resolvedPan ??= user?.panNumber;
       resolvedAadhar ??= user?.aadharNumber;
       
       // If still null, try secure storage fallbacks (rare case)
       if (resolvedPan == null || resolvedAadhar == null){
          final storage = SecureStorageService();
          final userData = await storage.getUserData();
          resolvedPan ??= userData?['userObject']?['APP_PAN_NO'] ?? userData?['panNumber'];
          resolvedAadhar ??= userData?['aadhaarNumber'];
       }
    }

    if (resolvedPan == null || resolvedPan.isEmpty) {
        SnackbarService.showError('PAN Number missing. Please restart KYC.');
        setState(() => _isUploading = false);
        return;
    }



    try {
      // 1. Upload PAN Card
      final panSuccess = await _kycController.uploadPanCard(
        panFile: _panCard!,
        panNumber: resolvedPan,
      );

      if (!panSuccess) {
        setState(() => _isUploading = false);
        return;
      }

      // 2. Upload Aadhaar Card
      final aadharSuccess = await _kycController.uploadAadharCard(
        frontFile: _aadhaarFront!,
        backFile: _aadhaarBack!,
        aadharNumber: resolvedAadhar ?? "", // Send empty string if null
      );

      if (!aadharSuccess) {
        setState(() => _isUploading = false);
        return;
      }

      // Fetch fresh status from backend and follow its dynamic routing instructions
      await Get.find<AuthController>().checkAuthStatus();
    } catch (e) {
      SnackbarService.showError('Something went wrong during upload.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildImageUploadBox({
    required String title,
    required File? image,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
            onTap: onTap,
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                border: Border.all(
                  color: AppTheme.borderGrey,
                  width: 1,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            image,
                            fit: BoxFit.cover,
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          )
                        ],
                      ),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppTheme.textGreyLight,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Tap to upload',
                          style: TextStyle(
                            color: AppTheme.textGreyLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryBlue),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Document Upload',
          style: TextStyle(
            color: AppTheme.primaryBlue,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload photos of your documents to complete the KYC process.',
                  style: TextStyle(color: AppTheme.textGrey, fontSize: 14),
                ),
                const SizedBox(height: 30),
                
                // PAN Card Section
                _buildImageUploadBox(
                  title: 'PAN Card (Front)',
                  image: _panCard,
                  onTap: () => _showImageSourceSheet((file) {
                    setState(() => _panCard = file);
                  }),
                ),
                const SizedBox(height: 20),

                // Aadhaar Front Section
                Row(
                  children: [
                    Expanded(
                      child: _buildImageUploadBox(
                        title: 'Aadhaar (Front)',
                        image: _aadhaarFront,
                        onTap: () => _showImageSourceSheet((file) {
                          setState(() => _aadhaarFront = file);
                        }),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _buildImageUploadBox(
                        title: 'Aadhaar (Back)',
                        image: _aadhaarBack,
                        onTap: () => _showImageSourceSheet((file) {
                          setState(() => _aadhaarBack = file);
                        }),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 40),
                Button(
                  title: 'Submit Documents',
                  buttonType: ButtonType.blue,
                  onTap: _isUploading ? null : _submit,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
