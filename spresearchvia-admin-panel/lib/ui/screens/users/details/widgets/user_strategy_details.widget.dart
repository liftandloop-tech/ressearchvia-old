import 'package:flutter/material.dart';
import 'package:spresearch_web/config/theme.config.dart';
import 'package:spresearch_web/config/app.config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class UserStrategyDetailsWidget extends StatefulWidget {
  final String userId;
  const UserStrategyDetailsWidget({super.key, required this.userId});

  @override
  State<UserStrategyDetailsWidget> createState() => _UserStrategyDetailsWidgetState();
}

class _UserStrategyDetailsWidgetState extends State<UserStrategyDetailsWidget> {
  bool _isLoading = false;
  Map<String, dynamic>? _cardData;
  List<dynamic> _history = [];

  @override
  void initState() {
    super.initState();
    _fetchStrategyData();
  }

  Future<void> _fetchStrategyData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final url = Uri.parse('${AppConfig.automatedApiBaseUrl}/ops/users/${widget.userId}/strategy');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        setState(() {
          _cardData = body['card'];
          _history = body['history'] ?? [];
        });
      } else {
        // Fallback default view if record not found
        setState(() {
          _cardData = {
            'automatedTrading': 'Inactive',
            'strategy': 'Fixed 1×',
            'strategyType': 'FIXED_1X',
            'baseMultiplier': '1×',
            'currentMultiplier': '1×',
            'lastTradeResult': 'None',
            'consecutiveLosses': 0,
            'nextTradeMultiplier': '1×',
            'strategySelectedOn': null,
            'agreementVersion': 'v1.0',
            'consentStatus': 'Pending',
          };
          _history = [];
        });
      }
    } catch (e) {
      setState(() {
        _cardData = {
          'automatedTrading': 'Inactive',
          'strategy': 'Fixed 1×',
          'strategyType': 'FIXED_1X',
          'baseMultiplier': '1×',
          'currentMultiplier': '1×',
          'lastTradeResult': 'None',
          'consecutiveLosses': 0,
          'nextTradeMultiplier': '1×',
          'strategySelectedOn': null,
          'agreementVersion': 'v1.0',
          'consentStatus': 'Pending',
        };
        _history = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
          border: Border.all(color: AppTheme.gray200),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final card = _cardData ?? {};
    final isActive = card['automatedTrading'] == 'Active';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusDefault),
        border: Border.all(color: AppTheme.gray200),
      ),
      padding: EdgeInsets.all(AppTheme.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: AppTheme.primaryBlue, size: 20),
                  ),
                  SizedBox(width: AppTheme.spacing12),
                  Text(
                    'Automated Trading & Strategy Configuration',
                    style: AppTheme.h5Style.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20, color: AppTheme.primaryBlue),
                onPressed: _fetchStrategyData,
                tooltip: 'Refresh Strategy State',
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Compliance Notice Banner (Admin Cannot Silently Change)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xffEFF6FF),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xffBFDBFE)),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xff1D4ED8), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Read-Only Enforcement: Strategy is legally selected by the client during daily consent. Admin cannot silently alter user strategy without explicit client acceptance.',
                    style: TextStyle(color: Colors.blue.shade900, fontSize: 12, height: 1.3),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 10-Field Grid Table
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.gray200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildTableRow('Automated Trading', card['automatedTrading'] ?? 'Inactive', isBadge: true, isSuccess: isActive),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Position Sizing Strategy', card['strategy'] ?? 'Fixed 1×', isHighlight: true),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Base Multiplier', card['baseMultiplier'] ?? '1×'),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Current Multiplier', card['currentMultiplier'] ?? '1×', isBold: true, isChip: true),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Last Trade Result', card['lastTradeResult'] ?? 'None', isOutcome: true),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Consecutive Losses', '${card["consecutiveLosses"] ?? 0}', isCounter: true),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Next Trade Multiplier', card['nextTradeMultiplier'] ?? '1×', isNext: true),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Strategy Selected On', card['strategySelectedOn'] != null ? card['strategySelectedOn'].toString().substring(0, 10) : '—'),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Agreement Version', card['agreementVersion'] ?? 'v1.0'),
                const Divider(height: 1, color: AppTheme.gray200),
                _buildTableRow('Consent Status', card['consentStatus'] ?? 'Pending', isBadge: true, isSuccess: card['consentStatus'] == 'Accepted'),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Strategy Version History Sub-Tab
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Strategy Version History',
                style: AppTheme.h5Style.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              Text(
                '${_history.length} audit transitions recorded',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.gray50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.gray200),
              ),
              child: const Center(
                child: Text(
                  'No strategy changes on record. User is operating on default initial agreement.',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.gray200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(const Color(0xffF8FAFC)),
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xff475569)),
                  dataTextStyle: const TextStyle(fontSize: 12.5, color: Colors.black87),
                  columnSpacing: 24,
                  columns: const [
                    DataColumn(label: Text('Date / Time')),
                    DataColumn(label: Text('Previous')),
                    DataColumn(label: Text('New Strategy')),
                    DataColumn(label: Text('Changed By')),
                    DataColumn(label: Text('Agreement')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: _history.map((h) {
                    final date = h['dateTime'] != null ? h['dateTime'].toString().replaceAll('T', ' ').substring(0, 16) : '—';
                    return DataRow(cells: [
                      DataCell(Text(date)),
                      DataCell(Text(h['previous'] ?? '—')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xffEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          h['new'] ?? '1×',
                          style: const TextStyle(color: Color(0xff1D4ED8), fontWeight: FontWeight.w600),
                        ),
                      )),
                      DataCell(Text(h['changedBy'] ?? 'User')),
                      DataCell(Text(h['agreement'] ?? 'v1.0')),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xffECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          h['status'] ?? 'Accepted',
                          style: const TextStyle(color: Color(0xff059669), fontWeight: FontWeight.w600),
                        ),
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String label,
    String value, {
    bool isBadge = false,
    bool isSuccess = false,
    bool isHighlight = false,
    bool isBold = false,
    bool isChip = false,
    bool isOutcome = false,
    bool isCounter = false,
    bool isNext = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xff64748B), fontWeight: FontWeight.w500),
          ),
          if (isBadge)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isSuccess ? const Color(0xffECFDF5) : const Color(0xffFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSuccess ? const Color(0xffA7F3D0) : const Color(0xffFECACA)),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: isSuccess ? const Color(0xff059669) : const Color(0xffDC2626),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else if (isChip)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xff312E81),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            )
          else if (isOutcome)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: value.toLowerCase() == 'loss' ? Colors.red.shade50 : (value.toLowerCase() == 'profit' ? Colors.green.shade50 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: value.toLowerCase() == 'loss' ? Colors.red.shade700 : (value.toLowerCase() == 'profit' ? Colors.green.shade700 : Colors.grey.shade700),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            )
          else if (isNext)
            Text(
              value,
              style: const TextStyle(color: Color(0xff4F46E5), fontWeight: FontWeight.w700, fontSize: 13.5),
            )
          else
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight || isBold ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? const Color(0xff1E4A7C) : Colors.black87,
              ),
            ),
        ],
      ),
    );
  }
}
