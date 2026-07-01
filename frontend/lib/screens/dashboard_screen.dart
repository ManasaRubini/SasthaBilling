import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? _stats;
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
      setState(() => _stats = stats);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;
    int crossAxisCount = width > 1100 ? 4 : (width > 700 ? 3 : 2);

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(title: const Text('முகப்பு / Dashboard')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'முகப்பு / Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dark),
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
                        ElevatedButton(onPressed: _load, child: const Text('மீண்டும் முயற்சி')),
                      ],
                    ),
                  ),
                )
              else if (_stats != null)
                GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                  children: [
                    StatCard(
                      title: 'இன்று வசூல்',
                      subtitle: "Today's Collection",
                      value: '₹${_stats!.todayCollection.toStringAsFixed(2)}',
                      icon: Icons.account_balance_wallet,
                      color: AppTheme.saffron,
                    ),
                    StatCard(
                      title: 'மொத்த வரி',
                      subtitle: 'Total Tax (Today)',
                      value: '₹${_stats!.todayVari.toStringAsFixed(2)}',
                      icon: Icons.request_quote,
                      color: AppTheme.gold,
                    ),
                    StatCard(
                      title: 'மொத்த காணிக்கை',
                      subtitle: 'Total Donation (Today)',
                      value: '₹${_stats!.todayKanikkai.toStringAsFixed(2)}',
                      icon: Icons.volunteer_activism,
                      color: AppTheme.darkOrange,
                    ),
                    StatCard(
                      title: 'இன்று ரசீதுகள்',
                      subtitle: "Today's Receipts",
                      value: '${_stats!.todayBillsCount}',
                      icon: Icons.receipt_long,
                      color: AppTheme.success,
                    ),
                    StatCard(
                      title: 'மொத்த பக்தர்கள்',
                      subtitle: 'Total Devotees',
                      value: '${_stats!.totalDevotees}',
                      icon: Icons.people,
                      color: Colors.blueGrey,
                    ),
                    StatCard(
                      title: 'மொத்த பணியாளர்கள்',
                      subtitle: 'Total Staff',
                      value: '${_stats!.totalStaff}',
                      icon: Icons.badge,
                      color: Colors.purple,
                    ),
                    StatCard(
                      title: 'இந்த மாத வசூல்',
                      subtitle: 'Monthly Collection',
                      value: '₹${_stats!.monthlyCollection.toStringAsFixed(2)}',
                      icon: Icons.calendar_month,
                      color: AppTheme.darkOrange,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}