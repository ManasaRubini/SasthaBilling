import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Map<String, dynamic>? _dailyData;
  Map<String, dynamic>? _monthlyData;
  Map<String, dynamic>? _staffData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final daily = await ApiService.getDailyReport();
      final monthly = await ApiService.getMonthlyReport();
      Map<String, dynamic>? staff;
      try {
        staff = await ApiService.getStaffReport();
      } catch (_) {
        staff = null; // non-admin users won't have access
      }
      setState(() {
        _dailyData = daily;
        _monthlyData = monthly;
        _staffData = staff;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: isWide ? null : const Text('அறிக்கைகள் / Reports'),
        automaticallyImplyLeading: false,
        toolbarHeight: isWide ? 0 : null,
        bottom: TabBar(
          controller: _tabController,
          labelColor: isWide ? AppTheme.darkOrange : Colors.white,
          unselectedLabelColor: isWide ? Colors.black54 : Colors.white70,
          indicatorColor: isWide ? AppTheme.saffron : Colors.white,
          tabs: const [
            Tab(text: 'தினசரி / Daily'),
            Tab(text: 'மாதாந்திர / Monthly'),
            Tab(text: 'பணியாளர் / Staff'),
          ],
        ),
        backgroundColor: isWide ? Colors.white : AppTheme.saffron,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadAll,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _dailyReportTab(),
                      _monthlyReportTab(),
                      _staffReportTab(),
                    ],
                  ),
      ),
    );
  }

  Widget _dailyReportTab() {
    if (_dailyData == null) return const SizedBox();
    final bills = (_dailyData!['bills'] as List?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_dailyData!['date'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat('மொத்தம்', '₹${(_dailyData!['total_amount'] ?? 0).toStringAsFixed(0)}', AppTheme.saffron)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('வரி', '₹${(_dailyData!['vari_amount'] ?? 0).toStringAsFixed(0)}', AppTheme.gold)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('காணிக்கை', '₹${(_dailyData!['kanikkai_amount'] ?? 0).toStringAsFixed(0)}', AppTheme.darkOrange)),
            ],
          ),
          const SizedBox(height: 20),
          const Text('பணம் செலுத்தும் முறை வாரியாக', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _miniStat('பணம்', '₹${(_dailyData!['cash_amount'] ?? 0).toStringAsFixed(0)}', AppTheme.success)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('UPI', '₹${(_dailyData!['upi_amount'] ?? 0).toStringAsFixed(0)}', Colors.blue)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('கார்டு', '₹${(_dailyData!['card_amount'] ?? 0).toStringAsFixed(0)}', Colors.purple)),
            ],
          ),
          const SizedBox(height: 24),
          Text('ரசீதுகள் (${bills.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (bills.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('இன்று பில்கள் இல்லை', style: TextStyle(color: Colors.black45))),
            )
          else
            _table(
              headers: const ['ரசீது எண்', 'பக்தர்', 'வகை', 'தொகை', 'பணியாளர்'],
              rows: bills.map<List<String>>((b) => [
                b['receipt_no'].toString(),
                b['devotee_name'].toString(),
                b['bill_type'].toString(),
                '₹${(b['amount'] as num).toStringAsFixed(0)}',
                b['staff_name'].toString(),
              ]).toList(),
            ),
        ],
      ),
    );
  }

  Widget _monthlyReportTab() {
    if (_monthlyData == null) return const SizedBox();
    final daily = (_monthlyData!['daily_breakdown'] as List?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_monthlyData!['month']}/${_monthlyData!['year']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _miniStat('மொத்தம்', '₹${(_monthlyData!['total_collection'] ?? 0).toStringAsFixed(0)}', AppTheme.saffron)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('வரி', '₹${(_monthlyData!['vari_total'] ?? 0).toStringAsFixed(0)}', AppTheme.gold)),
              const SizedBox(width: 10),
              Expanded(child: _miniStat('காணிக்கை', '₹${(_monthlyData!['kanikkai_total'] ?? 0).toStringAsFixed(0)}', AppTheme.darkOrange)),
            ],
          ),
          const SizedBox(height: 24),
          Text('நாள் வாரியான பகுப்பு (${daily.length} நாட்கள்)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),
          if (daily.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('இந்த மாதம் தரவு இல்லை', style: TextStyle(color: Colors.black45))),
            )
          else
            _table(
              headers: const ['தேதி', 'பில்கள்', 'வரி', 'காணிக்கை', 'மொத்தம்'],
              rows: daily.map<List<String>>((d) => [
                d['date'].toString(),
                d['count'].toString(),
                '₹${(d['vari'] as num).toStringAsFixed(0)}',
                '₹${(d['kanikkai'] as num).toStringAsFixed(0)}',
                '₹${(d['total'] as num).toStringAsFixed(0)}',
              ]).toList(),
            ),
        ],
      ),
    );
  }

  Widget _staffReportTab() {
    if (_staffData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Text(
            'பணியாளர் அறிக்கைகளை நிர்வாகி மட்டுமே பார்க்க முடியும்\n(Admin access required)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black45),
          ),
        ),
      );
    }
    final staffList = (_staffData!['staff_reports'] as List?) ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_staffData!['date'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          if (staffList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: Text('பணியாளர் தரவு இல்லை', style: TextStyle(color: Colors.black45))),
            )
          else
            _table(
              headers: const ['பணியாளர்', 'பில்கள்', 'வரி', 'காணிக்கை', 'மொத்தம்'],
              rows: staffList.map<List<String>>((s) => [
                s['staff_name'].toString(),
                s['bill_count'].toString(),
                '₹${(s['vari_amount'] as num).toStringAsFixed(0)}',
                '₹${(s['kanikkai_amount'] as num).toStringAsFixed(0)}',
                '₹${(s['total_amount'] as num).toStringAsFixed(0)}',
              ]).toList(),
            ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _table({required List<String> headers, required List<List<String>> rows}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
          rows: rows
              .map((row) => DataRow(cells: row.map((cell) => DataCell(Text(cell))).toList()))
              .toList(),
        ),
      ),
    );
  }
}