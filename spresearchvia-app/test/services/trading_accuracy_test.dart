import 'package:flutter_test/flutter_test.dart';
import 'package:spresearchvia/core/models/research_report.dart';

void main() {
  group('TradingCallOutcome & TradingAccuracyStats Tests', () {
    test('Correctly classifies target achieved outcome from decisive updates', () {
      final report = ResearchReport(
        id: '1',
        title: 'Buy RELIANCE @ 2500',
        category: 'Equity Cash',
        description: 'Target 2550, SL 2470',
        reportPath: '',
        reportOriginalName: '',
        reportName: '',
        publishedStatus: 'published',
        updates: [
          ReportUpdate(
            text: 'Call initiated',
            status: 'general',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          ReportUpdate(
            text: 'Target 1 achieved, book partial',
            status: 'partial_profit',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          ReportUpdate(
            text: 'Final target 2550 achieved! All targets done',
            status: 'target_achieved',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      );

      expect(report.outcome, TradingCallOutcome.targetAchieved);
    });

    test('Correctly classifies partially booked outcome when partial profit is latest decisive update', () {
      final report = ResearchReport(
        id: '2',
        title: 'Buy TATASTEEL @ 150',
        category: 'Equity Cash',
        description: 'Target 158, SL 145',
        reportPath: '',
        reportOriginalName: '',
        reportName: '',
        publishedStatus: 'published',
        updates: [
          ReportUpdate(
            text: 'Call initiated',
            status: 'general',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          ReportUpdate(
            text: 'Target 1 reached, book 50% partial profit',
            status: 'partial_profit',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      );

      expect(report.outcome, TradingCallOutcome.partiallyBooked);
    });

    test('Correctly classifies stoploss hit outcome', () {
      final report = ResearchReport(
        id: '3',
        title: 'Buy INFY @ 1800',
        category: 'Equity Cash',
        description: 'Target 1860, SL 1765',
        reportPath: '',
        reportOriginalName: '',
        reportName: '',
        publishedStatus: 'published',
        updates: [
          ReportUpdate(
            text: 'SL triggered at 1765, kindly exit',
            status: 'stoploss_hit',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      );

      expect(report.outcome, TradingCallOutcome.stoplossHit);
    });

    test('Correctly classifies active call when no decisive update exists', () {
      final report = ResearchReport(
        id: '4',
        title: 'Buy HDFCBANK @ 1650',
        category: 'Equity Cash',
        description: 'Target 1720, SL 1610',
        reportPath: '',
        reportOriginalName: '',
        reportName: '',
        publishedStatus: 'published',
        updates: [
          ReportUpdate(
            text: 'Trailing SL moved to cost 1650',
            status: 'general',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      );

      expect(report.outcome, TradingCallOutcome.active);
    });

    test('Correctly calculates TradingAccuracyStats from report list', () {
      final reports = [
        // 2 Target Achieved
        ResearchReport(
          id: '1',
          title: 'Call 1',
          category: 'Cash',
          description: '',
          reportPath: '',
          reportOriginalName: '',
          reportName: '',
          publishedStatus: 'published',
          updates: [
            ReportUpdate(text: 'Target achieved', status: 'target_achieved', timestamp: DateTime.now()),
          ],
        ),
        ResearchReport(
          id: '2',
          title: 'Call 2 - Target hit',
          category: 'Cash',
          description: 'target achieved',
          reportPath: '',
          reportOriginalName: '',
          reportName: '',
          publishedStatus: 'published',
        ),
        // 1 Partially Booked
        ResearchReport(
          id: '3',
          title: 'Call 3',
          category: 'Cash',
          description: '',
          reportPath: '',
          reportOriginalName: '',
          reportName: '',
          publishedStatus: 'published',
          updates: [
            ReportUpdate(text: 'Book partial profit', status: 'partial_profit', timestamp: DateTime.now()),
          ],
        ),
        // 1 Stoploss Hit
        ResearchReport(
          id: '4',
          title: 'Call 4',
          category: 'Cash',
          description: '',
          reportPath: '',
          reportOriginalName: '',
          reportName: '',
          publishedStatus: 'published',
          updates: [
            ReportUpdate(text: 'Stoploss hit', status: 'stoploss_hit', timestamp: DateTime.now()),
          ],
        ),
        // 1 Active
        ResearchReport(
          id: '5',
          title: 'Call 5 Active',
          category: 'Cash',
          description: 'Call active in progress',
          reportPath: '',
          reportOriginalName: '',
          reportName: '',
          publishedStatus: 'published',
        ),
      ];

      final stats = TradingAccuracyStats.fromReports(reports);

      expect(stats.totalCalls, 5);
      expect(stats.closedCalls, 4); // 2 Target + 1 Partial + 1 SL
      expect(stats.targetAchieved, 2);
      expect(stats.partiallyBooked, 1);
      expect(stats.stoplossHit, 1);
      expect(stats.active, 1);
      // Accuracy = (2 + 1) / 4 = 75.0%
      expect(stats.accuracyRate, 75.0);
      expect(stats.targetRate, 50.0);
      expect(stats.partialRate, 25.0);
      expect(stats.stoplossRate, 25.0);
    });

    test('Correctly parses accuracy stats from API JSON payload', () {
      final json = {
        'totalCalls': 50,
        'closedCalls': 40,
        'targetAchieved': 30,
        'partiallyBooked': 6,
        'stoplossHit': 4,
        'active': 10,
        'accuracyRate': 90.0,
      };

      final stats = TradingAccuracyStats.fromJson(json);

      expect(stats.totalCalls, 50);
      expect(stats.closedCalls, 40);
      expect(stats.targetAchieved, 30);
      expect(stats.partiallyBooked, 6);
      expect(stats.stoplossHit, 4);
      expect(stats.active, 10);
      expect(stats.accuracyRate, 90.0);
    });
  });
}
