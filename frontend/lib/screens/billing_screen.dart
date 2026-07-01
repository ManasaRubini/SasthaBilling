import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../models/models.dart';
import 'receipt_preview_screen.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _transactionController = TextEditingController();
  final _remarksController = TextEditingController();

  Devotee? _selectedDevotee;
  List<Devotee> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;

  String _billType = 'வரி';
  String _paymentMethod = 'பணம்';
  bool _submitting = false;

  final List<String> _billTypes = ['வரி', 'காணிக்கை'];
  final List<String> _paymentMethods = ['பணம்', 'UPI', 'கார்டு', 'காசோலை'];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _amountController.dispose();
    _categoryController.dispose();
    _transactionController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ApiService.getDevotees(search: query);
      setState(() => _searchResults = results);
    } catch (_) {
      setState(() => _searchResults = []);
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectDevotee(Devotee devotee) {
    setState(() {
      _selectedDevotee = devotee;
      _searchResults = [];
      _searchController.text = devotee.devoteeName;
    });
  }

  void _clearDevotee() {
    setState(() {
      _selectedDevotee = null;
      _searchController.clear();
      _searchResults = [];
    });
  }

  Future<void> _submitBill() async {
    if (_selectedDevotee == null) {
      _showSnack('select_devotee'.tr(), isError: true);
      return;
    }
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack('enter_amount'.tr(), isError: true);
      return;
    }

    setState(() => _submitting = true);
    try {
      final bill = await ApiService.createBill(
        devoteeId: _selectedDevotee!.devoteeId,
        billType: _billType,
        category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
        amount: amount,
        paymentMethod: _paymentMethod,
        transactionId: _transactionController.text.trim().isEmpty ? null : _transactionController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      );

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReceiptPreviewScreen(bill: bill)),
      );

      // Reset form
      setState(() {
        _selectedDevotee = null;
        _searchController.clear();
        _amountController.clear();
        _categoryController.clear();
        _transactionController.clear();
        _remarksController.clear();
        _billType = 'வரி';
        _paymentMethod = 'பணம்';
      });
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.error : AppTheme.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: isWide ? null : AppBar(title: Text('nav_billing'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isWide)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'nav_billing'.tr(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dark),
                  ),
                ),
              _sectionCard(
                title: 'select_devotee'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _searchController,
                      enabled: _selectedDevotee == null,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'search_devotee'.tr(),
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _selectedDevotee != null
                            ? IconButton(icon: const Icon(Icons.close), onPressed: _clearDevotee)
                            : (_searching ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              ) : null),
                      ),
                    ),
                    if (_selectedDevotee != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.lightOrange.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.saffron.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_selectedDevotee!.devoteeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  if (_selectedDevotee!.mobile != null)
                                    Text(_selectedDevotee!.mobile!, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_searchResults.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        constraints: const BoxConstraints(maxHeight: 240),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.black12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _searchResults.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final d = _searchResults[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.lightOrange,
                                child: Text(
                                  d.devoteeName.isNotEmpty ? d.devoteeName[0] : '?',
                                  style: const TextStyle(color: AppTheme.darkOrange, fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(d.devoteeName),
                              subtitle: Text([d.mobile, d.village].where((e) => e != null && e.isNotEmpty).join(' · ')),
                              onTap: () => _selectDevotee(d),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'billing_title'.tr(),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _billType,
                            decoration: InputDecoration(labelText: 'bill_type'.tr()),
                            items: _billTypes
                                .map((t) {
                                  String display = t;
                                  if (t == 'வரி') display = Translation.currentLanguage == 'ta' ? 'வரி' : 'Tax (Vari)';
                                  if (t == 'காணிக்கை') display = Translation.currentLanguage == 'ta' ? 'காணிக்கை' : 'Donation (Kanikkai)';
                                  return DropdownMenuItem(value: t, child: Text(display));
                                })
                                .toList(),
                            onChanged: (v) => setState(() => _billType = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            decoration: InputDecoration(labelText: '${'category'.tr()} (optional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkOrange),
                      decoration: InputDecoration(
                        labelText: 'amount'.tr(),
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.darkOrange),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _paymentMethod,
                            decoration: InputDecoration(labelText: 'payment_method'.tr()),
                            items: _paymentMethods
                                .map((m) {
                                  String display = m;
                                  if (m == 'பணம்') display = 'cash'.tr();
                                  if (m == 'UPI') display = 'upi'.tr();
                                  if (m == 'கார்டு') display = 'card'.tr();
                                  if (m == 'காசோலை') display = 'cheque'.tr();
                                  return DropdownMenuItem(value: m, child: Text(display));
                                })
                                .toList(),
                            onChanged: (v) => setState(() => _paymentMethod = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _transactionController,
                            decoration: InputDecoration(labelText: '${'transaction_id'.tr()} (optional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _remarksController,
                      maxLines: 2,
                      decoration: InputDecoration(labelText: '${'remarks'.tr()} (optional)'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _submitBill,
                  icon: _submitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.print),
                  label: Text(_submitting ? 'loading'.tr() : 'generate_receipt'.tr(),
                      style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.darkOrange)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}