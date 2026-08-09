import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  DateTime _fromDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _toDate = DateTime.now();

  List<dynamic> _transactions = [];
  Map<String, dynamic>? _summary;
  bool _loading = true;
  String? _error;

  String _selectedType = 'ALL';
  String? _selectedCategory;
  String? _selectedPaymentMethod;

  final List<String> _types = ['ALL', 'INCOME', 'EXPENSE'];
  final List<String> _paymentMethods = ['All', 'பணம்', 'UPI', 'கார்டு', 'காசோலை'];
  
  // Existing categories from bills + expenses
  final List<String> _categories = [
    'All', 'Archana', 'Abhishekam', 'Donation', 'Electricity', 'Flowers', 
    'Pooja Materials', 'Maintenance', 'Cleaning', 'Salary', 'Food', 
    'Decoration', 'Transport', 'Stationery', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await ApiService.getTransactionsSummary(
        fromDate: DateTime(_fromDate.year, _fromDate.month, _fromDate.day),
        toDate: DateTime(_toDate.year, _toDate.month, _toDate.day),
      );

      final txns = await ApiService.getTransactions(
        fromDate: DateTime(_fromDate.year, _fromDate.month, _fromDate.day),
        toDate: DateTime(_toDate.year, _toDate.month, _toDate.day),
        type: _selectedType == 'ALL' ? null : _selectedType,
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        paymentMethod: _selectedPaymentMethod == 'All' ? null : _selectedPaymentMethod,
        limit: 100
      );

      setState(() {
        _summary = summary;
        _transactions = txns;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _fromDate, end: _toDate),
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.saffron,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.dark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      _loadData();
    }
  }

  String _formatDateString(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthsTa = ['ஜன', 'பிப்', 'மார்', 'ஏப்', 'மே', 'ஜூன்', 'ஜூலை', 'ஆக', 'செப்', 'அக்', 'நவ', 'டிச'];
      final month = Translation.currentLanguage == 'ta' ? monthsTa[parsed.month - 1] : monthsEn[parsed.month - 1];
      return '${parsed.day.toString().padLeft(2, '0')} $month ${parsed.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatTimeString(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      final min = parsed.minute.toString().padLeft(2, '0');
      final hour = parsed.hour;
      final period = hour >= 12 ? 'PM' : 'AM';
      final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$formattedHour:$min $period';
    } catch (_) {
      return '';
    }
  }

  Map<String, List<dynamic>> _groupTransactionsByDate() {
    final Map<String, List<dynamic>> groups = {};
    for (var txn in _transactions) {
      final dateKey = txn['transaction_date'].toString().split('T')[0];
      if (!groups.containsKey(dateKey)) {
        groups[dateKey] = [];
      }
      groups[dateKey]!.add(txn);
    }
    return groups;
  }

  Map<String, double> _calculateDailySum(List<dynamic> dailyTxns) {
    double income = 0;
    double expense = 0;
    for (var txn in dailyTxns) {
      if (txn['status'] == 'cancelled') continue;
      final amt = double.tryParse(txn['amount'].toString()) ?? 0.0;
      if (txn['transaction_type'] == 'INCOME') {
        income += amt;
      } else if (txn['transaction_type'] == 'EXPENSE') {
        expense += amt;
      }
    }
    return {'income': income, 'expense': expense, 'net': income - expense};
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      appBar: isWide ? null : AppBar(title: Text('nav_transactions'.tr())),
      body: RefreshIndicator(
        onRefresh: _loadData,
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
                    'nav_transactions'.tr(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dark),
                  ),
                ),
              
              // Date Range selector
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: _selectDateRange,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.date_range, color: AppTheme.saffron),
                            const SizedBox(width: 12),
                            Text(
                              '${_formatDateString(_fromDate.toIso8601String())}  →  ${_formatDateString(_toDate.toIso8601String())}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Date Range Summary Metrics
              if (_summary != null)
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        'total_income'.tr(),
                        '₹${(double.tryParse(_summary!['total_income'].toString()) ?? 0).toStringAsFixed(0)}',
                        AppTheme.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        'total_expense'.tr(),
                        '₹${(double.tryParse(_summary!['total_expense'].toString()) ?? 0).toStringAsFixed(0)}',
                        AppTheme.error,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _metricCard(
                        'net_balance'.tr(),
                        '₹${(double.tryParse(_summary!['net_balance'].toString()) ?? 0).toStringAsFixed(0)}',
                        AppTheme.saffron,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),

              // Filters row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Type Filter Tabs
                    ..._types.map((type) {
                      final isSel = _selectedType == type;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedType = type);
                          _loadData();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? AppTheme.saffron : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSel ? AppTheme.saffron : Colors.black12),
                          ),
                          child: Text(
                            type == 'ALL' ? 'all_transactions'.tr() : (type == 'INCOME' ? 'income'.tr() : 'expense'.tr()),
                            style: TextStyle(
                              color: isSel ? Colors.white : AppTheme.dark,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    // Category drop-down filter
                    _dropdownFilter(
                      value: _selectedCategory ?? 'All',
                      items: _categories,
                      onChanged: (val) {
                        setState(() => _selectedCategory = val == 'All' ? null : val);
                        _loadData();
                      },
                    ),
                    const SizedBox(width: 8),
                    // Payment Method drop-down filter
                    _dropdownFilter(
                      value: _selectedPaymentMethod ?? 'All',
                      items: _paymentMethods,
                      onChanged: (val) {
                        setState(() => _selectedPaymentMethod = val == 'All' ? null : val);
                        _loadData();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Transaction Statement Timeline list
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
                  ),
                )
              else if (_transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 50, color: Colors.black.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        const Text(
                          'No transactions recorded / பரிவர்த்தனைகள் இல்லை',
                          style: TextStyle(color: Colors.black45, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ..._groupTransactionsByDate().entries.map((entry) {
                  final dateKey = entry.key;
                  final list = entry.value;
                  final dailyStats = _calculateDailySum(list);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Daily Date header row with summary totals
                      Padding(
                        padding: const EdgeInsets.only(top: 14, bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDateString(dateKey),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            Text(
                              'In: ₹${dailyStats['income']!.toStringAsFixed(0)} · Out: ₹${dailyStats['expense']!.toStringAsFixed(0)} · Net: ₹${dailyStats['net']!.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: dailyStats['net']! >= 0 ? AppTheme.success : AppTheme.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // List of transactions for this date
                      ...list.map((txn) => _buildTransactionCard(txn)),
                    ],
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 17)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _dropdownFilter({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(color: AppTheme.dark, fontSize: 12, fontWeight: FontWeight.w600),
          onChanged: onChanged,
          items: items.map((i) {
            String label = i;
            if (i == 'All') label = Translation.currentLanguage == 'ta' ? 'அனைத்தும்' : 'All';
            return DropdownMenuItem(value: i, child: Text(label));
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(dynamic txn) {
    final isIncome = txn['transaction_type'] == 'INCOME';
    final isCancelled = txn['status'] == 'cancelled';
    
    final amt = double.tryParse(txn['amount'].toString()) ?? 0.0;
    final categoryStr = txn['category'].toString();
    final refStr = txn['reference_number'] ?? '';
    final remarksStr = txn['remarks'] ?? '';
    final timeStr = _formatTimeString(txn['transaction_date']);
    
    // Display local localization for type
    final typeDisplay = isIncome 
      ? (Translation.currentLanguage == 'ta' ? 'வருமானம்' : 'INCOME')
      : (Translation.currentLanguage == 'ta' ? 'செலவு' : 'EXPENSE');

    // Visual indicators: grey if cancelled, green for income, red for expense
    Color valColor = isCancelled 
      ? Colors.black26 
      : (isIncome ? AppTheme.success : AppTheme.error);
    
    String prefix = isCancelled ? '' : (isIncome ? '+ ' : '- ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left icon container
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCancelled 
                    ? Colors.black12 
                    : (isIncome ? AppTheme.success.withOpacity(0.12) : AppTheme.error.withOpacity(0.12)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCancelled 
                    ? Icons.cancel_outlined 
                    : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                color: isCancelled 
                    ? Colors.black38 
                    : (isIncome ? AppTheme.success : AppTheme.error),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            // Middle section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                          color: isCancelled ? Colors.black38 : AppTheme.dark,
                        ),
                      ),
                      Text(
                        '$prefix₹${amt.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: valColor,
                          decoration: isCancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$typeDisplay · ${txn['payment_method']}',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                  if (refStr.isNotEmpty || remarksStr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      [refStr, remarksStr].where((s) => s.isNotEmpty).join(' · '),
                      style: const TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                    ),
                  ],
                  if (isCancelled) ...[
                    const SizedBox(height: 4),
                    Text(
                      Translation.currentLanguage == 'ta' ? 'ரத்து செய்யப்பட்டது (Cancelled)' : 'Cancelled',
                      style: const TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
