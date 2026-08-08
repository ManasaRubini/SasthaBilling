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
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _load();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ApiService.getMe();
      setState(() => _currentUser = user);
    } catch (_) {}
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
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.receipt, color: AppTheme.saffron),
                                          onPressed: () => Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(bill: bill)),
                                          ),
                                          tooltip: 'Print',
                                        ),
                                        if (_currentUser?.isAdmin == true && bill.status == 'active') ...[
                                          IconButton(
                                            icon: const Icon(Icons.edit, color: Colors.blue),
                                            onPressed: () => _editBillDialog(bill),
                                            tooltip: 'Edit',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel_outlined, color: AppTheme.error),
                                            onPressed: () => _cancelBill(bill),
                                            tooltip: 'Cancel',
                                          ),
                                        ],
                                      ],
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

  Future<void> _cancelBill(Bill bill) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('பில் ரத்து செய்ய உறுதிப்படுத்தவும்'),
        content: Text('நீங்கள் ரசீது எண் ${bill.receiptNo} ஐ ரத்து செய்ய விரும்புகிறீர்களா?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('மூடு / Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ரத்து செய் / Confirm', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      setState(() => _loading = true);
      try {
        await ApiService.cancelBill(bill.billId);
        _load();
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _editBillDialog(Bill bill) async {
    final amountController = TextEditingController(text: bill.amount.toString());
    final categoryController = TextEditingController(text: bill.category ?? '');
    final remarksController = TextEditingController(text: bill.remarks ?? '');
    String selectedMethod = bill.paymentMethod;
    String selectedType = bill.billType;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('ரசீது திருத்து / Edit Receipt'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'பில் வகை / Type'),
                      items: const [
                        DropdownMenuItem(value: 'வரி', child: Text('வரி')),
                        DropdownMenuItem(value: 'காணிக்கை', child: Text('காணிக்கை')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedType = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: categoryController,
                      decoration: const InputDecoration(labelText: 'வகை / Category'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'தொகை / Amount'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      decoration: const InputDecoration(labelText: 'செலுத்தும் முறை / Method'),
                      items: const [
                        DropdownMenuItem(value: 'பணம்', child: Text('பணம்')),
                        DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                        DropdownMenuItem(value: 'கார்டு', child: Text('கார்டு')),
                        DropdownMenuItem(value: 'காசோலை', child: Text('காசோலை')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedMethod = val);
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(labelText: 'குறிப்பு / Remarks'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('மூடு / Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('புதுப்பி / Update'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final double? amt = double.tryParse(amountController.text);
      if (amt == null || amt <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid amount'), backgroundColor: AppTheme.error),
        );
        return;
      }

      setState(() => _loading = true);
      try {
        await ApiService.updateBill(bill.billId, {
          'bill_type': selectedType,
          'category': categoryController.text.trim().isEmpty ? null : categoryController.text.trim(),
          'amount': amt,
          'payment_method': selectedMethod,
          'remarks': remarksController.text.trim().isEmpty ? null : remarksController.text.trim(),
        });
        _load();
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
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