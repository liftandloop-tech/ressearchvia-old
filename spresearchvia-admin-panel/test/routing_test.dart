import 'package:flutter_test/flutter_test.dart';
import 'package:spresearch_web/config/routes.config.dart';

void main() {
  group('Public Routes Verification', () {
    test('Identifies public routes correctly', () {
      expect(AppRoutes.isPublicRoute('/'), isTrue);
      expect(AppRoutes.isPublicRoute('/apply'), isTrue);
      expect(AppRoutes.isPublicRoute('/apply/continue'), isTrue);
      expect(AppRoutes.isPublicRoute('/apply/continue/6612345'), isTrue);
      expect(AppRoutes.isPublicRoute('/continue-application'), isTrue);
      expect(AppRoutes.isPublicRoute('/continue-application/6612345'), isTrue);
      expect(AppRoutes.isPublicRoute('/verify/staff/SP-101'), isTrue);
      expect(AppRoutes.isPublicRoute('/verify/SP-101'), isTrue);
      expect(AppRoutes.isPublicRoute('/forgot-password'), isTrue);
      expect(AppRoutes.isPublicRoute('/reset-password'), isTrue);
    });

    test('Identifies private routes correctly', () {
      expect(AppRoutes.isPublicRoute('/dashboard'), isFalse);
      expect(AppRoutes.isPublicRoute('/users'), isFalse);
      expect(AppRoutes.isPublicRoute('/staff'), isFalse);
      expect(AppRoutes.isPublicRoute('/applicants'), isFalse);
      expect(AppRoutes.isPublicRoute('/reports'), isFalse);
      expect(AppRoutes.isPublicRoute('/settings'), isFalse);
    });
  });
}
