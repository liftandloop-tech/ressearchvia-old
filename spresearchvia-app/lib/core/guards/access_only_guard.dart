import 'dart:io';
import '../models/user.dart';

class Session {
  final User? user;
  final String? intent;
  final String? platform;
  final bool isAuthenticated;

  Session({
    this.user,
    this.intent,
    this.platform,
    this.isAuthenticated = false,
  });

  bool get isAndroid => platform == 'android';
  bool get isIOS => platform == 'ios' || (Platform.isIOS); // Fallback to safe check

  // Guard Logic
  bool get canShowPayment {
    // Only Android, and only if "COLLECT_PAYMENT" was the explicit intent OR we are in a permissive state
    // But strict rule: NO iOS.
    if (isIOS) return false;
    
    // Default to true for Android unless restricted? 
    // Backend says: if not authorized, we get REGISTRATION_PAYMENT nextStep.
    return true; 
  }

  bool get isLimitedAccess {
    return intent == 'ACCESS_ONLY' || 
           (isIOS && user?.registrationStatus != 'ACTIVE' && user?.registrationStatus != 'COMPLETE'); 
  }
}

class AccessOnlyGuard {
  static bool canShowPayment() {
    if (Platform.isIOS) return false;
    return true;
  }
  
  static bool isLimitedAccess(User? user) {
     if (Platform.isIOS) {
       // If user is not active, they are limited access
       bool active = user?.registrationStatus == 'ACTIVE' || user?.registrationStatus == 'COMPLETE';
       return !active;
     }
     return false;
  }
}
