import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
  Map<String, dynamic>? _todayFinance;
  Map<String, dynamic>? _monthFinance;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await ApiService.getDashboard();
      
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final monthStart = DateTime(now.year, now.month, 1);
      
      final todayFinance = await ApiService.getTransactionsSummary(
        fromDate: todayStart,
        toDate: now,
      );
      final monthFinance = await ApiService.getTransactionsSummary(
        fromDate: monthStart,
        toDate: now,
      );
      
      setState(() {
        _stats = stats;
        _todayFinance = todayFinance;
        _monthFinance = monthFinance;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildFinancePeriodCard({
    required String title,
    required double income,
    required double expense,
    required double net,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54),
            ),
            const Divider(height: 16),
            _buildFinanceRow('income'.tr(), '+ ₹${income.toStringAsFixed(0)}', AppTheme.success),
            const SizedBox(height: 8),
            _buildFinanceRow('expense'.tr(), '- ₹${expense.toStringAsFixed(0)}', AppTheme.error),
            const Divider(height: 16),
            _buildFinanceRow(
              'net_balance'.tr(), 
              '₹${net.toStringAsFixed(0)}', 
              net >= 0 ? AppTheme.saffron : AppTheme.error,
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12, 
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppTheme.dark : Colors.black87,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13, 
            fontWeight: FontWeight.bold, 
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;
    int crossAxisCount = width > 1100 ? 4 : (width > 700 ? 3 : 2);

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(title: Text('nav_dashboard'.tr())),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'nav_dashboard'.tr(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dark),
                  ),
                ),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: AppTheme.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: Text('retry'.tr())),
                      ],
                    ),
                  ),
                )
              else if (_stats != null) ...[
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.35 : 1.1,
                  children: [
                    StatCard(
                      title: 'today_collection'.tr(),
                      subtitle: '',
                      value: '₹${_stats!.todayCollection.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      color: AppTheme.saffron,
                    ),
                    StatCard(
                      title: 'today_vari'.tr(),
                      subtitle: '',
                      value: '₹${_stats!.todayVari.toStringAsFixed(2)}',
                      icon: Icons.request_quote,
                      color: AppTheme.gold,
                    ),
                    StatCard(
                      title: 'today_kanikkai'.tr(),
                      subtitle: '',
                      value: '₹${_stats!.todayKanikkai.toStringAsFixed(2)}',
                      icon: Icons.volunteer_activism,
                      color: AppTheme.darkOrange,
                    ),
                    StatCard(
                      title: 'today_bills'.tr(),
                      subtitle: '',
                      value: '${_stats!.todayBillsCount}',
                      icon: Icons.receipt_long,
                      color: AppTheme.success,
                    ),
                    StatCard(
                      title: 'total_devotees'.tr(),
                      subtitle: '',
                      value: '${_stats!.totalDevotees}',
                      icon: Icons.people,
                      color: Colors.blueGrey,
                    ),
                    StatCard(
                      title: 'total_staff'.tr(),
                      subtitle: '',
                      value: '${_stats!.totalStaff}',
                      icon: Icons.badge,
                      color: Colors.purple,
                    ),
                    StatCard(
                      title: 'monthly_collection'.tr(),
                      subtitle: '',
                      value: '₹${_stats!.monthlyCollection.toStringAsFixed(2)}',
                      icon: Icons.calendar_month,
                      color: AppTheme.darkOrange,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                const Text(
                  'Financial Overview / நிதி மேலாண்மை',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.dark),
                ),
                const SizedBox(height: 12),
                if (_todayFinance != null && _monthFinance != null)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth <= 600;
                      if (isMobile) {
                        return Column(
                          children: [
                            _buildFinancePeriodCard(
                              title: "TODAY / இன்று",
                              income: double.tryParse(_todayFinance!['total_income'].toString()) ?? 0,
                              expense: double.tryParse(_todayFinance!['total_expense'].toString()) ?? 0,
                              net: double.tryParse(_todayFinance!['net_balance'].toString()) ?? 0,
                            ),
                            const SizedBox(height: 12),
                            _buildFinancePeriodCard(
                              title: "THIS MONTH / இந்த மாதம்",
                              income: double.tryParse(_monthFinance!['total_income'].toString()) ?? 0,
                              expense: double.tryParse(_monthFinance!['total_expense'].toString()) ?? 0,
                              net: double.tryParse(_monthFinance!['net_balance'].toString()) ?? 0,
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: _buildFinancePeriodCard(
                              title: "TODAY / இன்று",
                              income: double.tryParse(_todayFinance!['total_income'].toString()) ?? 0,
                              expense: double.tryParse(_todayFinance!['total_expense'].toString()) ?? 0,
                              net: double.tryParse(_todayFinance!['net_balance'].toString()) ?? 0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFinancePeriodCard(
                              title: "THIS MONTH / இந்த மாதம்",
                              income: double.tryParse(_monthFinance!['total_income'].toString()) ?? 0,
                              expense: double.tryParse(_monthFinance!['total_expense'].toString()) ?? 0,
                              net: double.tryParse(_monthFinance!['net_balance'].toString()) ?? 0,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}