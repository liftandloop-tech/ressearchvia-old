class Validators {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  static final RegExp _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');

  static final RegExp _aadharRegex = RegExp(r'^\d{12}$');

  static final RegExp _pincodeRegex = RegExp(r'^\d{6}$');

  static final RegExp _otpRegex = RegExp(r'^\d{4,6}$');

  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z\s.']+$");
  static final RegExp _dobRegex = RegExp(
    r'^(0[1-9]|[12][0-9]|3[01])[-\/]' r'(0[1-9]|1[0-2])[-\/]' r'(19|20)\d\d$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (!_phoneRegex.hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  static String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'PAN number is required';
    }

    final pan = value.trim().toUpperCase();

    if (pan.length != 10) {
      return 'PAN must be exactly 10 characters';
    }

    if (!_panRegex.hasMatch(pan)) {
      return 'Invalid PAN format. Use: ABCDE1234F (5 letters, 4 digits, 1 letter)';
    }

    if (pan[3] != 'P' &&
        pan[3] != 'C' &&
        pan[3] != 'H' &&
        pan[3] != 'F' &&
        pan[3] != 'A' &&
        pan[3] != 'T' &&
        pan[3] != 'B' &&
        pan[3] != 'L' &&
        pan[3] != 'J' &&
        pan[3] != 'G') {
      return 'Invalid PAN: 4th character must be a valid entity type';
    }

    return null;
  }

  static String? validateAadhar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final cleaned = value.replaceAll(RegExp(r'\s'), '');

    if (!_aadharRegex.hasMatch(cleaned)) {
      return 'Please enter a valid 12-digit Aadhar number';
    }
    return null;
  }

  static String? validateDOB(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Date of Birth is required';
    }
    final v = value.trim();
    if (!_dobRegex.hasMatch(v)) {
      return 'Please enter DOB in DD-MM-YYYY';
    }
    return null;
  }

  static String? validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    if (!_pincodeRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 4-digit pincode';
    }
    return null;
  }

  static String? validateOTP(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (!_otpRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 4 digit OTP';
    }
    return null;
  }

  static String? validateName(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (!_nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters and spaces';
    }
    return null;
  }

  static String? validateRequired(String? value, {required String fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  static bool isValidEmail(String email) {
    return _emailRegex.hasMatch(email.trim());
  }

  static bool isValidPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return _phoneRegex.hasMatch(cleaned);
  }

  static bool isValidPAN(String pan) {
    return _panRegex.hasMatch(pan.trim().toUpperCase());
  }

  static bool isValidAadhar(String aadhar) {
    final cleaned = aadhar.replaceAll(RegExp(r'\s'), '');
    return _aadharRegex.hasMatch(cleaned);
  }

  static bool isValidPincode(String pincode) {
    return _pincodeRegex.hasMatch(pincode.trim());
  }

  static String cleanPhone(String phone) {
    return phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  static String cleanAadhar(String aadhar) {
    return aadhar.replaceAll(RegExp(r'\s'), '');
  }

  static String normalizeDob(String dob) {
    return dob.trim().replaceAll('/', '-');
  }

  static String formatPhone(String phone) {
    final cleaned = cleanPhone(phone);
    if (cleaned.length == 10) {
      return '${cleaned.substring(0, 5)} ${cleaned.substring(5)}';
    }
    return phone;
  }

  static String formatAadhar(String aadhar) {
    final cleaned = cleanAadhar(aadhar);
    if (cleaned.length == 12) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 8)} ${cleaned.substring(8)}';
    }
    return aadhar;
  }

  static String formatPAN(String pan) {
    return pan.toUpperCase();
  }
}
