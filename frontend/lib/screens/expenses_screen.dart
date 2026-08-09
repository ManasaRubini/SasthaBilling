import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../models/models.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<dynamic> _expenses = [];
  bool _loading = true;
  String? _error;
  User? _currentUser;

  // Categories list
  final List<String> _categories = [
    'Electricity', 'Flowers', 'Pooja Materials', 'Maintenance', 
    'Cleaning', 'Salary', 'Food', 'Decoration', 'Transport', 
    'Stationery', 'Other'
  ];

  // Payment methods list
  final List<String> _paymentMethods = ['பணம்', 'UPI', 'கார்டு', 'காசோலை'];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadExpenses();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ApiService.getMe();
      setState(() => _currentUser = user);
    } catch (_) {}
  }

  Future<void> _loadExpenses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Fetch financial transactions of type EXPENSE
      final list = await ApiService.getTransactions(type: 'EXPENSE', limit: 100);
      setState(() => _expenses = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
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

  double _calculateTotalExpenses() {
    double total = 0.0;
    for (var exp in _expenses) {
      if (exp['status'] == 'cancelled') continue;
      total += double.tryParse(exp['amount'].toString()) ?? 0.0;
    }
    return total;
  }

  void _showExpenseDialog({Map<String, dynamic>? expenseToEdit}) {
    final formKey = GlobalKey<FormState>();
    
    DateTime selectedDate = expenseToEdit != null 
        ? DateTime.parse(expenseToEdit['transaction_date']).toLocal() 
        : DateTime.now();
        
    String selectedCategory = expenseToEdit != null && _categories.contains(expenseToEdit['category'])
        ? expenseToEdit['category'] 
        : _categories.first;
        
    String selectedPaymentMethod = expenseToEdit != null && _paymentMethods.contains(expenseToEdit['payment_method'])
        ? expenseToEdit['payment_method'] 
        : _paymentMethods.first;

    final descController = TextEditingController(text: expenseToEdit != null ? expenseToEdit['description'] : '');
    final amountController = TextEditingController(text: expenseToEdit != null ? (double.tryParse(expenseToEdit['amount'].toString())?.toStringAsFixed(0) ?? '') : '');
    final refController = TextEditingController(text: expenseToEdit != null ? expenseToEdit['reference_number'] : '');
    final remarksController = TextEditingController(text: expenseToEdit != null ? expenseToEdit['remarks'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(expenseToEdit == null ? 'add_expense'.tr() : 'edit_expense'.tr()),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date Picker field
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: AppTheme.saffron),
                        title: Text('${'expense_date'.tr()}: ${_formatDateString(selectedDate.toIso8601String())}'),
                        trailing: const Icon(Icons.edit, size: 16),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                      ),
                      
                      // Category selection
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(labelText: 'expense_category'.tr()),
                        items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCategory = val!),
                      ),
                      const SizedBox(height: 10),

                      // Description
                      TextFormField(
                        controller: descController,
                        decoration: InputDecoration(labelText: 'expense_description'.tr()),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Please enter description' : null,
                      ),
                      const SizedBox(height: 10),

                      // Amount
                      TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(labelText: 'amount'.tr(), prefixText: '₹'),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Please enter amount';
                          final numVal = double.tryParse(val);
                          if (numVal == null || numVal <= 0) return 'Please enter valid positive amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Payment Method
                      DropdownButtonFormField<String>(
                        value: selectedPaymentMethod,
                        decoration: InputDecoration(labelText: 'payment_method'.tr()),
                        items: _paymentMethods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) => setDialogState(() => selectedPaymentMethod = val!),
                      ),
                      const SizedBox(height: 10),

                      // Reference
                      TextFormField(
                        controller: refController,
                        decoration: InputDecoration(labelText: 'reference_no'.tr()),
                      ),
                      const SizedBox(height: 10),

                      // Remarks
                      TextFormField(
                        controller: remarksController,
                        decoration: InputDecoration(labelText: 'remarks'.tr()),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('cancel'.tr()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
                      setState(() => _loading = true);
                      try {
                        if (expenseToEdit == null) {
                          await ApiService.createExpense(
                            expenseDate: selectedDate,
                            category: selectedCategory,
                            description: descController.text.trim(),
                            amount: double.parse(amountController.text.trim()),
                            paymentMethod: selectedPaymentMethod,
                            referenceNo: refController.text.trim(),
                            remarks: remarksController.text.trim(),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('expense_added'.tr()), backgroundColor: AppTheme.success),
                          );
                        } else {
                          // Fetch linked expense ID from transaction reference or link
                          final expenseId = expenseToEdit['expense_id'];
                          if (expenseId == null) throw Exception("Linked expense details missing");
                          
                          await ApiService.updateExpense(expenseId, {
                            'expense_date': selectedDate.toIso8601String(),
                            'category': selectedCategory,
                            'description': descController.text.trim(),
                            'amount': double.parse(amountController.text.trim()),
                            'payment_method': selectedPaymentMethod,
                            'reference_no': refController.text.trim(),
                            'remarks': remarksController.text.trim(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('expense_updated'.tr()), backgroundColor: AppTheme.success),
                          );
                        }
                        _loadExpenses();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
                        );
                        setState(() => _loading = false);
                      }
                    }
                  },
                  child: Text('save'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _cancelExpense(dynamic exp) async {
    final expenseId = exp['expense_id'];
    if (expenseId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: const Text('Are you sure you want to cancel this expense record? / இந்த செலவு பதிவை ரத்து செய்ய வேண்டுமா?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      await ApiService.cancelExpense(expenseId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('expense_cancelled'.tr()), backgroundColor: AppTheme.success),
      );
      _loadExpenses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;
    final isAdmin = _currentUser?.isAdmin ?? false;

    return Scaffold(
      appBar: isWide ? null : AppBar(title: Text('nav_expenses'.tr())),
      body: RefreshIndicator(
        onRefresh: _loadExpenses,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'nav_expenses'.tr(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dark),
                    ),
                    if (isAdmin)
                      ElevatedButton.icon(
                        onPressed: () => _showExpenseDialog(),
                        icon: const Icon(Icons.add),
                        label: Text('add_expense'.tr()),
                      ),
                  ],
                ),
              const SizedBox(height: 16),

              // Total Expense indicator card
              Card(
                color: AppTheme.error.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.redAccent, width: 0.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total Active Expenses / மொத்த செலவுகள்',
                            style: TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${_calculateTotalExpenses().toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 22, color: AppTheme.error, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Icon(Icons.volunteer_activism, color: AppTheme.error.withOpacity(0.5), size: 30),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Expense records table or card lists
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
              else if (_expenses.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.volunteer_activism_outlined, size: 50, color: Colors.black.withOpacity(0.15)),
                        const SizedBox(height: 12),
                        const Text(
                          'No expenses recorded / செலவுப் பதிவுகள் எதுவும் இல்லை',
                          style: TextStyle(color: Colors.black45, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._expenses.map((exp) {
                  final isCancelled = exp['status'] == 'cancelled';
                  final amt = double.tryParse(exp['amount'].toString()) ?? 0.0;
                  final category = exp['category'].toString();
                  final description = exp['description'].toString();
                  final ref = exp['reference_number'] ?? '';
                  final remarks = exp['remarks'] ?? '';
                  final date = _formatDateString(exp['transaction_date']);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                category,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isCancelled ? Colors.black38 : AppTheme.dark,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              Text(
                                '₹${amt.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: isCancelled ? Colors.black38 : AppTheme.error,
                                  decoration: isCancelled ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$date · ${exp['payment_method']}',
                            style: const TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 12, 
                              color: isCancelled ? Colors.black38 : Colors.black87,
                            ),
                          ),
                          if (ref.isNotEmpty || remarks.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              [ref, remarks].where((s) => s.isNotEmpty).join(' · '),
                              style: const TextStyle(fontSize: 11, color: Colors.black38, fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (isCancelled) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'ரத்து செய்யப்பட்டது (Cancelled)',
                              style: TextStyle(color: AppTheme.error, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                          
                          // Edit / Cancel Actions for Admin role
                          if (isAdmin && !isCancelled) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _showExpenseDialog(expenseToEdit: exp),
                                  icon: const Icon(Icons.edit, size: 14),
                                  label: Text('edit'.tr(), style: const TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _cancelExpense(exp),
                                  icon: const Icon(Icons.cancel, size: 14),
                                  label: Text('delete'.tr(), style: const TextStyle(fontSize: 12)),
                                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
      floatingActionButton: (!isWide && isAdmin)
          ? FloatingActionButton(
              onPressed: () => _showExpenseDialog(),
              backgroundColor: AppTheme.saffron,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }
}
