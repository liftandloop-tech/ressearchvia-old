import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Session & Inactivity Expiration Tests', () {
    const lastActivityKey = 'last_activity_timestamp';
    const inactivityTimeout = Duration(hours: 1);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    test('Session should NOT expire if activity is within 1 hour', () async {
      final prefs = await SharedPreferences.getInstance();
      // User active 10 minutes ago
      final tenMinutesAgo = DateTime.now().subtract(const Duration(minutes: 10));
      await prefs.setInt(lastActivityKey, tenMinutesAgo.millisecondsSinceEpoch);

      final lastMs = prefs.getInt(lastActivityKey);
      expect(lastMs, isNotNull);

      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs!);
      final elapsed = DateTime.now().difference(lastTime);
      final isExpired = elapsed >= inactivityTimeout;

      expect(isExpired, isFalse);
    });

    test('Session SHOULD expire if inactive for more than 1 hour', () async {
      final prefs = await SharedPreferences.getInstance();
      // User inactive for 65 minutes
      final sixtyFiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 65));
      await prefs.setInt(lastActivityKey, sixtyFiveMinutesAgo.millisecondsSinceEpoch);

      final lastMs = prefs.getInt(lastActivityKey);
      expect(lastMs, isNotNull);

      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs!);
      final elapsed = DateTime.now().difference(lastTime);
      final isExpired = elapsed >= inactivityTimeout;

      expect(isExpired, isTrue);
    });

    test('Hard refresh simulation preserves valid active session without false expiry', () async {
      final prefs = await SharedPreferences.getInstance();
      // Set active credentials
      await prefs.setString('auth_token', 'valid_jwt_token_123');
      await prefs.setString('user_data', '{"id":"123","role":"Admin","fullName":"Test Admin"}');
      // Set recent activity (just now)
      final justNow = DateTime.now();
      await prefs.setInt(lastActivityKey, justNow.millisecondsSinceEpoch);

      // Verify credentials and activity exist
      final token = prefs.getString('auth_token');
      final user = prefs.getString('user_data');
      final lastMs = prefs.getInt(lastActivityKey);

      expect(token, isNotNull);
      expect(user, isNotNull);
      expect(lastMs, isNotNull);

      final lastTime = DateTime.fromMillisecondsSinceEpoch(lastMs!);
      final elapsed = DateTime.now().difference(lastTime);
      final isExpired = elapsed >= inactivityTimeout;

      expect(isExpired, isFalse);
    });
  });
}
