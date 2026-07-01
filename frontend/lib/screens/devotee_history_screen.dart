import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../models/models.dart';
import 'receipt_preview_screen.dart';

class DevoteeHistoryScreen extends StatefulWidget {
  final Devotee devotee;
  const DevoteeHistoryScreen({super.key, required this.devotee});

  @override
  State<DevoteeHistoryScreen> createState() => _DevoteeHistoryScreenState();
}

class _DevoteeHistoryScreenState extends State<DevoteeHistoryScreen> {
  List<Bill> _bills = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final bills = await ApiService.getDevoteeHistory(widget.devotee.devoteeId);
      setState(() => _bills = bills);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  double get _totalVari => _bills.where((b) => b.billType == 'வரி').fold(0, (s, b) => s + b.amount);
  double get _totalKanikkai => _bills.where((b) => b.billType == 'காணிக்கை').fold(0, (s, b) => s + b.amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.devotee.devoteeName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppTheme.saffron, AppTheme.darkOrange]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _summaryItem('மொத்த வரி', '₹${_totalVari.toStringAsFixed(0)}'),
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          Expanded(
                            child: _summaryItem('மொத்த காணிக்கை', '₹${_totalKanikkai.toStringAsFixed(0)}'),
                          ),
                          Container(width: 1, height: 40, color: Colors.white24),
                          Expanded(
                            child: _summaryItem('பில்கள்', '${_bills.length}'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _bills.isEmpty
                          ? const Center(child: Text('பில்லிங் வரலாறு இல்லை', style: TextStyle(color: Colors.black54)))
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              itemCount: _bills.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final bill = _bills[index];
                                final isVari = bill.billType == 'வரி';
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isVari ? AppTheme.lightOrange : AppTheme.gold.withOpacity(0.2),
                                      child: Icon(
                                        isVari ? Icons.request_quote : Icons.volunteer_activism,
                                        color: isVari ? AppTheme.darkOrange : AppTheme.gold,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text('${bill.billType} - ₹${bill.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      '${_formatDate(bill.billDate)} · ${bill.receiptNo}\n${bill.paymentMethod}${bill.category != null ? ' · ${bill.category}' : ''}',
                                    ),
                                    isThreeLine: true,
                                    trailing: IconButton(
                                      icon: const Icon(Icons.receipt, color: AppTheme.saffron),
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(bill: bill)),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }
}