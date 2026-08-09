abstract class ValidationService {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _indianPhoneRegex = RegExp(r'^[6-9]\d{9}$');

  static bool validatePhoneNumber(String input) {
    if (input.isEmpty) return false;

    String cleanedInput = input.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    if (cleanedInput.startsWith('91') && cleanedInput.length == 12) {
      cleanedInput = cleanedInput.substring(2);
    }

    return _indianPhoneRegex.hasMatch(cleanedInput);
  }

  static bool validateEmail(String input) {
    if (input.isEmpty) return false;

    String trimmedInput = input.trim();

    return _emailRegex.hasMatch(trimmedInput);
  }

  static bool validateDefault(String input) {
    return input.trim().isNotEmpty;
  }

  static bool validatePassword(String input) {
    return input.length >= 6;
  }

  static bool validateStrongPassword(String input) {
    if (input.length < 8) return false;

    final hasUppercase = input.contains(RegExp(r'[A-Z]'));
    final hasLowercase = input.contains(RegExp(r'[a-z]'));
    final hasDigit = input.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = input.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return hasUppercase && hasLowercase && hasDigit && hasSpecialChar;
  }

  static bool validateName(String input) {
    if (input.trim().isEmpty) return false;

    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegex.hasMatch(input.trim());
  }

  static bool validatePAN(String input) {
    if (input.isEmpty) return false;

    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    return panRegex.hasMatch(input.toUpperCase());
  }

  static bool validateAadhaar(String input) {
    if (input.isEmpty) return false;

    String cleanedInput = input.replaceAll(RegExp(r'\s'), '');

    final aadhaarRegex = RegExp(r'^\d{12}$');
    return aadhaarRegex.hasMatch(cleanedInput);
  }

  static bool validateGST(String input) {
    if (input.isEmpty) return false;

    final gstRegex = RegExp(
      r'^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$',
    );
    return gstRegex.hasMatch(input.toUpperCase());
  }

  static bool validatePinCode(String input) {
    if (input.isEmpty) return false;

    final pinRegex = RegExp(r'^\d{6}$');
    return pinRegex.hasMatch(input);
  }

  static bool validateURL(String input) {
    if (input.isEmpty) return false;

    final urlRegex = RegExp(
      r'^(https?:\/\/)?(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&]*)$',
    );
    return urlRegex.hasMatch(input);
  }

  static bool validateAmount(String input) {
    if (input.isEmpty) return false;

    final amountRegex = RegExp(r'^\d+(\.\d{1,2})?$');
    return amountRegex.hasMatch(input);
  }

  static bool validateIFSC(String input) {
    if (input.isEmpty) return false;

    final ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
    return ifscRegex.hasMatch(input.toUpperCase());
  }

  static bool validateConfirmPassword(String password, String confirmPassword) {
    return password == confirmPassword && password.isNotEmpty;
  }

  static bool validateMinLength(String input, int minLength) {
    return input.length >= minLength;
  }

  static bool validateMaxLength(String input, int maxLength) {
    return input.length <= maxLength;
  }

  static bool validateAlphanumeric(String input) {
    if (input.isEmpty) return false;

    final alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');
    return alphanumericRegex.hasMatch(input);
  }

  static String? getPhoneNumberError(String input) {
    if (input.isEmpty) return 'Phone number is required';
    if (!validatePhoneNumber(input)) {
      return 'Please enter a valid 10-digit Indian phone number';
    }
    return null;
  }

  static String? getEmailError(String input) {
    if (input.isEmpty) return 'Email is required';
    if (!validateEmail(input)) return 'Please enter a valid email address';
    return null;
  }

  static String? getDefaultError(String input, String fieldName) {
    if (!validateDefault(input)) return '$fieldName is required';
    return null;
  }

  static String? getPasswordError(String input) {
    if (input.isEmpty) return 'Password is required';
    if (!validatePassword(input)) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? getNameError(String input) {
    if (input.isEmpty) return 'Name is required';
    if (!validateName(input)) {
      return 'Please enter a valid name (letters only)';
    }
    return null;
  }

  static String? getPANError(String input) {
    if (input.isEmpty) return 'Please enter PAN card number';
    if (!validatePAN(input)) {
      return 'Please enter a valid PAN number (e.g., ABCDE1234F)';
    }
    return null;
  }

  static String? getAadhaarError(String input) {
    if (input.isEmpty) return 'Please enter Aadhar number';
    if (!validateAadhaar(input)) {
      return 'Please enter a valid 12-digit Aadhar number';
    }
    return null;
  }
}
