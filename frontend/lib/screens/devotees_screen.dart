import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../models/models.dart';
import 'devotee_form_screen.dart';
import 'devotee_history_screen.dart';

class DevoteesScreen extends StatefulWidget {
  const DevoteesScreen({super.key});

  @override
  State<DevoteesScreen> createState() => _DevoteesScreenState();
}

class _DevoteesScreenState extends State<DevoteesScreen> {
  final _searchController = TextEditingController();
  List<Devotee> _devotees = [];
  bool _loading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devotees = await ApiService.getDevotees(search: search);
      setState(() => _devotees = devotees);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _load(search: query));
  }

  Future<void> _deleteDevotee(Devotee devotee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('confirm_delete'.tr()),
        content: Text('${devotee.devoteeName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('cancel'.tr())),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('delete'.tr(), style: const TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.deleteDevotee(devotee.devoteeId);
        _load(search: _searchController.text);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Future<void> _openForm({Devotee? devotee}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DevoteeFormScreen(devotee: devotee)),
    );
    if (result == true) {
      _load(search: _searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: isWide ? null : AppBar(title: Text('nav_devotees'.tr())),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.saffron,
        icon: const Icon(Icons.add),
        label: Text('add_devotee'.tr()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'devotees_title'.tr(),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.dark),
                ),
              ),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'search_placeholder'.tr(),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.error)))
                      : _devotees.isEmpty
                          ? _emptyState()
                          : _buildTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 56, color: Colors.black.withOpacity(0.2)),
          const SizedBox(height: 12),
          Text('total_devotees'.tr() + ': 0', style: const TextStyle(color: Colors.black54, fontSize: 16)),
          const SizedBox(height: 4),
          Text('add_devotee'.tr(), style: const TextStyle(color: Colors.black38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: [
              DataColumn(label: Text('name'.tr())),
              DataColumn(label: Text('mobile'.tr())),
              DataColumn(label: Text('address'.tr())),
              DataColumn(label: Text('history'.tr())),
            ],
            rows: _devotees.map((d) {
              return DataRow(cells: [
                DataCell(
                  Text(d.devoteeName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DevoteeHistoryScreen(devotee: d)),
                  ),
                ),
                DataCell(Text(d.mobile ?? '-')),
                DataCell(
                  Container(
                    constraints: const BoxConstraints(maxWidth: 280),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      d.address ?? '-',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.history, size: 20, color: AppTheme.gold),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DevoteeHistoryScreen(devotee: d)),
                      ),
                      tooltip: 'history'.tr(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: AppTheme.saffron),
                      onPressed: () => _openForm(devotee: d),
                      tooltip: 'edit'.tr(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: AppTheme.error),
                      onPressed: () => _deleteDevotee(d),
                      tooltip: 'delete'.tr(),
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}