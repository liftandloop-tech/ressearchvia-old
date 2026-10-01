import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spresearchvia/controllers/automated_trading.controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const MethodChannel channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });
  });

  group('AutomatedTradingController State Tests', () {
    late AutomatedTradingController controller;

    setUp(() {
      controller = AutomatedTradingController();
    });

    test('Initial states are set with correct defaults', () {
      expect(controller.hasSignedAgreement.value, false);
      expect(controller.consentsStatus.value, 'NOT_GRANTED');
      expect(controller.selectedStrategy.value, 'FIXED_1X');
      expect(controller.isDailyConsentActive, false);
      expect(controller.isBrokerConfigured, false);
      expect(controller.isBrokerSessionActive, false);
      expect(controller.hasActiveProxy, false);
      expect(controller.isLotConfigured, false);
      expect(controller.isStrategyConfigured, false);
    });

    test('isBrokerConfigured returns true when linkedBrokers has entries', () {
      controller.linkedBrokers.value = [
        {'brokerCode': 'ANGEL_ONE', 'brokerClientId': 'A123', 'isSessionActive': false}
      ];
      expect(controller.isBrokerConfigured, true);
      expect(controller.isBrokerSessionActive, false);
    });

    test('isBrokerSessionActive correctly checks any active broker session among multiple brokers', () {
      controller.linkedBrokers.value = [
        {'brokerCode': 'ANGEL_ONE', 'brokerClientId': 'A123', 'isSessionActive': false},
        {'brokerCode': 'ZEBU', 'brokerClientId': 'Z456', 'isSessionActive': true},
      ];
      expect(controller.isBrokerConfigured, true);
      expect(controller.isBrokerSessionActive, true);
    });

    test('isDailyConsentActive returns true only when consentsStatus is ACTIVE', () {
      controller.consentsStatus.value = 'NOT_GRANTED';
      expect(controller.isDailyConsentActive, false);

      controller.consentsStatus.value = 'REVOKED';
      expect(controller.isDailyConsentActive, false);

      controller.consentsStatus.value = 'ACTIVE';
      expect(controller.isDailyConsentActive, true);
    });

    test('hasActiveProxy validates proxy presence and active status', () {
      controller.proxyInfo.value = {'hasProxy': false, 'status': 'none'};
      expect(controller.hasActiveProxy, false);

      controller.proxyInfo.value = {'hasProxy': true, 'status': 'expired', 'ip': '1.2.3.4'};
      expect(controller.hasActiveProxy, false);

      controller.proxyInfo.value = {'hasProxy': true, 'status': 'active', 'ip': '1.2.3.4'};
      expect(controller.hasActiveProxy, true);
      expect(controller.staticIpAddress, '1.2.3.4');
    });

    test('isLotConfigured checks segment allocation baseLot > 0', () {
      controller.userSegments.value = [];
      expect(controller.isLotConfigured, false);

      controller.userSegments.value = [
        {'segmentCode': 'NIFTY_FUT', 'baseLot': 0}
      ];
      expect(controller.isLotConfigured, false);

      controller.userSegments.value = [
        {'segmentCode': 'NIFTY_FUT', 'baseLot': 2}
      ];
      expect(controller.isLotConfigured, true);
    });

    test('isStrategyConfigured validates currentStrategyData presence', () {
      controller.currentStrategyData.value = null;
      expect(controller.isStrategyConfigured, false);

      controller.currentStrategyData.value = {'strategy': {'strategyType': 'LOSS_MULTIPLIER_2X'}};
      expect(controller.isStrategyConfigured, true);
    });
  });
}
